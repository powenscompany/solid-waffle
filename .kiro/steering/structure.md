# Project Structure

## Directory Organization

### Expected Development Directory Layout
```
/Users/username/dev/  (or /home/username/dev/ on Linux)
├── backend/                 # Backend source code (mounted for live changes)
├── woob/                   # Woob source code (mounted for live changes)
├── apishell/               # API shell utilities (mounted for live changes)
├── proxynet.pem            # ProxyNet certificate (required)
└── solid-waffle/           # This project
    ├── .env                # Environment variables
    ├── docker-compose.yml  # Service orchestration
    ├── Dockerfile          # Container definition
    # setup.sh removed - using task-based setup instead
    └── scripts/            # Setup and utility scripts
```

### Solid Waffle Project Structure
```
solid-waffle/
├── .env                        # Local environment configuration
├── .env.example               # Environment template
├── docker-compose.yml         # Service definitions
├── Dockerfile                 # Development container
├── Dockerfile.lean           # Lean container approach
├── Makefile                  # Legacy task runner
├── Taskfile.yml             # Modern task runner (host)
# setup.sh removed - using task-based setup instead
├── install_deps.sh          # Legacy dependency installer
# additional_bashrc removed - using container-bashrc instead
├── container-bashrc         # Clean container bashrc additions
├── container-Taskfile.yml   # Container-specific tasks
├── scripts/
│   ├── setup-deps.sh        # Clean dependency installation
│   ├── setup-environment.sh # Complete environment setup
│   └── validate-setup.sh    # Environment validation
├── session_folders/         # Mounted as container data directories
└── .kiro/
    └── steering/           # AI assistant guidance files
```

## Volume Mounting Strategy

### Mounted for Development (Live Changes)
- `../backend` → `/home/budgea_user/dev/backend`
- `../woob` → `/home/budgea_user/dev/woob`
- `../apishell` → `/home/budgea_user/dev/apishell`
- `./scripts` → `/home/budgea_user/dev/scripts`
- `./container-Taskfile.yml` → `/home/budgea_user/dev/Taskfile.yml`

### Container-Managed Volumes
- `backend_venv`: Backend virtual environment (prevents host interference)
- `mariadb_data`: Database persistence

### Configuration Mounts
- `~/.ssh` → `/home/budgea_user/.ssh` (read-only)
- `../proxynet.pem` → `/home/budgea_user/dev/proxynet.pem` (read-only)
- `./session_folders` → `/var/log/bi/data` and `/home/budgea_user/data`

## Container Internal Structure

### Key Directories Inside Container
```
/home/budgea_user/
├── dev/                    # Main development workspace
│   ├── backend/           # Backend source (mounted)
│   │   └── .venv/        # Virtual environment (volume)
│   ├── woob/             # Woob source (mounted)
│   ├── apishell/         # Apishell source (mounted)
│   ├── scripts/          # Setup scripts (mounted)
│   ├── Taskfile.yml      # Container tasks (mounted)
│   └── proxynet.pem      # SSL certificate (mounted)
├── data/                 # Application data
├── sessions/             # Session storage
└── .ssh/                 # SSH keys (mounted)
```

### System Directories
- `/var/log/bi/`: Application logs
- `/etc/bi/`: Configuration files
- `/opt/playwright-browsers/`: Browser automation

## File Naming Conventions

### Configuration Files
- `.env`: Local environment variables (never commit)
- `.env.example`: Environment template (commit this)
- `*-Taskfile.yml`: Task definitions for specific contexts
- `container-*`: Files specific to container environment

### Scripts
- `setup-*.sh`: Setup and initialization scripts
- `validate-*.sh`: Validation and testing scripts
- Executable permissions required for all `.sh` files

### Documentation
- `*_MIGRATION.md`: Migration guides between versions
- `*_BEST_PRACTICES.md`: Best practice documentation
- `*_ANALYSIS.md`: Technical analysis documents

## Service Architecture

### Docker Compose Services
- `backend`: Main development container
- `webview`: Frontend UI (pre-built image)
- `mariadb`: Database server
- `gearmand`: Job queue server

### Network Configuration
- All services use `backend-network` bridge network
- Internal service communication via service names
- External access via mapped ports

## Development Workflow Paths

### Host Machine (Outside Container)
- Edit code in `../backend/`, `../woob/`, `../apishell/`
- Run `task` commands for container management
- Access services via `localhost` ports

### Inside Container
- Use `task` commands for development workflows
- Activate environment with `devenv`
- All development tools available in PATH
- Virtual environment automatically managed

## Important Path Variables

### Environment Variables
- `WORKDIR`: `/home/budgea_user/dev`
- `PYTHONPATH`: Includes backend, woob, and site-packages
- `PATH`: Includes virtual environment and scripts
- `VENV_DIR`: `/home/budgea_user/dev/backend/.venv`

### Key Paths to Remember
- Backend code: `/home/budgea_user/dev/backend`
- Woob modules: `/home/budgea_user/dev/woob`
- Virtual environment: `/home/budgea_user/dev/backend/.venv`
- Scripts: `/home/budgea_user/dev/scripts`
- Logs: `/var/log/bi/`