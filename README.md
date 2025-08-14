# 🧇 Solid Waffle - Powens Full Stack Development Environment

A Docker-based development environment for the complete Powens stack, enabling local testing of the full application on both macOS and Linux systems using a Debian Bookworm container.

## 🚀 Quick Start

> **First time setup?** Make sure to follow all installation steps including `task build` to create the Docker image.

### Prerequisites

1. **Task Runner**: Install the Task tool on your host system:
   - **Installation guide**: https://taskfile.dev/docs/installation
   - **Quick install** (most systems):
     ```bash
     # macOS (Homebrew)
     brew install go-task/tap/go-task
     
     # Linux (snap)
     sudo snap install task --classic
     
     # Or use install script
     sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d
     ```

2. **Directory Structure**: Ensure your development directory follows this structure:

   ```
   /Users/username/dev/  (or /home/username/dev/ on Linux)
   ├── backend/                # Backend source code (mounted for live changes)
   ├── woob/                   # Woob source code (mounted for live changes)
   ├── apishell/               # API shell utilities (mounted for live changes)
   ├── proxynet.pem            # ProxyNet certificate (required)
   └── solid-waffle/           # This project
       ├── .env                # Your environment variables
       ├── docker-compose.yml  # Service orchestration
       ├── Taskfile.yml        # Host task automation
       └── ...
   ```

3. **AWS ECR Access**: You need access to the Powens Docker registry for the webview image.

### Installation Steps

1. **Configure Environment**:

   ```bash
   cd solid-waffle
   cp .env.example .env
   # Edit .env with your actual values (see Environment Configuration section)
   ```

2. **Build Docker Image**:

   ```bash
   task build  # Builds the bookworm-powens-stack image
   ```

3. **Login to ECR** (if not already done):

   ```bash
   task ecr-login
   ```

4. **Run Initial Setup**:

   ```bash
   task setup  # Creates required directories and validates environment
   ```

5. **Start Services**:

   ```bash
   task up
   ```

6. **Enter Container and Complete Setup**:
   <!-- TODO: automate `cd dev`-->
   ```bash
   task shell
   cd dev
   # Inside container:
   task setup:full
   ```

7. **Access Application**:
   <!-- TODO: should be port 4200 for webview, to fix when fully implementing webview -->
   - **Frontend (Webview)**: <http://localhost:8080>
   - **Backend API**: <http://localhost:3158>
   - **API Documentation**: <http://localhost:3158/docs>

## 📋 Installation Sequence Explained

### 1. Environment File Creation (.env)

The `.env` file contains your personal configuration that gets loaded into the container:

```bash
# Copy template and customize
cp .env.example .env
```

**Key variables to customize**:

- `ECR_REGISTRY`: Docker registry URL for webview images
- `WEBVIEW_RELEASE_TAG`: Specific webview version (defaults to 'latest')
- Database credentials and API configuration
- SSL certificate paths

### 2. File and Folder Mounting

Docker Compose automatically mounts:

**Source Code (Live Development)**:

- `../backend` → `/home/budgea_user/dev/backend` (DB, API and aggregation orchestrator)
- `../woob` → `/home/budgea_user/dev/woob` (scraping connectors)
- `../apishell` → `/home/budgea_user/dev/apishell` (API utilities)

**Configuration Files**:

- `./container-Taskfile.yml` → `/home/budgea_user/dev/Taskfile.yml` (task automation)
- `./container-bashrc` → `/home/budgea_user/dev/container-bashrc` (bash functions)
- `./scripts/` → `/home/budgea_user/dev/scripts/` (setup scripts)

**Persistent Data**:

- `backend_venv` volume → `/home/budgea_user/dev/backend/.venv` (Python virtual environment)
- `mariadb_data` volume → `/var/lib/mysql` (database persistence)

**Security**:

- `~/.ssh` → `/home/budgea_user/.ssh` (read-only SSH keys)
- `../proxynet.pem` → `/home/budgea_user/dev/proxynet.pem` (read-only SSL certificate)

### 3. Essential Task Commands

**Quick Start Commands**:

```bash
task up           # Start all services
task shell        # Enter container
task down         # Stop all services
task logs         # View service logs
```

**Inside Container - Setup Commands**:

```bash
task setup:full   # Complete setup (recommended)
task setup:environment  # Environment setup only
task woob:update  # Update woob modules metadata
task db:setup     # Setup databases
task setup:keys   # Generate encryption keys
```

**Inside Container - Development Commands**:

```bash
task dev:both     # Start both servers in tmux
task dev:budgea   # Start budgea server only
task dev:wsgi     # Start wsgi server only
task dev:attach   # Attach to tmux session
task dev:stop     # Stop development servers
```

### 4. Environment Installation Process

When you run `task setup:environment`, here's what happens:

#### A. Container Bashrc Setup

- Sources `/home/budgea_user/dev/container-bashrc` with development functions
- Sets up PATH and PYTHONPATH environment variables
- Configures aliases and helper functions
- Auto-activates Python virtual environment on login

#### B. Python Virtual Environment

- **Location**: `/home/budgea_user/dev/backend/.venv` (Docker volume)
- **Manager**: UV (fast Python package manager)
- **Python Version**: 3.9.19 It matches production and has best performance for every platform (need more CPython build otherwise)
- **Isolation**: Separate from host system to avoid conflicts

#### C. System Paths Configuration

```bash
# Automatically configured paths:
PATH=$PATH:$HOME/dev/backend/scripts:$HOME/.local/bin
PYTHONPATH=$PYTHONPATH:$HOME/dev/backend:$HOME/dev/woob
BUDGEA_VENV_DIR="$HOME/dev/backend/.venv"
```

#### D. System Dependencies

The container comes pre-installed with:

- Python 3.9.19 and development tools
- UV package manager
- Task runner
- Database clients (MySQL/MariaDB)
- SSH and networking tools
- tmux for session management

## 🏗️ Architecture Overview

### Stack Components

| Component    | Purpose            | Development Access  | Source           |
| ------------ | ------------------ | ------------------- | ---------------- |
| **Backend**  | API Server         | ✅ Live code editing | Local repository |
| **Woob**     | Banking connectors | ✅ Live code editing | Local repository |
| **Apishell** | API utilities      | ✅ Live code editing | Local repository |
| **Webview**  | Frontend UI        | ❌ Pre-built image   | ECR Registry     |
| **MariaDB**  | Database           | 🔧 Via container     | Docker image     |
| **Gearman**  | Job queue          | 🔧 Via container     | Docker image     |

### Why This Architecture?

- **Live Development**: Only components you actively develop (backend, woob, apishell) are mounted
- **Production Parity**: Uses same base images and configuration as production
- **Simplified Frontend**: Webview uses pre-built image, no local setup needed
- **Isolated Dependencies**: Virtual environment prevents host system conflicts

## 🔧 Environment Configuration

### Required Environment Variables

Create your `.env` file based on `.env.example`:

```bash
# Docker Registry
ECR_REGISTRY=737968113546.dkr.ecr.eu-west-3.amazonaws.com
WEBVIEW_RELEASE_TAG=latest

# Database Configuration
MYSQL_ROOT_PASSWORD=1245487
MYSQL_DB_PASSWORD=qwer

# Backend Configuration
PW_CONFIG_FILES=backend.conf
PW_API_PLUGINS=* -jobs -background -bddf -cleaner -encryption_migration -file_migration -ocr -oidc -payment_background_worker -regulation -categorization -categorization_ds
PW_API_RESTART_ON_UPDATE=1
PW_API_MANDATORY_TRANSACTIONS_PAGINATION=1
PW_SECRETS_PATH=/etc/bi/powens_secrets.json
```

### AWS ECR Authentication

The webview image is hosted on AWS ECR. You need proper authentication:

1. **Configure AWS CLI** with your credentials
2. **Add to `~/.aws/credentials`**:

   ```ini
   [sso]
   sso_start_url = https://d-80672338a9.awsapps.com/start
   sso_region = eu-west-3

   [artifacts]
   sso_start_url = https://d-80672338a9.awsapps.com/start
   sso_region = eu-west-3
   sso_account_id = 737968113546
   sso_role_name = DevelopperRoAccess
   ```

3. **Login**:

   ```bash
   # auto
   task ecr-login

   # or use manual:
   aws sso login --profile artifacts
   # then:
   aws ecr get-login-password --profile artifacts --region eu-west-3 | docker login --username AWS --password-stdin 737968113546.dkr.ecr.eu-west-3.amazonaws.com
   ```

## 🛠️ Development Workflow

### Daily Development

1. **Start Environment**:

   ```bash
   task up
   task shell
   ```

2. **Start Development Servers**:

   ```bash
   task dev:both  # Starts both budgea and budgea.wsgi in tmux
   ```

3. **Make Code Changes**:
   - Edit files in `../backend/`, `../woob/`, or `../apishell/`
   - Changes are immediately available in the container

4. **Test Changes**:
   - Access webview at <http://localhost:8080>
   - API available at <http://localhost:3158>

5. **Manage Development Session**:

   ```bash
   task dev:attach  # Attach to tmux session
   task dev:stop    # Stop servers
   ```

### Database Operations

```bash
# Inside container
task db:setup     # Setup local databases
task db:user      # Create budgea database user

# Direct database access
docker-compose exec mariadb mysql -uroot -p1245487
```

### Woob Module Management

```bash
# Inside container
task woob:update        # Update woob modules metadata (build_modules_metadata.py)
task woob:update-repos  # Update woob repositories (woob update command)
```

## 🔍 Available Services

| Service | Port | Description | URL                   |
| ------- | ---- | ----------- | --------------------- |
| Webview | 8080 | Frontend UI | <http://localhost:8080> |
| Backend | 3158 | API Server  | <http://localhost:3158> |
| MariaDB | 3306 | Database    | Internal only         |
| Gearman | 4730 | Job Queue   | Internal only         |

## 🐛 Troubleshooting

### Build Issues

**Docker build fails**:

```bash
# Try building with verbose output for debugging
task build:debug
# or
docker-compose build --progress=plain --no-cache
```

**Image not found error**:

- Make sure you've run `task build` before `task up`
- Check if the build completed successfully

### Container Issues

**Container won't start**:

- Verify all required directories exist (backend, woob, apishell)
- Check `.env` file configuration
- Ensure Docker has sufficient resources
- Make sure the Docker image was built successfully (`task build`)

**Permission issues**:

- Linux: Add user to docker group: `sudo usermod -aG docker $USER`
- Restart Docker daemon if needed

### ECR Authentication Issues

**403 Forbidden when pulling webview**:

```bash
task ecr-login
# or check authentication status:
task check-ecr-auth
```

### Database Connection Issues

**Can't connect to database**:

```bash
# Inside container
task db:user  # Create database user
# Check if MariaDB is running:
docker-compose ps mariadb
```

### Development Server Issues

**Servers won't start**:

```bash
# Check if virtual environment is activated
devenv
# Check if dependencies are installed
task setup:environment
```

**Can't access webview**:

- Ensure backend is running on port 3158
- Check if all services are up: `docker-compose ps`
- Verify network connectivity between containers

## 🔐 Security Notes

- Never commit your `.env` file (it's in `.gitignore`)
- SSH keys are mounted read-only
- SSL certificates are mounted read-only
- Database passwords should be changed for production use
- ECR authentication tokens expire and need renewal

## 📚 Additional Resources

### Task Commands Reference

**Host Commands** (outside container):

```bash
task setup              # Initial setup (directories, validation)
task build              # Build Docker image
task up/down/restart    # Service management
task shell              # Enter container
task logs               # View logs
task ecr-login          # ECR authentication
```

**Container Commands** (inside container):

```bash
task setup:full         # Complete setup
task dev:both/budgea/wsgi  # Development servers
task db:setup/user      # Database operations
task woob:update        # Woob operations
task test:backend/woob  # Run tests
task clean:cache        # Clean Python cache
```

### Legacy Function Support

These bash functions are still available for backward compatibility:

- `devenv` - Activate virtual environment
- `full_setup` - Complete setup (use `task setup:full` instead)
- `install_deps` - Install dependencies (use `task setup:environment` instead)
- `update_woob` - Update woob (use `task woob:update` instead)

### File Structure Summary

```
solid-waffle/
├── .env                    # Your environment configuration
├── .env.example           # Environment template
├── docker-compose.yml     # Service definitions
├── Dockerfile             # Container definition
├── container-bashrc       # Container bash configuration
├── container-Taskfile.yml # Container task definitions
├── Taskfile.yml          # Host task definitions
├── install_deps.sh        # Legacy dependency installer (backward compatibility)
└── scripts/              # Setup and utility scripts
    ├── setup-environment.sh
    ├── validate-setup.sh
    └── ...
```

---

🎉 **Ready to develop!** This environment provides everything you need to work on the complete Powens stack locally with production-like configuration.
