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
	@mkdir -p $(DATA_PATH)/database
	@mkdir -p $(DATA_PATH)/wordpress
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
	@echo "$(BLUE)=== Inception Project Info ===$(RESET)"
	@echo "$(GREEN)URL:$(RESET) https://localhost"
	@echo "$(GREEN)URL:$(RESET) https://localhost/wp-admin"
	@echo "$(GREEN)Admin Login:$(RESET) admin / admin42pass"
	@echo "$(GREEN)User Login:$(RESET) user / user42pass"
	@echo "$(GREEN)Database:$(RESET) wordpress_db"
	@echo "$(GREEN)DB User:$(RESET) wpuser / wpuser42pass"
	@echo "$(YELLOW)Before start add the following to your hosts $(RESET)"
	@echo "$(YELLOW)sudo nano /etc/hosts $(RESET) and write $(YELLOW) 127.0.0.1	rcosta-c.42.fr $(RESET)"
	@echo "$(YELLOW)Volumes:$(RESET) $(DATA_PATH)"

.PHONY: all setup up down stop start status logs logs-db logs-nginx logs-wp clean fclean re info