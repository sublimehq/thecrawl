FROM node:26-slim

WORKDIR ./app

COPY package.json package-lock.json ./

RUN npm install

COPY _includes ./_includes
COPY assets ./assets
COPY browse ./browse
COPY packages ./packages
COPY static ./static
COPY util ./util
COPY \
    *.md \
    *.njk \
    *.mjs \
    emoji.json \
    label-aliases.json \
    label-icons.json \
    label-icons-config.json \
    sublimehq/build.sh \
    ./

ENV NODE_OPTIONS=--max_old_space_size=6144
