#!/bin/bash
# 禁止禁用官方 bundled 成本 / 工时 / 报表 / 预算模块。
set -euo pipefail

DISABLED="${OPENPROJECT_DISABLED__MODULES:-}"
if [ -z "${DISABLED}" ]; then
  exit 0
fi

normalized="$(echo "${DISABLED}" | tr '[:upper:]' '[:lower:]')"
for name in costs reporting budgets time_tracking time_entries; do
  if echo "${normalized}" | grep -Eq "(^|[, ])${name}([, ]|$)"; then
    echo "ERROR: OPENPROJECT_DISABLED__MODULES 含 ${name}，会破坏原生 Cost/工时模块。请从环境变量中移除。" >&2
    exit 1
  fi
done
