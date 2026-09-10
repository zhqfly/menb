# OpenProject 12.x Docker Compose 部署（锁定官方源码/镜像）

官方 Git 标签中**没有** `v12.13.0`。`opf/openproject` 的 12 系列止于 **`v12.5.8`**（镜像 `openproject/community:12.5.8`）。本仓库按该版本锁定，**不升级 OpenProject、不执行 `apt-get upgrade`**，完整保留官方 CE 原生 **Cost（costs）**、**工时（time entries，挂在 costs 引擎）**、**成本报表（reporting）**、**预算（budgets）** 模块。

参考：

- 部署编排：[opf/openproject-deploy `stable/12` compose](https://github.com/opf/openproject-deploy/blob/stable/12/compose/docker-compose.yml)
- 应用镜像/源码：[opf/openproject `v12.5.8`](https://github.com/opf/openproject/tree/v12.5.8)（`docker/prod/Dockerfile`、`Gemfile.modules`）

## 架构

| 服务 | 说明 | 端口 |
| --- | --- | --- |
| `proxy` | 官方 `./docker/prod/proxy`（Apache → web） | **8080→80** |
| `web` | Puma `./docker/prod/web` | 容器内 8080（调试时另映射 8081） |
| `worker` | 后台任务 | — |
| `cron` | 定时任务 | — |
| `seeder` | 首次结构/种子数据，成功后退出 | — |
| `db` | PostgreSQL **13.21-bullseye** | **5432** |
| `cache` | Memcached 1.6.22 | — |

数据卷：

- `./data/postgres` → `/var/lib/postgresql/data`
- `./data/openproject` → `/var/openproject/assets`
- `./logs/postgres` → `/var/log/postgresql`
- `./logs/openproject` → `/app/log`

应用日志同时走 stdout（`RAILS_LOG_TO_STDOUT=1`），由 Compose `json-file` 限制为 10MB × 5。

## 本地启动

环境：Docker Engine 20.10+、Compose v2（需要 `service_completed_successfully`）。国内请配置 Docker Hub 镜像加速后再拉基础镜像。

```bash
chmod +x scripts/*.sh docker/postgres/initdb/*.sh docker/openproject/*.sh
./scripts/bootstrap.sh          # 建目录、权限、从 .env.example 生成 .env
./scripts/start.sh               # 构建并后台启动
# 或
make start
```

首次 `seeder` 可能数分钟：

```bash
docker compose logs -f seeder
docker compose ps
```

浏览器：`http://127.0.0.1:8080`  
默认账号：`admin` / `admin`（**立刻改密**）。

停止：

```bash
docker compose down          # 保留绑定目录中的数据
docker compose down -v       # 仅当使用 named volume 时会删卷；绑定目录需手动删 data/
```

## 调试

```bash
./scripts/start-dev.sh
# 等价: docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```

| 方式 | 命令 |
| --- | --- |
| 跟踪 web | `docker compose logs -f web` |
| 跟踪 worker | `docker compose logs -f worker` |
| Rails console | `./scripts/console.sh` |
| 直连 Puma | `http://127.0.0.1:8081`（dev 覆盖） |
| psql | `docker compose exec db psql -U openproject -d openproject` |
| 进容器 | `docker compose exec web bash` |
| 核对 Cost/工时 | `./scripts/verify-modules.sh` |
| 提高日志 | `OPENPROJECT_LOG__LEVEL=debug`（dev 文件已设） |

在 console 中可验证：

```ruby
Costs::Engine
OpenProject::AccessControl.permission(:log_time)
```

## 定制 Dockerfile 要点

`Dockerfile` **FROM 锁定** `openproject/community:12.5.8`，不从源码重编应用（避免改动官方 bundle 与模块集合）。叠加层：

- Debian APT 切到阿里云，**只 `apt-get install --no-upgrade`**
- `zh_CN.UTF-8`、`fonts-noto-cjk` / 文泉驿（PDF/导出中文）
- `TZ=Asia/Shanghai`
- `OPENPROJECT_EDITION=standard`
- 启动前 `ensure-native-modules`：若误设 `OPENPROJECT_DISABLED__MODULES` 含 `costs` / `reporting` / `budgets` / `time_tracking` 则拒绝启动

PostgreSQL 定制见 `docker/postgres/Dockerfile`（同样 `--no-upgrade`）。

## 权限

`scripts/fix-permissions.sh`：

- PostgreSQL 数据目录 uid **999**，权限 `0700`
- OpenProject assets / 日志 uid **1000**（官方镜像 `app` 用户）

非 root 启动若 db 报 permission denied，用 `sudo ./scripts/fix-permissions.sh`。

## 模块说明（12.x 官方行为）

`Gemfile.modules`（v12.5.8）中：

```text
gem 'costs',                 path: 'modules/costs'
gem 'openproject-reporting',  path: 'modules/reporting'
gem 'budgets',               path: 'modules/budgets'
```

`Costs::Engine` 以 `bundled: true` 注册项目模块 `:costs`，权限包含 `log_time`、`view_time_entries`、`log_costs` 等。不要升级到 13+ 再关闭企业功能；本方案停留在 12.5.8 社区版完整模块集。

新项目默认模块见 `.env` 中 `OPENPROJECT_DEFAULT__PROJECTS__MODULES`。已有项目需在 **项目设置 → 模块** 勾选「时间与成本」。

管理后台可把货币改为 CNY：**管理 → 时间与成本**。

## 国内网络

1. Docker Hub：daemon `registry-mirrors`（如 `https://docker.m.daocloud.io`）
2. 构建 ARG：`DEBIAN_MIRROR` / `DEBIAN_SECURITY_MIRROR`（默认阿里云）
3. 不要把基础镜像换成随意的第三方「完整汉化包」，以免替换掉官方 costs gem

若必须从源码构建，请 clone `https://github.com/opf/openproject.git` 并 `git checkout v12.5.8`，使用仓库内 `docker/prod/Dockerfile`，**不要改 `Gemfile.modules`，不要 `apt-get upgrade`**。日常部署请用本仓库基于官方镜像的 Dockerfile。
