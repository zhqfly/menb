#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${ROOT}"

mkdir -p \
  data/postgres \
  data/openproject/files \
  data/openproject/git \
  data/openproject/svn \
  logs/postgres \
  logs/openproject \
  logs/compose

chmod 0755 scripts docker docker/postgres docker/postgres/initdb docker/openproject || true
chmod 0755 scripts/*.sh docker/postgres/initdb/*.sh docker/openproject/*.sh || true

# 官方 postgres 镜像运行用户 uid=999；OpenProject 12 镜像 app 用户一般为 uid=1000
if [ "$(id -u)" = "0" ]; then
  chown -R 999:999 data/postgres logs/postgres
  chown -R 1000:1000 data/openproject logs/openproject
  chmod 0700 data/postgres
else
  chmod 0700 data/postgres || true
  echo "非 root：若 PostgreSQL 启动报权限错误，请执行: sudo ./scripts/fix-permissions.sh"
fi

echo "目录已就绪:"
find data logs -maxdepth 2 -type d | sort
