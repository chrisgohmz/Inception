.PHONY: all build up down dirs hosts secrets stop clean fclean re

SRC_DIR := srcs
ENV_FILE := $(SRC_DIR)/.env

COMPOSE := docker compose \
		--project-directory $(SRC_DIR) \
		-f $(SRC_DIR)/docker-compose.yml \
		--env-file $(ENV_FILE)
DATA_DIR := /home/$(shell grep '^LOGIN=' $(ENV_FILE) | cut -d '=' -f 2)/data

all: dirs secrets hosts build up

dirs:
	mkdir -p $(DATA_DIR)/secrets
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress
	mkdir -p $(DATA_DIR)/redis

hosts:
	@bash -c 'set -a; . "$(ENV_FILE)"; set +a; DOMAIN="$$DOMAIN" bash $(SRC_DIR)/scripts/setup-hosts.sh'

secrets:
	@bash $(SRC_DIR)/scripts/mksecrets.sh

build:
	$(COMPOSE) build --no-cache

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

clean:
	$(COMPOSE) down --volumes --remove-orphans

fclean: clean
	-docker image rm nginx:v1 wordpress:v1 mariadb:v1 2>/dev/null || true

re: fclean all