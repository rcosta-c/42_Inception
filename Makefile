# Makefile

# Variáveis
DOCKER_COMPOSE = docker-compose
DOCKER_COMPOSE_FILE = ./srcs/docker-compose.yml
DATA_PATH = ~/data

# Cores para output
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[0;33m
BLUE = \033[0;34m
RESET = \033[0m

all: setup up info

setup:
	@echo "$(YELLOW)Creating data folders...$(RESET)"
	@mkdir -p /home/$(USER)/data/database
	@mkdir -p /home/$(USER)/data/wordpress
	@echo "$(GREEN)Folders created!$(RESET)"

up:
	@echo "$(GREEN)Starting containers...$(RESET)"
	@$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_FILE) up -d --build 
	@echo "$(GREEN)Containers started!$(RESET)"
	@echo "$(YELLOW)Please wait 30 sec for WordPress config...$(RESET)"
	
down:
	@echo "$(RED)Stoping containers...$(RESET)"
	@cd srcs && $(DOCKER_COMPOSE) down
	@echo "$(RED)Containers stoped!$(RESET)"

stop:
	@echo "$(RED)Stoping containers...$(RESET)"
	@cd srcs && $(DOCKER_COMPOSE) stop

start:
	@echo "$(GREEN)Starting containers...$(RESET)"
	@cd srcs && $(DOCKER_COMPOSE) start

status:
	@cd srcs && $(DOCKER_COMPOSE) ps -a

logs:
	@cd srcs && $(DOCKER_COMPOSE) logs -f

clean: down
	@echo "$(RED)Cleaning images...$(RESET)"
	@docker system prune -af
	@echo "$(RED)Cleaning completed!$(RESET)"

fclean: clean
	@echo "$(RED)Removing data...$(RESET)"
	@sudo chown -R $(USER):$(USER) $(DATA_PATH) 2>/dev/null || true
	@rm -rf $(DATA_PATH)
	@echo "$(RED)Removing used volumes...$(RESET)"
	@docker volume rm srcs_db_data srcs_wordpress_data 2>/dev/null || true
	@docker volume prune -f
	@docker system prune -f
	@echo "$(RED)Limpeza total completa!$(RESET)"

re: fclean all

info:
	@echo ""
	@echo "$(BLUE)=== Inception Project Info ===$(RESET)"
	@if [ -f srcs/.env ]; then \
		echo "$(GREEN)Domain:$(RESET) $$(grep DOMAIN_NAME srcs/.env | cut -d'=' -f2)"; \
		echo "$(GREEN)Database:$(RESET) $$(grep MYSQL_DATABASE srcs/.env | cut -d'=' -f2)"; \
		echo "$(GREEN)Site Title:$(RESET) $$(grep WP_TITLE srcs/.env | cut -d'=' -f2)"; \
	fi
	@if [ -d secrets ]; then \
		echo ""; \
		echo "$(GREEN)Admin User:$(RESET) $$(cat secrets/wp_admin_user 2>/dev/null)"; \
		echo "$(GREEN)Admin Pass:$(RESET) $$(cat secrets/wp_adminpassword 2>/dev/null)"; \
		echo "$(GREEN)DB User:$(RESET) $$(cat secrets/mysql_user 2>/dev/null)"; \
		echo "$(GREEN)DB Pass:$(RESET) $$(cat secrets/mysql_password 2>/dev/null)"; \
	fi
	@echo ""
	@echo "$(YELLOW)Add to /etc/hosts: 127.0.0.1 $$(grep DOMAIN_NAME srcs/.env | cut -d'=' -f2)$(RESET)"

.PHONY: all setup up down stop start status logs logs-db logs-nginx logs-wp clean fclean re info