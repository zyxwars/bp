# https://pnpm.io/docker
# https://docs.docker.com/build/concepts/dockerfile
# https://docs.docker.com/build/building/best-practices
FROM node:24.11.1-slim AS base

RUN corepack enable

WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .