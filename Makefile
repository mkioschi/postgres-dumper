.PHONY: start
start:
	@docker compose up -d

.PHONY: stop
stop:
	@docker compose down

.PHONY: build
build:
	@docker compose build

.PHONY: restart
restart: down up

.PHONY: backup
backup:
	@echo "Creating backup now..."
	@docker exec -it dumper sh -c "sh /bin/dumper/backup.sh >> /logs/dumper.log 2>&1"
	@echo "Backup finished!"

.PHONY: exec
exec:
	@docker exec -it dumper sh