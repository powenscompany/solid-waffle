# Technology Stack

## Build System & Task Management

### Primary Build Tools
- **Docker & Docker Compose**: Container orchestration and development environment
- **Task (go-task)**: Modern task runner for automation (preferred)
- **Make**: Legacy task runner (still supported)
- **UV**: Fast Python package manager and dependency resolver

### Task Management
Use `task` command for all development workflows:
```bash
task                    # List all available tasks
task up                 # Start all services
task shell              # Connect to backend container
task setup:full         # Run complete setup inside container
```

## Tech Stack

### Backend
- **Language**: Python 3.9.19
- **Framework**: Custom Powens backend framework
- **Package Management**: UV with pyproject.toml
- **Virtual Environment**: Located at `/home/budgea_user/dev/backend/.venv`
- **Server**: WSGI with uwsgi
- **Database**: MariaDB 10.5
- **Job Queue**: Gearman (preferred over Celery for development)

### Frontend
- **Webview**: Pre-built Docker image from ECR registry
- **No local development**: Uses `registry.gitlab.com/budget-insight/webview:latest`
- **Configuration**: Connects to backend via environment variables

### Infrastructure
- **Containerization**: Docker with Debian Bookworm base
- **Networking**: Docker bridge network
- **Volumes**: Persistent storage for database and backend venv
- **SSL**: ProxyNet certificate mounting

## Common Commands

### Container Management
```bash
# Start development environment
task up
docker-compose up -d

# Connect to backend container
task shell
docker-compose exec backend bash

# View logs
task logs
docker-compose logs -f

# Stop services
task down
docker-compose down
```

### Inside Container Development
```bash
# Activate development environment
devenv

# Start both development servers
task dev:both

# Run full setup (database, woob, keys, client)
task setup:full

# Install dependencies
task deps:install

# Run tests
task test:backend
task test:woob
```

### Database Operations
```bash
# Connect to database
task db:shell
docker-compose exec mariadb mysql -uroot -p1245487

# Setup database
task setup-db
```

## Environment Configuration

### Required Environment Files
- `.env`: Local environment variables (copy from `.env.example`)
- `backend/.env.example`: Backend-specific configuration
- `proxynet.pem`: SSL certificate (must exist in parent directory)

### Key Environment Variables
- `ECR_REGISTRY`: Docker registry for webview images
- `WEBVIEW_RELEASE_TAG`: Specific webview version (defaults to 'latest')
- `PW_*`: Powens-specific configuration variables
- `MYSQL_*`: Database connection settings

## Development Workflow

1. **Initial Setup**: Run `./setup.sh` to initialize environment
2. **Container Access**: Use `task shell` to enter development container
3. **Full Setup**: Run `task setup:full` inside container for complete initialization
4. **Development**: Edit code locally, changes reflect immediately in container
5. **Testing**: Use `task test:backend` and `task test:woob` for testing

## Package Management

### UV Package Manager
- **Installation**: Handled automatically in container setup
- **Sync**: `uv sync --frozen` for backend dependencies
- **Virtual Environment**: Managed by UV in backend directory

### Dependency Files
- `backend/pyproject.toml`: Backend Python dependencies
- `woob/.ci/requirements.txt`: Woob core requirements
- `woob/.ci/requirements_modules.txt`: Woob module requirements