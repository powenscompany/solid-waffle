# Dependency Management Migration Guide

This document explains the improvements made to dependency management and how to use the new system.

## What Changed

### Before (Old System)
- Complex `additional_bashrc` with mixed concerns
- Single `install_deps.sh` script handling everything
- Manual dependency management scattered across functions
- No container-specific task automation

### After (New System)
- Clean separation of concerns
- Structured dependency installation with `scripts/setup-deps.sh`
- Container-specific Taskfile for development workflows
- Simplified bashrc focused on essential functions
- Better error handling and logging

## New File Structure

```
solid-waffle/
├── scripts/
│   ├── setup-deps.sh           # Clean dependency installation
│   └── validate-setup.sh       # Validates the development environment
├── container-Taskfile.yml      # Renamed to Taskfile.yml in container
├── container-bashrc            # Simplified bashrc additions
├── Taskfile.yml               # Host-level tasks (unchanged)
├── additional_bashrc          # Legacy (still works)
└── install_deps.sh            # Legacy (still works)
```

## Migration Steps

### 1. Rebuild Container (Recommended)
```bash
# Stop current services
task down

# Rebuild with new configuration
task build

# Start services
task up

# Connect to container
task shell
```

### 2. Inside Container - New Workflow

#### Option A: Use New Setup Script
```bash
# Run the new dependency setup
cd /home/budgea_user/dev
./scripts/setup-deps.sh

# Or from host:
task setup:deps
```

#### Option B: Use New Task-based Workflow
```bash
# See available tasks
task

# Install dependencies step by step
task deps:install

# Run full setup
task setup:full

# Start development servers
task dev:both    # Both servers in tmux
task dev:budgea  # Just budgea server
task dev:wsgi    # Just wsgi server
```

### 3. Development Workflow

#### Starting Development Servers
```bash
# Old way (still works):
budgea &
budgea.wsgi &

# New way - both servers in tmux:
task dev:both

# Attach to tmux session:
task dev:attach

# Stop servers:
task dev:stop
```

#### Managing Dependencies
```bash
# Install all dependencies:
task deps:install

# Sync backend only:
task deps:sync

# Update woob only:
task deps:woob
```

#### Database and Setup Tasks
```bash
# Setup database:
task db:setup

# Create database user:
task db:user

# Generate keys:
task setup:keys

# Full setup (equivalent to old full_setup):
task setup:full
```

## Key Improvements

### 1. Better Error Handling
- Colored output for better visibility
- Proper error checking at each step
- Clear success/failure messages

### 2. Modular Design
- Separate functions for each concern
- Easy to run individual steps
- Better debugging capabilities

### 3. Container-Specific Tasks

- `container-Taskfile.yml` is mounted as `Taskfile.yml` inside the container, allowing you to use `task` commands directly.
- Development server management
- Environment status checking

### 4. Backward Compatibility
- Old functions still work
- Gradual migration possible
- No breaking changes

## Troubleshooting

### Virtual Environment Issues
```bash
# Check environment status:
task env:status

# Recreate environment:
rm -rf /home/budgea_user/dev/backend/.venv
./scripts/setup-deps.sh
```

### Dependency Issues
```bash
# Clean and reinstall:
task clean:cache
task deps:install
```

### Development Server Issues
```bash
# Check if servers are running:
ps aux | grep budgea

# Kill existing servers:
task dev:stop
pkill -f budgea

# Start fresh:
task dev:both
```

## Host-Level Tasks (Unchanged)

These tasks run from your host machine and remain the same:

```bash
task up           # Start services
task down         # Stop services
task shell        # Connect to container
task logs         # View logs
task status       # Check service status
```

## Benefits

1. **Cleaner Code**: Separated concerns, better organization
2. **Better DX**: Task-based workflow, tmux integration
3. **Easier Debugging**: Colored output, step-by-step execution
4. **More Reliable**: Better error handling, environment validation
5. **Future-Ready**: Prepared for woob's pyproject.toml migration

## Legacy Support

The old system continues to work:
- `additional_bashrc` functions are still available
- `install_deps.sh` still works
- `full_setup` function unchanged

You can migrate gradually or continue using the old system if preferred.