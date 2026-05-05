# Early Access System v3 - Developer Environment Makefile
# Comprehensive test environment setup and development tools

.PHONY: help install setup test lint clean coverage quality fix security build dev

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

#==============================================================================
# HELP
#==============================================================================

# Default target
help: ## Show this help message
	@echo "Early Access System v3 - Developer Environment"
	@echo "================================================"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# =============================================================================
# INSTALLATION & SETUP
# =============================================================================

install: ## Install all dependencies (PHP + Node.js)
	@echo "Installing PHP dependencies..."
	composer install --prefer-dist --no-scripts --no-interaction --no-progress --optimize-autoloader
	@echo "Installing Node.js dependencies..."
	npm install
	@echo "✅ All dependencies installed"

setup: install ## Complete development environment setup
	@echo "Setting up development environment..."
	php bin/console doctrine:database:create --if-not-exists
	php bin/console doctrine:migrations:migrate --no-interaction
	php bin/console cache:clear
	npm run build
	@echo "✅ Development environment ready"

setup-test: ## Setup test environment
	@echo "Setting up test environment..."
	php bin/console --env=test doctrine:database:create --if-not-exists
	php bin/console --env=test doctrine:migrations:migrate --no-interaction
	php bin/console --env=test cache:clear
	@echo "✅ Test environment ready"

# =============================================================================
# PHP TESTING & QUALITY ASSURANCE
# =============================================================================

test: ## Run all PHP tests
	composer test

test-unit: ## Run PHP unit tests only
	composer test:unit

test-integration: ## Run PHP integration tests only
	composer test:integration

test-feature: ## Run PHP feature tests only
	composer test:feature

test-coverage: ## Generate PHP test coverage report
	composer test:coverage

test-coverage-check: ## Check PHP test coverage with text output
	composer test:coverage-check

phpstan: ## Run PHPStan static analysis
	composer phpstan

rector: ## Run Rector code analysis (dry-run)
	composer rector

rector-fix: ## Apply Rector fixes
	vendor/bin/rector process src

cs-fixer: ## Run PHP CS Fixer
	composer cs-fixer

cs-fixer-dry: ## Run PHP CS Fixer in dry-run mode
	vendor/bin/php-cs-fixer fix --dry-run --diff

infection: ## Run Infection mutation testing
	composer infection

# =============================================================================
# JAVASCRIPT/NODE.JS TESTING
# =============================================================================

test-js: ## Run JavaScript tests with Vitest
	npm run test

test-js-watch: ## Run JavaScript tests in watch mode
	npm run test:watch

test-js-coverage: ## Generate JavaScript test coverage
	npm run test:coverage

test-js-ui: ## Run JavaScript tests with UI
	npm run test:ui

test-e2e: ## Run end-to-end tests with Playwright
	npm run test:e2e

test-e2e-ui: ## Run Playwright tests with UI
	npx playwright test --ui

test-monitoring: ## Run monitoring tests with Checkly
	npm run test:monitoring

test-report: ## Show Playwright test report
	npm run test:report

test-all: ## Run all tests (PHP + JS + E2E)
	npm run test:all

test-ci: ## Run tests for CI environment
	npm run test:ci

# =============================================================================
# CODE QUALITY & LINTING
# =============================================================================

lint: ## Run all linters
	npm run lint
	npm run stylelint
	npm run test:contrast

lint-fix: ## Fix all linting issues
	npm run lint:fix
	npm run stylelint:fix

contrast-test: ## Run WCAG contrast ratio validation
	npm run test:contrast

lint-js: ## Run JavaScript/TypeScript linting
	npm run lint

lint-js-fix: ## Fix JavaScript/TypeScript linting issues
	npm run lint:fix

lint-css: ## Run CSS/SCSS linting
	npm run stylelint

lint-css-fix: ## Fix CSS/SCSS linting issues
	npm run stylelint:fix

# =============================================================================
# SECURITY & VALIDATION
# =============================================================================

security: ## Run all security checks
	npm run security:audit
	composer audit

security-fix: ## Fix security vulnerabilities
	npm run security:fix

security-audit: ## Run npm security audit
	npm run security:audit

validate: ## Run package validation
	npm run validate

validate-packages: ## Validate package configurations
	npm run validate:packages

validate-scripts: ## Validate script configurations
	npm run validate:scripts

# =============================================================================
# BUILD & DEVELOPMENT
# =============================================================================

dev: ## Start development server
	npm run dev

build: ## Build assets for production
	npm run build

preview: ## Preview production build
	npm run preview

# =============================================================================
# SYMFONY SPECIFIC
# =============================================================================

symfony-cache-clear: ## Clear Symfony cache
	php bin/console cache:clear

symfony-cache-warmup: ## Warmup Symfony cache
	php bin/console cache:warmup

symfony-assets: ## Install Symfony assets
	php bin/console assets:install

symfony-db-create: ## Create database
	php bin/console doctrine:database:create

symfony-db-migrate: ## Run database migrations
	php bin/console doctrine:migrations:migrate --no-interaction

symfony-db-fixtures: ## Load database fixtures
	php bin/console doctrine:fixtures:load --no-interaction

symfony-make-entity: ## Create new Doctrine entity
	php bin/console make:entity

symfony-make-controller: ## Create new controller
	php bin/console make:controller

symfony-make-form: ## Create new form
	php bin/console make:form

symfony-make-migration: ## Create new migration
	php bin/console make:migration

# =============================================================================
# UTILITIES & MAINTENANCE
# =============================================================================

find-tests: ## Find all test files in the project
	npm run find:tests

activities-archive: ## Archive activities using bash script
	npm run activities:archive

coverage-badge: ## Generate coverage badge
	composer coverage:badge

clean: ## Clean all caches and temporary files (preserves protected coverage data)
	@echo "Cleaning caches and temporary files..."
	@echo "⚠️  Preserving protected coverage files..."
	rm -rf var/cache/*
	rm -rf var/log/*
	rm -rf node_modules/.cache
	rm -rf build/
	# Note: coverage/ directory is protected and preserved during cleanup
	npm run build
	php bin/console cache:clear
	@echo "✅ Cleanup complete (coverage data preserved)"

reset: clean install setup ## Reset entire development environment
	@echo "✅ Development environment reset complete"

# =============================================================================
# DOCKER SUPPORT (if using Docker)
# =============================================================================

docker-build: ## Build Docker containers
	docker-compose build

docker-up: ## Start Docker containers
	docker-compose up -d

docker-down: ## Stop Docker containers
	docker-compose down

docker-logs: ## View Docker logs
	docker-compose logs -f

# =============================================================================
# QUICK TESTING COMBINATIONS
# =============================================================================

test-quick: ## Run quick tests (unit + JS)
	composer test:unit
	npm run test

test-full: ## Run full test suite
	make test-coverage
	make test-js-coverage
	make test-e2e
	make phpstan
	make lint

test-pre-commit: ## Run tests before commit
	make lint
	make test-quick
	make security-audit

# =============================================================================
# DEVELOPMENT WORKFLOW
# =============================================================================

pre-commit: test-pre-commit ## Pre-commit checks

pre-push: test-full ## Pre-push full validation

release-check: ## Check if ready for release
	make test-full
	make security
	make validate
	@echo "✅ Release checks passed"