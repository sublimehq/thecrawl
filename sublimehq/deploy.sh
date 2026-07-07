#/usr/bin/env bash

# always run from repository root
cd "$(dirname "$0")"
cd ..

HOST=packages.sublimetext.com

podman build -f sublimehq/build.dockerfile -t thecrawl-site-build .
podman image list thecrawl-site-build
podman save thecrawl-site-build | zstd -1 | pv | ssh $HOST "zstd -d > /opt/thecrawl/thecrawl-site-build.image"
