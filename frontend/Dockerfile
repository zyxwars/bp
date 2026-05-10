# https://docs.docker.com/build/concepts/dockerfile
# https://docs.docker.com/build/building/best-practices
FROM debian:bookworm-slim AS godot-base

ARG GODOT_VERSION=4.6.1

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    libfontconfig1 \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Install godot
RUN wget -O godot.zip "https://downloads.godotengine.org/?version=${GODOT_VERSION}&flavor=stable&slug=linux.x86_64.zip&platform=linux.64" \
  && unzip godot.zip \
  && mv Godot_v${GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot \
  && chmod +x /usr/local/bin/godot \
  && rm godot.zip

# Install godot templates for building web platform
RUN wget -O templates.zip "https://downloads.godotengine.org/?version=${GODOT_VERSION}&flavor=stable&slug=export_templates.tpz&platform=templates" \
  && unzip templates.zip \
  && mkdir -p /root/.local/share/godot/export_templates/${GODOT_VERSION}.stable \
  && mv templates/web_* /root/.local/share/godot/export_templates/${GODOT_VERSION}.stable/ \
  && mv templates/version.txt /root/.local/share/godot/export_templates/${GODOT_VERSION}.stable/ \
  && rm -rf templates templates.zip

# Build project
FROM godot-base AS builder

WORKDIR /app
RUN mkdir -p ./build
COPY . .

RUN godot --headless --import
RUN godot --headless --export-release "Web"

# Serve with nginx
FROM nginx:alpine

COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
