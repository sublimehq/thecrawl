#/usr/bin/env bash

set -ex

node render_readmes.mjs -i readmes.json -o readmes_rendered.json
npx @11ty/eleventy
