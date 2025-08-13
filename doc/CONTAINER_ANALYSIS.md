# Container Design Analysis

## Current Issues

### 1. **Redundancy Between Dockerfile and Scripts**

**Dockerfile does:**
- Installs system Python packages (python3-*)
- Sets up user and directories
- Copies and sets up bashrc
- Installs tmux

**setup-deps.sh does:**
- Installs UV
- Creates virtual environment
- Installs Python packages via UV
- Sets up woob dependencies

**Problem:** System Python packages vs UV-managed packages conflict

### 2. **Questionable Dockerfile Choices**

```dockerfile
# ❌ Installing tons of system Python packages
python3-alembic python3-pyflakes python3-bcrypt python3-bs4 \
python3-dateutil python3-dev python3-ecdsa python3-flask \
# ... 30+ more packages

# ❌ This conflicts with UV-managed dependencies
```

**Issues:**
- System packages can conflict with UV-managed versions
- Harder to manage dependency versions
- Bloated image size
- Mixing package managers (apt + UV)

### 3. **Build vs Runtime Confusion**

**Should be at BUILD time:**
- System dependencies (libraries, compilers)
- User creation
- Directory structure
- Base tools (curl, git, etc.)

**Should be at RUNTIME:**
- Python virtual environment
- Application dependencies
- Project-specific setup
- Development tools

## Recommended Approach

### Option A: Lean Container (Recommended)

**Dockerfile should only:**
```dockerfile
# System dependencies only
RUN apt-get install build-essential libmariadb-dev curl git tmux

# User setup
RUN useradd budgea_user

# Basic directory structure
RUN mkdir -p /home/budgea_user/dev
```

**Runtime scripts handle:**
- UV installation
- Virtual environment creation
- Python dependencies
- Project setup

### Option B: Hybrid Approach (Current + Cleanup)

Keep current approach but:
- Remove system Python packages
- Let UV handle all Python dependencies
- Move development tools to runtime

## Benefits of Lean Approach

1. **Faster builds** - Only rebuild when system deps change
2. **Smaller images** - No redundant packages
3. **Cleaner separation** - Build vs runtime concerns
4. **Easier debugging** - Clear responsibility boundaries
5. **Better caching** - Docker layer caching more effective