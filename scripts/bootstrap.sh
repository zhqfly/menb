#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

chmod +x scripts/*.sh docker/postgres/initdb/*.sh docker/openproject/*.sh
./scripts/fix-permissions.sh

if [ ! -f .env ]; then
  cp .env.example .env
  if command -v openssl >/dev/null 2>&1; then
    secret="$(openssl rand -hex 64)"
    # POSIX sed: in-place replace placeholder
    if grep -q 'CHANGE_ME_GENERATE_WITH_OPENSSL' .env; then
      tmp="$(mktemp)"
      sed "s/CHANGE_ME_GENERATE_WITH_OPENSSL/${secret}/" .env > "${tmp}"
      mv "${tmp}" .env
    fi
  fi
  echo "已生成 .env（请按需修改 OPENPROJECT_HOST__NAME / 密码）"
else
  echo ".env 已存在，跳过"
fi
