#!/bin/bash
# 在官方 12.5.8 镜像内注入 path 插件，不升级 rails/pg 等已锁定 gem。
set -euo pipefail
cd /app
cp /app/plugins/Gemfile.plugins /app/Gemfile.plugins
export BUNDLE_FROZEN=0
bundle config unset deployment || true
bundle config unset frozen || true
# 优先只用已有 vendor/bundle，path 插件无新远程依赖
if ! bundle install --jobs=4 --retry=3 --local; then
  bundle install --jobs=4 --retry=3
fi
chown -R "${APP_USER:-app}:${APP_USER:-app}" /app/plugins /app/Gemfile.plugins /app/Gemfile.lock /app/vendor/bundle || true
