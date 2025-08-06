# Docker Backend Development Environment Makefile

.PHONY: help setup build up down clean logs shell test

# Default target
help: ## Show this help message
	@echo "Docker Backend Development Environment"
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Initial setup - create .env and required directories
	@echo "🐳 Setting up Docker Backend Development Environment..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "📝 Created .env file. Please edit with your actual values."; \
	fi
	@mkdir -p etc_bi session_folders
	@echo "✅ Setup complete!"

build: ## Build Docker images (fast ARM64 version for development)
	@echo "🔨 Building Docker images (ARM64 native)..."
	docker-compose build

build-production: ## Build production-exact Docker image (slower on ARM Macs)
	@echo "🔨 Building production-exact Docker image (AMD64 with emulation)..."
	docker build -f Dockerfile.production -t debian11-powens-backend:production .

build-debug: ## Build with verbose output for debugging
	docker-compose build --progress=plain --no-cache

up: ## Start all services (fast ARM64 version)
	@echo "🚀 Starting services (development)..."
	docker-compose up -d

up-production: ## Start production-exact services (slower on ARM Macs)
	@echo "🚀 Starting services (production-exact with emulation)..."
	docker-compose --profile production up -d

down: ## Stop all services
	@echo "🛑 Stopping services..."
	docker-compose down

clean: ## Stop services and remove containers, networks, and volumes
	@echo "🧹 Cleaning up..."
	docker-compose down -v --remove-orphans
	docker system prune -f

logs: ## Show logs from all services
	docker-compose logs -f

logs-backend: ## Show logs from backend service only
	docker-compose logs -f backend

logs-production: ## Show logs from production backend service only
	docker-compose logs -f backend-production

shell: ## Connect to backend container with bash (development)
	docker-compose exec backend bash

shell-production: ## Connect to production-exact backend container with bash
	docker-compose exec backend-production bash

db-shell: ## Connect to MariaDB with mysql client
	docker-compose exec mariadb mysql -uroot -p1245487

restart: ## Restart all services
	@echo "🔄 Restarting services..."
	docker-compose restart

restart-production: ## Restart production services
	@echo "🔄 Restarting production services..."
	docker-compose --profile production restart

status: ## Show status of all services
	docker-compose ps

# Development helpers
full-setup: ## Run full setup inside container (database, woob, keys, client)
	docker-compose exec backend bash -c "full_setup"

install-woob: ## Install woob modules in container
	docker-compose exec backend bash -c "devenv && install_woob"

setup-db: ## Setup local database in container
	docker-compose exec backend bash -c "devenv && setup_local_db"

# Testing
test-backend: ## Run backend tests
	docker-compose exec backend bash -c "devenv && cd /home/budgea_user/dev/budgea && python -m pytest tests/"

test-woob: ## Run woob tests
	docker-compose exec backend bash -c "devenv && cd /home/budgea_user/dev/woob && python -m pytest"

# Utility commands
check-env: ## Check if environment is properly configured
	@echo "🔍 Checking environment configuration..."
	@if [ ! -f .env ]; then echo "❌ .env file missing"; exit 1; fi
	@if [ ! -d ../backend ]; then echo "❌ backend directory missing"; exit 1; fi
	@if [ ! -d ../woob ]; then echo "❌ woob directory missing"; exit 1; fi
	@if [ ! -f ../proxynet.pem ]; then echo "❌ proxynet.pem missing"; exit 1; fi
	@echo "✅ Environment looks good!"

backup-db: ## Backup database data
	@echo "💾 Creating database backup..."
	docker-compose exec mariadb mysqldump -uroot -p1245487 --all-databases > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "✅ Database backup created!"

# Debugging
debug-container: ## Debug container by running with bash and TTY
	docker-compose run --rm backend bash

debug-build: ## Build with verbose output for debugging
	docker-compose build --progress=plain --no-cache

inspect-backend: ## Show detailed information about backend container
	docker-compose exec backend bash -c "env | sort && echo '---' && ps aux"

inspect-production: ## Show detailed information about production backend container
	docker-compose exec backend-production bash -c "env | sort && echo '---' && ps aux"
