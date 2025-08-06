# 🧇 Solid Waffle - Powens Full Stack Development Environment

This project provides a Docker-based development environment for the complete Powens stack, allowing you to test the full application locally on both macOS and Debian/Linux systems using a Debian Bookworm container. While the backend installation is the most complex part (hence the containerization), this setup includes webview, woob, backend, and apishell components.

## Architecture Considerations

This setup is optimized for development on multiple platforms with architecture-specific optimizations:

### Fast Development (Recommended)

- **File**: `Dockerfile`
- **Platform**: Native architecture (ARM64 on Apple Silicon, x86_64 on Intel/AMD)
- **Use case**: Daily development, testing local changes
- **Build**: `make build` or `docker-compose build`
- **Performance**: Fast on both ARM Macs and x86_64 Linux systems

### Production-Exact Testing

- **File**: `Dockerfile.production`
- **Platform**: AMD64 with emulation when needed (exact production match)
- **Use case**: Final testing before deployment, debugging production-specific issues
- **Build**: `make build-production`

⚠️ **Performance Notes**:

- **ARM Macs**: Production Dockerfile will be slower due to x86_64 emulation
- **x86_64 Linux/Debian**: Both Dockerfiles will have similar performance
- **Intel Macs**: Native performance for both options

## Features

- 🐳 **Full Stack Environment**: Complete Powens stack (webview, backend, woob, apishell) in containers
- 🖥️ **Multi-platform**: Works on ARM64 Macs, Intel Macs, and x86_64 Linux/Debian with optimized performance
- 🏭 **Production-like environment**: Uses the same base image and configuration as production
- 🔁 **Live code mounting**: Local backend, woob, and apishell changes are immediately reflected in the container
- 🌐 **Webview integration**: Frontend served from pre-built Docker image (no local repo needed)
- 🔐 **Environment secrets**: Supports your shell environment variables (zsh/bash)
- 🗄️ **Database setup**: Includes MariaDB with automated setup scripts
- ⚙️ **Gearman support**: Includes gearman job server for background tasks
- 🔧 **Development tools**: Pre-configured with all necessary development utilities

## Stack Components

| Component | Purpose | Volume Mounted | Development Access | Source |
|-----------|---------|----------------|-------------------|---------|
| **Webview** | Frontend UI | ❌ (pre-built image) | Via browser | GitLab Registry |
| **Backend** | API Server | ✅ (live changes) | Direct code editing | Local repository |
| **Woob** | Banking connectors | ✅ (live changes) | Direct code editing | Local repository |
| **Apishell** | API utilities | ✅ (live changes) | Direct code editing | Local repository |

**Development Strategy**: Only woob, backend, and apishell are mounted as volumes since these are the components developers typically modify and need to test changes on. The webview uses a pre-built Docker image from GitLab registry and connects to your live backend changes.

## Job Manager: Gearman vs Celery

This development environment uses **Gearman** as the job manager for background tasks. While the backend supports both Gearman and Celery, we chose Gearman for the following reasons:

### Why Gearman for Development?

- **Simpler setup**: Single container vs multiple (RabbitMQ + Redis for Celery)
- **Lighter resource usage**: Better for local development on laptops and workstations
- **Faster startup**: Fewer services to initialize and orchestrate
- **Production alignment**: Matches our current production configuration

### Gearman vs Celery Comparison

| Feature | Gearman | Celery |
|---------|---------|---------|
| Infrastructure | Single gearman server | RabbitMQ + Redis |
| Containers needed | 1 | 3+ |
| SSL/TLS | Basic | Full support |
| Monitoring | Custom scripts | Built-in (Flower) |
| Complexity | Low | High |

# TODO: adapt doc to .env only
If you need to test Celery locally, modify the job manager configuration in `backend.conf`:

```ini
# Switch to Celery (requires additional containers)
[jobs]
manager = celery
broker_url = amqp://budgea:budgea@rabbitmq:5672
result_backend = redis://:@redis:6379/0
```

**Current choice**: Gearman for simplicity and development speed. ⚡

## Directory Structure

Ensure your development directory follows this structure:

**macOS Example**:

```
/Users/bob.sponge/dev/
├── backend/                 # Backend source code (mounted for live changes)
├── woob/                   # Woob source code (mounted for live changes)
├── apishell/               # API shell utilities (mounted for live changes)
├── proxynet.pem            # ProxyNet certificate
└── solid-waffle/           # This project
    ├── Dockerfile
    ├── docker-compose.yml
    ├── setup.sh
    └── .env                # Your environment variables
```

**Debian/Linux Example**:

```
/home/bob.sponge/dev/
├── backend/                 # Backend source code (mounted for live changes)
├── woob/                   # Woob source code (mounted for live changes)
├── apishell/               # API shell utilities (mounted for live changes)
├── proxynet.pem            # ProxyNet certificate
└── solid-waffle/           # This project
    ├── Dockerfile
    ├── docker-compose.yml
    ├── setup.sh
    └── .env                # Your environment variables
```

**Volume Mounting Strategy**:

- ✅ **Mounted**: `backend/`, `woob/`, `apishell/` - for live development
- ❌ **Not Mounted**: `webview/` - uses pre-built Docker image, no local repository needed

#TODO: not GITLAB !!!
**Note**: The webview component is served from a pre-built Docker image (`registry.gitlab.com/budget-insight/webview:latest`), eliminating the need for a local webview repository. The `gearman==2.0.3` dependency is handled automatically through the backend's `pyproject.toml` and your private package registry.

## Quick Start

1. **Setup environment variables**:

   ```bash
   cd solid-waffle
   cp .env.example .env
   # Edit .env with your actual values from shell environment (~/.zshrc, ~/.bashrc, etc.)
   ```

2. **Run setup script**:

   ```bash
   ./setup.sh
   ```

3. **Start the full stack**:

   For daily development (native architecture):

   ```bash
   docker-compose up -d
   # or
   make up
   ```

   For production-exact testing (x86_64 emulation on ARM):

   ```bash
   docker-compose --profile production up -d
   # or
   make up-production
   ```

4. **Connect to the container**:

   Development version:

   ```bash
   docker-compose exec backend bash
   # or 
   make shell
   ```

   Production version:

   ```bash
   make shell-production
   ```

5. **Run full setup inside container**:

   ```bash
   full_setup
   ```

6. **Access the application**:
   - **Webview (Frontend)**: <http://localhost:8080>
   - **Backend API**: <http://localhost:3158>
   - **API Documentation**: <http://localhost:3158/docs>

## Advanced Usage

### Selective Service Startup

You can start specific components based on your development needs:

```bash
# Start only backend services (no webview)
docker-compose up -d backend mariadb gearmand

# Start only webview with existing backend
docker-compose up -d webview

# Start production stack for testing
docker-compose --profile production up -d

# Start production webview only (connects to production backend on port 3159)
docker-compose up -d webview-production
```

### Multiple Environment Testing

Test different configurations simultaneously:

```bash
# Development environment
docker-compose up -d
# Access at: http://localhost:8080 (webview) and http://localhost:3158 (backend)

# Production environment (in addition to development)
docker-compose --profile production up -d
# Access at: http://localhost:8081 (webview) and http://localhost:3159 (backend)
```

### Webview Version Control

By default, the webview uses the `latest` image. You can specify a different version:

```bash
# Use latest version (default)
docker-compose up -d

# Use specific version via environment variable
WEBVIEW_RELEASE_TAG=4.48.0 docker-compose up -d

# Or set in .env file
echo "WEBVIEW_RELEASE_TAG=4.48.0" >> .env
docker-compose up -d
```

## Platform-Specific Notes

### macOS (Intel & Apple Silicon)

- **Docker Desktop**: Ensure sufficient resources allocated (8GB+ RAM recommended)
- **Performance**: ARM Macs benefit most from native ARM64 builds
- **File sharing**: Docker Desktop handles volume mounting automatically

### Debian/Linux

- **Docker Engine**: Install via package manager or official Docker installation
- **Permissions**: Ensure your user is in the `docker` group:

  ```bash
  sudo usermod -aG docker $USER
  # Log out and back in for changes to take effect
  ```

- **Performance**: Native x86_64 performance, both Dockerfiles work well
- **File permissions**: Volume mounts preserve local file ownership

### Architecture Detection

The setup automatically detects your platform:

```bash
# Check your architecture
uname -m
# arm64 (Apple Silicon) / x86_64 (Intel/AMD)

# Docker will use the appropriate base image
docker info | grep Architecture
```

## Available Commands (Inside Container)

| Command | Description |
|---------|-------------|
| `devenv` | Activate Python virtual environment |
| `gm` | Start gearman job server |
| `full_setup` | Complete setup (dependencies, database, woob, keys, client) |
| `install_deps` | Install all Python dependencies (backend + woob) |
| `setup_local_db` | Setup local database only |
| `update_woob` | Update woob modules |
| `keys` | Generate frontend/backend keys |
| `create_client` | Create API client |

## Environment Variables

Key environment variables from your shell that should be in `.env`:

```bash
# SSH and API Keys
BI_SSH_KEY=/home/budgea/.ssh/id_rsa

# UV_INSECURE_HOST=*

# Backend Configuration
PW_CONFIG_FILES=backend.conf
PW_API_PLUGINS=* -jobs -background...
```

**Shell Environment Sources**:

- **macOS zsh**: `~/.zshrc`
- **Linux bash**: `~/.bashrc` or `~/.bash_profile`
- **Linux zsh**: `~/.zshrc`

**ProxyNet Certificate Handling**: The `proxynet.pem` file is mounted from your local dev directory into the container and configured via SSL environment variables. This allows for dynamic certificate updates without rebuilding the container image.

## Services

| Service | Port | Description | Access | Profile |
|---------|------|-------------|--------|---------|
| Webview (Frontend) | 8080 | Development frontend | <http://localhost:8080> | default |
| Backend API | 3158 | Development backend API | <http://localhost:3158> | default |
| Webview (Production) | 8081 | Production frontend | <http://localhost:8081> | production |
| Backend API (Production) | 3159 | Production backend API | <http://localhost:3159> | production |
| MariaDB | 3306 | Database server | Internal | default |
| Gearman | 4730 | Job queue server | Internal | default |
| SFTP | 2222 | Test SFTP server | Internal | default |

## Development Workflow

1. **Make changes** to backend, woob, or apishell code in your local directories
2. **Changes are immediately available** in the container (via volume mounts)
3. **Test your changes** in the full stack environment through the webview
4. **Use the same tools** and configurations as production
5. **Debug and iterate** with live reloading

## Troubleshooting

### Container won't start

- Check that all required directories exist (backend, woob, apishell)
- Verify `.env` file is properly configured
- Ensure Docker has enough resources allocated
- **Linux**: Verify user is in docker group and Docker daemon is running

### Webview connection issues

- Ensure backend container is running: `docker-compose ps`
- Check if webview can reach backend: `docker-compose logs webview`
- Verify network connectivity: `docker network ls`
- Check webview image pull: `docker pull registry.gitlab.com/budget-insight/webview:latest`

### Database connection issues

- Ensure MariaDB container is running: `docker-compose ps`
- Check database credentials in `.env`
- Run `create_budgea_db_user` inside container

### Frontend/Backend connection issues

- Verify backend is running on port 3158
- Check webview configuration points to correct backend URL
- Ensure all services are in the same Docker network

### SSL/Certificate issues

- Verify `proxynet.pem` exists in your dev directory and is readable
<!-- - Ensure UV_INSECURE_HOST is set to `*` -->
- The certificate is mounted as read-only from your local `../proxynet.pem`

### Woob modules not found

- Run `install_woob` inside container
- Check that woob directory is properly mounted
- Verify virtual environment is activated

### Platform-specific issues

#### macOS

- **Docker Desktop issues**: Restart Docker Desktop or increase resource limits
- **Volume mounting slow**: Consider using delegated mounts or Docker Desktop settings
- **ARM compatibility**: Use native ARM builds when possible

#### Debian/Linux

- **Permission denied**: Ensure user is in docker group: `sudo usermod -aG docker $USER`
- **Docker daemon not running**: Start with `sudo systemctl start docker`
- **SELinux issues**: May need to configure SELinux contexts for volume mounts

### Production vs Development

- Use `docker-compose up -d` for native architecture development (fast on all platforms)
- Use `docker-compose --profile production up -d` for production-exact testing (slower on ARM Macs only)
- Production services run on different ports to avoid conflicts

## Security Notes

- Never commit your `.env` file
- Use `.env.example` as a template
- SSH keys are mounted read-only
- Secrets are handled through environment variables, not build args
- Webview image is pulled from secure GitLab registry

## Quick Installation Summary

This environment allows you to quickly install and run the complete Powens stack on any platform:

1. **Clone required repositories** (backend, woob, apishell) in your dev directory
2. **Configure environment** with `.env` file (from your shell environment)
3. **Run setup script** to initialize everything
4. **Log to the Docker repository** if not already done (see below)
5. **Start with one command** (`docker-compose up -d`)

   The `-d` argument stands for "detached mode," which means Docker Compose will start all services in the background, allowing you to continue using your terminal for other tasks.
6. **Access the full application** at <http://localhost:8080>

Perfect for onboarding new developers or testing full-stack changes locally on macOS, Debian, or any Linux distribution! 🚀

**No local webview repository needed** - the frontend is served from a pre-built Docker image! 🎉

## Access to Powens Repository (ECR)

Docker images are stored on ECR (Elastic Container Registry), and hence we need access to it.

If AWS CLI isn't installed on your machine, use
[the official instructions](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
to get it running.

### AWS Configuration

Your AWS configuration must contain the `[sso]` and `[artifacts]` sections to be able to download secrets from AWS.
These secrets are necessary to install our private version of gearman client, and some NPM packages.

Add the following to `~/.aws/credentials` (create the file if it doesn't exist):

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

### Login Instructions

1. **Log in using JumpCloud:**

    ```bash
    aws sso login --profile artifacts
    ```

2. **Connect to the Docker repository:**

    ```bash
    aws ecr get-login-password --profile artifacts --region eu-west-3 \
    | docker login --username AWS --password-stdin 737968113546.dkr.ecr.eu-west-3.amazonaws.com
    ```

You can view the available images in the ECR console: [https://eu-west-3.console.aws.amazon.com/ecr/private-registry/repositories?region=eu-west-3](https://eu-west-3.console.aws.amazon.com/ecr/private-registry/repositories?region=eu-west-3)
