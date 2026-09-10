.PHONY: bootstrap start start-dev stop logs console modules psql rebuild test-iext

bootstrap:
	chmod +x scripts/*.sh docker/postgres/initdb/*.sh docker/openproject/*.sh
	./scripts/bootstrap.sh

start: bootstrap
	./scripts/start.sh

start-dev: bootstrap
	./scripts/start-dev.sh

stop:
	docker compose down

logs:
	./scripts/logs.sh

console:
	./scripts/console.sh

modules:
	./scripts/verify-modules.sh

psql:
	docker compose exec db psql -U openproject -d openproject

rebuild:
	docker compose build --no-cache

test-iext:
	ruby plugins/openproject-internal_ext/test/iext_math_test.rb
