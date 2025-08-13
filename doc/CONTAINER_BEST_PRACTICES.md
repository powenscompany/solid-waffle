# Container Best Practices: Fat vs Lean Containers

## The Question: Build-time vs Runtime?

You asked a great question about whether to do setup in the Dockerfile or in runtime scripts. Here's the definitive answer:

## Best Practice: Lean Containers

### ✅ **Dockerfile Should Handle (Build-time):**
- **System dependencies** (libraries, compilers, system tools)
- **Base user setup** (user creation, basic directories)
- **Security configuration** (sudo setup, permissions)
- **System-level configuration** (timezone, locale)

### ✅ **Runtime Scripts Should Handle:**
- **Application dependencies** (Python packages, virtual environments)
- **Project-specific setup** (database initialization, key generation)
- **Development tools** (task runners, development servers)
- **Environment activation** (PATH, PYTHONPATH setup)

## Current vs Recommended Approach

### Current "Fat" Dockerfile Issues

```dockerfile
# ❌ BAD: Installing Python packages at build time
RUN apt-get install python3-flask python3-requests python3-numpy...

# ❌ BAD: Mixing package managers
# System packages + UV packages = conflicts

# ❌ BAD: Development-specific setup in production image
COPY container-bashrc /tmp/container-bashrc
RUN cat /tmp/container-bashrc >> ${HOMEDIR}/.bashrc
```

**Problems:**
1. **Version conflicts** between system and UV packages
2. **Bloated images** with unnecessary packages
3. **Slow builds** when dependencies change
4. **Poor caching** - changes invalidate large layers

### Recommended "Lean" Dockerfile

```dockerfile
# ✅ GOOD: Only system dependencies
RUN apt-get install build-essential libmariadb-dev curl git tmux

# ✅ GOOD: Basic user setup
RUN useradd budgea_user && mkdir -p /home/budgea_user/dev

# ✅ GOOD: No Python packages, no app-specific setup
```

**Benefits:**
1. **Faster builds** - system deps rarely change
2. **Better caching** - smaller, more stable layers
3. **No conflicts** - single package manager (UV)
4. **Flexible** - same image for dev/test/prod

## Migration Strategy

### Option 1: Gradual Migration (Safest)

1. **Keep current Dockerfile** but remove Python packages:
   ```dockerfile
   # Remove all python3-* packages
   # Keep system libraries they depend on
   ```

2. **Enhance runtime scripts** to handle removed packages:
   ```bash
   # Let UV install everything Python-related
   uv pip install flask requests numpy...
   ```

3. **Test thoroughly** before removing more

### Option 2: Clean Slate (Recommended)

1. **Use new lean Dockerfile**
2. **Use comprehensive setup script**
3. **Update docker-compose.yml** to use new image
4. **Test and validate**

## Implementation

I've created both approaches for you:

### Files Created:
- `Dockerfile.lean` - Minimal, best-practice Dockerfile
- `scripts/setup-environment.sh` - Complete runtime setup
- `CONTAINER_ANALYSIS.md` - Detailed analysis

### To Try the Lean Approach:

```bash
# Backup current setup
cp Dockerfile Dockerfile.fat

# Use lean Dockerfile
cp Dockerfile.lean Dockerfile

# Update docker-compose to use new setup script
# (I can help with this)

# Rebuild and test
task build
task up
task shell
./scripts/setup-environment.sh
```

## Why Lean is Better

### 1. **Separation of Concerns**
- **Build time**: System setup
- **Runtime**: Application setup
- **Clear boundaries**, easier debugging

### 2. **Better Performance**
- **Faster builds** (system deps cached)
- **Smaller images** (no redundant packages)
- **Better layer caching**

### 3. **More Maintainable**
- **Single source of truth** for Python deps (UV)
- **Easier to update** dependencies
- **Environment parity** (dev = prod)

### 4. **Flexibility**
- **Same image** for different environments
- **Runtime configuration** via scripts
- **Easy to customize** per developer

## Industry Standards

**Most successful projects use lean containers:**
- **Node.js**: System deps in Dockerfile, npm install at runtime
- **Python**: System libs in Dockerfile, pip/poetry at runtime  
- **Go**: Just build tools in Dockerfile, binary at runtime
- **Java**: JRE in Dockerfile, JAR deployment at runtime

## Recommendation

**Use the lean approach** (`Dockerfile.lean` + `setup-environment.sh`):

1. **Cleaner separation** of concerns
2. **Industry best practices**
3. **Better performance** and maintainability
4. **Future-proof** architecture

The current "fat" approach works but creates technical debt. The lean approach is more professional and scalable.