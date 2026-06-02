#!/usr/bin/env bash

# always run from repository root
cd "$(dirname "$0")"
cd ..

SERVER=packages.sublimetext.com

git checkout main-sublimehq
rsync  -rltvc --exclude __pycache__ --chmod=ugo=rwX pyproject.toml uv.lock scripts sublimehq/crawl.sh $SERVER:/opt/thecrawl
