# ===== EASV3 Makefile =====
# Runs commands inside containers via docker/coder/coder-exec.sh

# Helper script
SCRIPT          ?= ./docker/coder/coder-exec.sh

# Container names (match docker-compose)
CHILD_WEB       ?= easv3_child_web
PARENT_WEB      ?= easv3_parent_web
CHILD_DB        ?= easv3_child_db
PARENT_DB       ?= easv3_parent_db
NGINX_SVC       ?= easv3_nginx
CODER_SVC       ?= easv3_coder

.PHONY: help list easv3 \
        php/console parent/php/console \
        php/unit parent/php/unit \
        cache/clear parent/cache/clear \
        web/shell parent/web/shell \
        db/shell parent/db/shell \
        nginx/test

help:
	@echo "Usage:"
	@echo "  make list                              # show supported containers"
	@echo "  make php/console ARGS='cache:clear'    # child app console"
	@echo "  make parent/php/console ARGS='...'     # parent app console"
	@echo "  make php/unit ARGS='-v'                # child PHPUnit"
	@echo "  make parent/php/unit ARGS='-v'         # parent PHPUnit"
	@echo "  make cache/clear                       # child cache clear"
	@echo "  make parent/cache/clear                # parent cache clear"
	@echo "  make web/shell | parent/web/shell      # interactive bash"
	@echo "  make db/shell | parent/db/shell        # mysql shell"
	@echo "  make nginx/test                        # nginx -t"
	@echo "  make coder                             # connect coder"
	@echo "  make down                              # stop and remove containers"
	@echo "  make down-full                         # down, remove volumes"
	@echo "  make up-full                           # up, build fresh"
	@echo "  make full-reset                        # down, remove volumes, up"
	@echo "  make env-update                        # update environment"
	@echo "  make help                              # this help"
	@echo "  make up                                # start containers"
	@echo "Examples:"
	@echo '  make easv3 php/unit'
	@echo '  make php/console ARGS="doctrine:migrations:migrate"'
	@echo '  make parent/php/unit ARGS="-v"'

# No-op namespace so "make easv3 php/unit" works
easv3:
	@true

# Connect to Coder Container
coder:
	@echo "🔌 Opening VS Code Remote-SSH"
	@code --remote ssh-remote+dev@localhost:2222 /workspace

coder-parent:
	@echo "🔌 Opening VS Code Remote-SSH"
	@code --remote ssh-remote+dev@localhost:2222 /workspace/parent

coder-child:
	@echo "🔌 Opening VS Code Remote-SSH"
	@code --remote ssh-remote+dev@localhost:2222 /workspace/child

# Clean Up Environment
down:
	@echo "🔌 Opening VS Code Remote-SSH"
	@docker-compose down -v

# Start Environment
up:
	@docker-compose up -d --build

# Full Delete Environment

down-full: down
	@docker volume rm easv3_code easv3parent_code
	@docker rmi -f earlyaccesscare/easv3_child_web earlyaccesscare/eas_v3parent_db earlyaccesscare/eas_v3parent_web earlyaccesscare/easv3_child_db earlyaccesscare/easv3_coder earlyaccesscare/easv3_nginx earlyaccesscare/phpmyadmin

# Initialize Environment
up-full: 
	@docker volume create easv3_code
	@docker volume create easv3parent_code
	@$(MAKE) up

# Full Reset Environment
full-reset: down-full up-full

# ENV Update
env-update:
	@./setup/encrypt-upload-env.sh

# ENV Upload (alias for clarity)
env-upload:
	@./setup/encrypt-upload-env.sh

# ENV Download (pulls and decrypts from Azure)
env-download:
	@./setup/init-bash.sh

list:
	@$(SCRIPT) --list

# ---------- Symfony Console ----------
php/console:
	@$(SCRIPT) $(CHILD_WEB) "php bin/console $(ARGS)"

parent/php/console:
	@$(SCRIPT) $(PARENT_WEB) "php bin/console $(ARGS)"

# Common shortcuts
cache/clear:
	@$(MAKE) php/console ARGS="cache:clear"

parent/cache/clear:
	@$(MAKE) parent/php/console ARGS="cache:clear"

# ---------- PHPUnit ----------
php/unit:
	@$(SCRIPT) $(CHILD_WEB) "if [ -x vendor/bin/phpunit ]; then vendor/bin/phpunit $(ARGS); else php bin/phpunit $(ARGS); fi"

parent/php/unit:
	@$(SCRIPT) $(PARENT_WEB) "if [ -x vendor/bin/phpunit ]; then vendor/bin/phpunit $(ARGS); else php bin/phpunit $(ARGS); fi"

# ---------- Shell helpers ----------
web/shell:
	@docker exec -it $(CHILD_WEB) bash

parent/web/shell:
	@docker exec -it $(PARENT_WEB) bash

db/shell:
	@docker exec -it $(CHILD_DB) mysql -u root -p

parent/db/shell:
	@docker exec -it $(PARENT_DB) mysql -u root -p

nginx/test:
	@$(SCRIPT) $(NGINX_SVC) "nginx -t"

