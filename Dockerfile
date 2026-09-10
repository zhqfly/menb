# OpenProject Community — 官方镜像定制层
# 上游锁定: openproject/community:12.5.8 (= git tag v12.5.8)
# 官方无 12.13.0；本文件不重建应用、不升级系统包，仅叠加中文运行依赖。
#
# 原生模块保留（来自官方 Gemfile.modules，bundled: true）：
#   costs / openproject-reporting / budgets
# 工时记录在 12.x 中属于 costs 引擎（log_time / time_entries），勿禁用。

ARG OPENPROJECT_IMAGE_TAG=12.5.8
ARG OPENPROJECT_IMAGE=openproject/community:${OPENPROJECT_IMAGE_TAG}

FROM ${OPENPROJECT_IMAGE}

ARG DEBIAN_MIRROR=https://mirrors.aliyun.com/debian
ARG DEBIAN_SECURITY_MIRROR=https://mirrors.aliyun.com/debian-security
ARG TZ=Asia/Shanghai

ENV TZ=${TZ} \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    OPENPROJECT_EDITION=standard \
    OPENPROJECT_DEFAULT__LANGUAGE=zh-CN \
    OPENPROJECT_INSTALLATION__TYPE=docker

USER root

# 仅替换 APT 源，不执行 apt-get upgrade / dist-upgrade
RUN set -eux; \
    if [ -f /etc/apt/sources.list ]; then \
      sed -i \
        -e "s|http://deb.debian.org/debian|${DEBIAN_MIRROR}|g" \
        -e "s|https://deb.debian.org/debian|${DEBIAN_MIRROR}|g" \
        -e "s|http://security.debian.org/debian-security|${DEBIAN_SECURITY_MIRROR}|g" \
        -e "s|https://security.debian.org/debian-security|${DEBIAN_SECURITY_MIRROR}|g" \
        -e "s|http://security.debian.org|${DEBIAN_SECURITY_MIRROR}|g" \
        /etc/apt/sources.list; \
    fi

# --no-upgrade：已安装包保持官方镜像原版本
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends --no-upgrade \
      ca-certificates \
      fonts-noto-cjk \
      fonts-wqy-microhei \
      fonts-wqy-zenhei \
      locales \
      tzdata; \
    sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen; \
    sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen; \
    locale-gen zh_CN.UTF-8 en_US.UTF-8; \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo "${TZ}" > /etc/timezone; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

COPY docker/openproject/ensure-native-modules.sh /usr/local/bin/ensure-native-modules
COPY docker/openproject/install-plugins.sh /usr/local/bin/install-plugins
COPY plugins /app/plugins
RUN chmod 0755 /usr/local/bin/ensure-native-modules /usr/local/bin/install-plugins \
 && /usr/local/bin/install-plugins

# 官方 entrypoint 会按需 gosu 到 app 用户
WORKDIR /app
ENTRYPOINT ["./docker/prod/entrypoint.sh"]
CMD ["./docker/prod/web"]
