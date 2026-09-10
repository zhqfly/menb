#!/bin/bash
# 国内无法直连 Docker Hub 时，经 DaoCloud 拉取再打回官方标签（compose/Dockerfile 不用改）。
set -euo pipefail

MIRROR="${DOCKER_CN_MIRROR:-docker.m.daocloud.io}"

pull_tag() {
  local src="$1"
  local dst="$2"
  echo "==== pull ${MIRROR}/${src} -> ${dst}"
  docker pull "${MIRROR}/${src}"
  docker tag "${MIRROR}/${src}" "${dst}"
}

pull_tag "library/memcached:1.6.22-alpine" "memcached:1.6.22-alpine"
pull_tag "library/postgres:13.21-bullseye" "postgres:13.21-bullseye"
pull_tag "openproject/community:12.5.8" "openproject/community:12.5.8"

echo "镜像已就位。请再执行: docker compose up -d --build"
