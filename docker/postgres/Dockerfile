# PostgreSQL 13 锁定补丁版本，与 OpenProject 12.x 官方容器内 PGVERSION=13 对齐。
# 不升级系统包，仅启用中文 locale 与日志目录。

ARG POSTGRES_IMAGE_TAG=13.21-bullseye
FROM postgres:${POSTGRES_IMAGE_TAG}

ARG DEBIAN_MIRROR=https://mirrors.aliyun.com/debian
ARG DEBIAN_SECURITY_MIRROR=https://mirrors.aliyun.com/debian-security
ARG TZ=Asia/Shanghai

ENV TZ=${TZ} \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

USER root

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

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends --no-upgrade \
      locales \
      tzdata; \
    sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen; \
    sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen; \
    locale-gen zh_CN.UTF-8 en_US.UTF-8; \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo "${TZ}" > /etc/timezone; \
    mkdir -p /var/log/postgresql; \
    chown postgres:postgres /var/log/postgresql; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

COPY postgresql.conf /etc/postgresql/openproject.conf
COPY initdb /docker-entrypoint-initdb.d/
