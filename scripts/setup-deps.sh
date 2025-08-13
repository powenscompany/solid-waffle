#!/bin/bash
# Cleaner dependency management script
# Separates backend, woob, and system dependencies

set -euo pipefail

# Configuration
BACKEND_DIR="$HOME/dev/backend"
WOOB_DIR="$HOME/dev/woob"
# TODO: change venv location fo global one?
VENV_DIR="$BACKEND_DIR/.venv"
# TODO: comment why
REQUIRED_PYTHON="3.9.19"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the container
check_environment() {
    if [[ ! -d "$BACKEND_DIR" ]]; then
        log_error "Backend directory not found at $BACKEND_DIR"
        log_info "This script should be run inside the development container"
        exit 1
    fi
    
    if [[ ! -d "$WOOB_DIR" ]]; then
        log_error "Woob directory not found at $WOOB_DIR"
        exit 1
    fi
}

# Ensure log directories have correct permissions
setup_log_directories() {
    log_info "Setting up log directories..."
    
    # Ensure /var/log/bi and subdirectories exist with correct ownership
    sudo mkdir -p /var/log/bi/data
    sudo chown -R "$(whoami):$(id -gn)" /var/log/bi
    
    log_success "Log directories configured"
}

# Ensure UV is available
# TODO: lift uv version pin?
setup_uv() {
    if ! command -v uv &> /dev/null; then
        log_info "Installing uv package manager..."
        pip install "uv==0.5.1"
        log_success "UV installed"
    else
        log_info "UV already available: $(uv --version)"
    fi
}

# Setup Python virtual environment
setup_venv() {
    log_info "Setting up Python virtual environment..."
    
    # Check if venv exists and has correct Python version
    local needs_recreation=false
    
    if [[ -d "$VENV_DIR" ]]; then
        if [[ -x "$VENV_DIR/bin/python" ]]; then
            local current_version
            current_version=$("$VENV_DIR/bin/python" -c 'import sys; print(".".join(map(str, sys.version_info[:3])))' 2>/dev/null || echo "")
            if [[ "$current_version" != "$REQUIRED_PYTHON" ]]; then
                log_warning "Recreating venv: found Python $current_version, need $REQUIRED_PYTHON"
                needs_recreation=true
            fi
        else
            log_warning "Virtual environment corrupted, recreating..."
            needs_recreation=true
        fi
    else
        log_info "Creating new virtual environment..."
        needs_recreation=true
    fi
    
    if [[ "$needs_recreation" == "true" ]]; then
        # Clean existing venv
        if [[ -d "$VENV_DIR" ]]; then
            rm -rf "$VENV_DIR"/* "$VENV_DIR"/.[!.]* 2>/dev/null || true
        fi
        
        # Ensure proper ownership for Docker volume
        sudo chown -R "$(whoami):$(id -gn)" "$VENV_DIR" 2>/dev/null || true
        chmod 755 "$VENV_DIR" 2>/dev/null || true
        
        # Install required Python version
        log_info "Installing Python $REQUIRED_PYTHON..."
        uv python install "$REQUIRED_PYTHON"
        
        # Create virtual environment
        log_info "Creating virtual environment..."
        if ! uv venv --python "$REQUIRED_PYTHON" --relocatable "$VENV_DIR"; then
            log_warning "UV venv failed, falling back to standard venv..."
            local python_path
            python_path=$(uv python find "$REQUIRED_PYTHON" 2>/dev/null || echo "python$REQUIRED_PYTHON")
            if command -v "$python_path" &> /dev/null; then
                "$python_path" -m venv "$VENV_DIR"
            else
                log_warning "Using system python3..."
                python3 -m venv "$VENV_DIR"
            fi
        fi
    fi
    
    # Verify venv was created successfully
    if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
        log_error "Failed to create virtual environment"
        exit 1
    fi
    
    # Activate virtual environment
    # shellcheck source=/dev/null #? WTFIT?
    source "$VENV_DIR/bin/activate"
    log_success "Virtual environment ready: $(python --version)"
}

# Verify system tools are available
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

# Install backend dependencies
install_backend_deps() {
    log_info "Installing backend dependencies..."
    
    cd "$BACKEND_DIR"
    
    # Check if pyproject.toml exists
    if [[ ! -f "pyproject.toml" ]]; then
        log_error "pyproject.toml not found in $BACKEND_DIR"
        exit 1
    fi
    
    # Sync dependencies
    log_info "Syncing backend dependencies with uv..."
    uv sync --frozen --no-install-package uwsgi ${UV_SYNC_EXTRA_OPTS:-}
    
    # Install uwsgi separately with limited CPU (Docker constraint)
    log_info "Installing uwsgi with CPU limit..."
    CPUCOUNT=1 uv sync --frozen ${UV_SYNC_EXTRA_OPTS:-}
    
    log_success "Backend dependencies installed"
}

# Install woob dependencies
install_woob_deps() {
    log_info "Installing woob dependencies..."
    
    cd "$WOOB_DIR"
    
    # Install woob requirements
    if [[ -f ".ci/requirements.txt" ]]; then
        uv pip install -r .ci/requirements.txt
    else
        log_warning "Woob requirements.txt not found, skipping..."
    fi
    
    if [[ -f ".ci/requirements_modules.txt" ]]; then
        uv pip install -r .ci/requirements_modules.txt
    else
        log_warning "Woob modules requirements not found, skipping..."
    fi
    
    # Install specific versions for compatibility
    # TODO: complete this with missing ones
    uv pip install "requests==2.28.2" "Jinja2==3.0.0"
    
    # Install woob in development mode, replaces privately published "woob_powens" coming from backend dependencies.
    uv pip install -e .
    
    log_success "Woob dependencies installed"
}

# Create woob_modules symlink for compatibility
setup_woob_symlink() {
    log_info "Setting up woob_modules symlink..."
    
    local site_packages="$VENV_DIR/lib/python3.9/site-packages"
    
    if [[ -d "$site_packages/modules" && ! -L "$site_packages/woob_modules" ]]; then
        ln -s modules "$site_packages/woob_modules"
        log_success "woob_modules symlink created"
    else
        log_info "woob_modules symlink already exists or modules directory not found"
    fi
}

# Main installation function
main() {
    log_info "Starting dependency installation..."
    
    check_environment
    setup_log_directories
    setup_uv
    setup_venv
    verify_system_tools
    install_backend_deps
    install_woob_deps
    setup_woob_symlink
    
    log_success "All dependencies installed successfully!"
    log_info "Virtual environment activated. You can now run:"
    log_info "  - task dev:both    # Start both budgea servers"
    log_info "  - task setup:full  # Run complete setup"
    log_info "  - task --list      # See all available tasks"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi