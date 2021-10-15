# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ Colors definitions                                                          │
# └─────────────────────────────────────────────────────────────────────────────┘
CR=\033[0;31m
CG=\033[0;32m
CY=\033[0;33m
CB=\033[0;36m
RC=\033[0m

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ Commands                                                                    │
# └─────────────────────────────────────────────────────────────────────────────┘
.PHONY: up
up:
	@docker-compose up -d

.PHONY: down
down:
	@docker-compose down

.PHONY: build
build:
	@docker-compose build

.PHONY: restart
restart: down up

.PHONY: backup
backup:
	@echo "Creating backup now..."
	@docker exec -it dumper sh -c "sh /bin/dumper/backup.sh >> /logs/dumper.log 2>&1"
	@echo "Backup finished!"

.PHONY: sh
sh:
	@docker exec -it dumper sh

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ Help                                                                        │
# └─────────────────────────────────────────────────────────────────────────────┘
help:
	@echo ""
	@echo "${CY}Usage:${RC}"
	@echo "   make ${CG}<command>${RC}"
	@echo ""
	@echo "${CY}Infra commands:${RC}"
	@echo "${CG}   backup              ${RC}Create backup now"
	@echo "${CG}   build               ${RC}Build container"
	@echo "${CG}   down                ${RC}Stop dumper service"
	@echo "${CG}   restart             ${RC}Restart dumper service"
	@echo "${CG}   sh                  ${RC}Open a shel terminal inside the dumper service"
	@echo "${CG}   up                  ${RC}Start dumper service"
	@echo ""
	@echo "${CY}See more: https://github.com/mkioschi/postgres-dumper${RC}"