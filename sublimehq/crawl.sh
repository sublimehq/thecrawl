#!/usr/bin/env bash

set -e

# always run from repository root
cd "$(dirname "$0")"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN not set"
    exit 1
fi

# Copy working data from the database directory. We do atomic replacement of
# these files to ensure data integrity.
if [ -d database ]; then
    cp database/registry.json database/workspace.json \
        database/prev_totals.json database/readmes.json database/stats.json ./
else
    echo "First run. Initializing database directory"
    mkdir -p database
fi

### Perform crawling

uv run -m scripts.generate_registry
uv run -m scripts.crawl --fetch-readmes ./readmes.json
uv run -m scripts.crawl_libraries
uv run -m scripts.generate_channel
uv run -m scripts.accumulate_stats

# Generate compressed channels for v4 and v3
uv run -m scripts.compress_channel -o channel_v4.json
gzip -9knf channel_v4.json
# zstd --ultra -22 -kf channel_v4.json
uv run -m scripts.compress_channel --legacy -o channel_v3.json
gzip -9knf channel_v3.json
# zstd --ultra -22 -kf channel_v3.json

# TODO: Collect logs from journalctl
echo "[]" > logs.json

# Data is now up to date, update the database
mv prev_totals.json database/prev_totals.json
mv readmes.json database/readmes.json
mv registry.json database/registry.json
mv stats.json database/stats.json
mv workspace.json database/workspace.json

### Build website

# First make sure our copy of the package control channel is up to date
if [ ! -d .package_control_channel ]; then
    git clone https://github.com/sublimehq/package_control_channel.git .package_control_channel
fi
cd .package_control_channel
git pull
cd -

# Build the website in a clean directory
rm -rf _site
mkdir -p _site

# Load the docker image for building the website. This is quick if we've already
# done this.
podman load -i thecrawl-site-build.image

# Initialize the rendered readmes if they don't exist
if [ ! -f database/readmes_rendered.json ]; then
    echo '{}' > database/readmes_rendered.json
fi

# Run build script
HASH=$(podman image list thecrawl-site-build -q)
podman run --rm \
    -v ./database/workspace.json:/app/workspace.json:ro \
    -v ./database/stats.json:/app/stats.json:ro \
    -v ./database/readmes.json:/app/readmes.json:ro \
    -v ./database/readmes_rendered.json:/app/readmes_rendered.json:rw \
    -v ./_site:/app/_site \
    -v ./.package_control_channel:/app/.package_control_channel \
    thecrawl-site-build \
    bash -c "NODE_ENV=production GIT_HASH=$HASH ./build.sh"

# gzip everything so nginx doesn't do this dynamically
find _site -type f -exec gzip -9nk {} + || true

# Move channels into site
mv channel_v*.json* _site/

# Copy changed files to the release directory, this dir is the live website.
mkdir -p current-release
# update based on checksum rather than modified time
rsync -rlc --delete-after _site/ current-release/
