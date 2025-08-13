# Task Installation Fix

## Problem

The previous setup installed Task (go-task) via `uv pip install go-task-bin` inside the Python virtual environment. This created several issues:

1. **Dependency on venv activation**: Task was only available when the virtual environment was activated
2. **Host command failures**: Running `task validate:setup` from the host machine failed because Task wasn't in the system PATH
3. **Chicken-and-egg problem**: You needed the venv activated to use Task, but might need Task to set up the venv
4. **Inconsistent availability**: Task availability depended on Python environment state

## Solution

Install Task as a system-wide binary using the official installation script, making it available globally regardless of virtual environment state.

### Changes Made

#### 1. Dockerfile Update
```dockerfile
# Install Task (go-task) as system binary
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
```

This installs Task system-wide during container build, making it available to all users and processes.

#### 2. Setup Script Update
Replaced the venv-dependent installation:
```bash
# OLD: Install go-task if not available (package name is go-task-bin per official docs)
if ! python -c 'import shutil; import sys; sys.exit(0 if shutil.which("task") else 1)' 2>/dev/null; then
    log_info "Installing go-task..."
    python -m pip install -U go-task-bin
    log_success "go-task installed"
fi
```

With system verification:
```bash
# NEW: Verify system tools are available
verify_system_tools() {
    log_info "Verifying system tools..."
    
    # Check if task is available (should be installed system-wide in Dockerfile)
    if ! command -v task &> /dev/null; then
        log_error "Task not found in PATH. This should be installed system-wide in the container."
        log_info "Try rebuilding the container with: docker-compose build --no-cache backend"
        exit 1
    else
        log_success "Task available: $(task --version)"
    fi
}
```

#### 3. Test Script Addition
Created `scripts/test-task-availability.sh` to verify Task works:
- Without virtual environment activated
- With virtual environment activated  
- From different directories

## Benefits

1. **Consistent availability**: Task works regardless of Python environment state
2. **Host compatibility**: Commands like `task validate:setup` work from the host
3. **Simplified setup**: No need to manage Task as a Python dependency
4. **Better separation**: System tools are system-wide, Python packages are in venv
5. **Official installation**: Uses the recommended installation method from taskfile.dev

## Usage

After rebuilding the container:

```bash
# From host (works now!)
task validate:setup

# Inside container (always worked)
task --list
task dev:both

# Works with or without venv activated
task env:status
devenv  # activate venv
task env:status  # still works
```

## Migration Steps

1. **Rebuild container**: `docker-compose build --no-cache backend`
2. **Test availability**: `docker-compose exec backend task --version`
3. **Run validation**: `task validate:setup`
4. **Verify from host**: Task commands should work from host machine

## Verification

Run the test script to verify everything works:
```bash
docker-compose exec backend ./scripts/test-task-availability.sh
```

This approach follows the official Task installation recommendations and provides a more robust, predictable development environment.