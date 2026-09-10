#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"
./scripts/bootstrap.sh
docker compose up -d --build
echo
echo "查看初始化（首次 seeder 可能需要数分钟）:"
echo "  docker compose logs -f seeder"
echo "  docker compose ps"
echo "访问: http://127.0.0.1:${PORT:-8080}  默认账号 admin / admin"
