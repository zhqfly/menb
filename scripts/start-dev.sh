#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"
./scripts/bootstrap.sh
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
echo
echo "调试模式已启动（LOG_LEVEL=debug，映射 PostgreSQL 5432）"
echo "Rails console:  ./scripts/console.sh"
echo "Web 日志:       docker compose logs -f web"
echo "Worker 日志:    docker compose logs -f worker"
echo "核对模块:       ./scripts/verify-modules.sh"
