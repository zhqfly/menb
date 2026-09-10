#!/bin/bash
# 仅在空数据目录首次 initdb 时执行（官方 docker-entrypoint 约定）。
set -euo pipefail

echo "[initdb] OpenProject database encoding=$(psql -v ON_ERROR_STOP=1 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc 'SHOW server_encoding;')"

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<'SQL'
-- 与官方 OpenProject 12.x 数据库约定一致：UTF8 + 可重连连接池
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gist;
SQL

echo "[initdb] extensions ready (pg_trgm, btree_gist)"
