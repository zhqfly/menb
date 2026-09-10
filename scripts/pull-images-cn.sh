#!/bin/bash
# 国内拉取基础镜像并打回官方标签。openproject/community 不在 DaoCloud 白名单，需多源回退。
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

pull_tag() {
  local src="$1"
  local dst="$2"
  echo "==== pull ${src} -> ${dst}"
  if docker pull "${src}"; then
    docker tag "${src}" "${dst}"
    return 0
  fi
  return 1
}

if ! docker image inspect memcached:1.6.22-alpine >/dev/null 2>&1; then
  pull_tag "docker.m.daocloud.io/library/memcached:1.6.22-alpine" "memcached:1.6.22-alpine"
fi

if ! docker image inspect postgres:13.21-bullseye >/dev/null 2>&1; then
  pull_tag "docker.m.daocloud.io/library/postgres:13.21-bullseye" "postgres:13.21-bullseye"
fi

OP_DST="openproject/community:12.5.8"
if docker image inspect "${OP_DST}" >/dev/null 2>&1; then
  echo "==== 已有 ${OP_DST}，跳过拉取"
else
  ok=0
  for src in \
    "docker.1ms.run/openproject/community:12.5.8" \
    "swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/openproject/community:12.5.8" \
    "docker.xuanyuan.run/openproject/community:12.5.8" \
    "dockerproxy.net/openproject/community:12.5.8"
  do
    echo "==== try ${src}"
    if docker pull "${src}"; then
      docker tag "${src}" "${OP_DST}"
      ok=1
      break
    fi
  done
  if [ "${ok}" -ne 1 ]; then
    echo "ERROR: 无法拉取 ${OP_DST}。" >&2
    echo "请关闭 Docker Desktop 中阿里云个人加速器（会对非白名单镜像返回 403），" >&2
    echo "或换可访问 Docker Hub 的网络后再执行本脚本。" >&2
    exit 1
  fi
fi

echo "==== 使用本地基础镜像构建（不向 Docker Hub 查 FROM）"
docker compose build --pull never
echo "==== 启动"
docker compose up -d
echo "查看: docker compose logs -f seeder"
