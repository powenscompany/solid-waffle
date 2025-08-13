#!/bin/bash
# Complete environment setup script for lean container
# Handles everything that used to be in the "fat" Dockerfile

set -euo pipefail

# Configuration
BACKEND_DIR="$HOME/dev/backend"
WOOB_DIR="$HOME/dev/woob"
VENV_DIR="$BACKEND_DIR/.venv"
REQUIRED_PYTHON="3.9.19"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Check if we're in the container
check_container_environment() {
    if [[ ! -d "$HOME/dev" ]]; then
        log_error "This script should be run inside the development container"
        exit 1
    fi
    
    if [[ ! -d "$BACKEND_DIR" || ! -d "$WOOB_DIR" ]]; then
        log_error "Backend or Woob directories not mounted. Check docker-compose.yml"
        exit 1
    fi
    
    # Check if .venv is properly mounted as a Docker volume
    log_info "Checking virtual environment mount status..."
    if mountpoint -q "$VENV_DIR" 2>/dev/null; then
        log_success "Virtual environment directory is properly mounted as Docker volume"
    else
        log_warning "Virtual environment directory is not a mount point"
        log_info "This might mean a host .venv is interfering with the Docker volume"
        log_info "Consider removing ../backend/.venv on your host machine"
    fi
}

# Setup environment variables and paths
setup_environment() {
    log_info "Setting up environment variables..."
    
    # Create environment setup script
    cat > "$HOME/.env_setup" << 'EOF'
# Development environment setup
export PATH="$PATH:$HOME/dev/backend/scripts:$HOME/.local/bin:$HOME/dev/scripts"
export PYTHONPATH="${PYTHONPATH:-}:$HOME/dev/backend:$HOME/dev/woob"
export BUDGEA_VENV_DIR="$HOME/dev/backend/.venv"

# UV configuration
export UV_COMPILE_BYTECODE=1
export UV_NO_SYNC=1
export UV_SYNC_EXTRA_OPTS="--no-install-package argparse"

# Application configuration
export PW_CONFIG_FILES=backend.conf
export PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers
EOF

    # Source it in bashrc if not already there
    if ! grep -q ".env_setup" "$HOME/.bashrc"; then
        echo "source $HOME/.env_setup" >> "$HOME/.bashrc"
    fi
    
    # Source it now
    source "$HOME/.env_setup"
    
    log_success "Environment variables configured"
}

# Install UV package manager
install_uv() {
    if command -v uv &> /dev/null; then
        log_info "UV already installed: $(uv --version)"
        return 0
    fi
    
    log_info "Installing UV package manager..."
    pip install "uv==0.5.1"
    log_success "UV installed: $(uv --version)"
}

# Setup Python virtual environment
setup_python_environment() {
    log_info "Setting up Python virtual environment..."
    
    # Install required Python version
    log_info "Installing Python $REQUIRED_PYTHON..."
    uv python install "$REQUIRED_PYTHON"
    
    # Check if venv already exists and is functional
    if [[ -f "$VENV_DIR/bin/activate" ]]; then
        log_info "Virtual environment already exists, checking if it's functional..."
        # Test activation in a subshell to avoid affecting current environment
        if (source "$VENV_DIR/bin/activate" && python --version | grep -q "$REQUIRED_PYTHON") 2>/dev/null; then
            log_success "Existing virtual environment is functional"
            source "$VENV_DIR/bin/activate"
            log_info "Activated: $(python --version)"
            return 0
        else
            log_warning "Existing virtual environment is not functional, recreating..."
        fi
    fi
    
    # Ensure the directory exists with proper ownership
    sudo mkdir -p "$VENV_DIR"
    sudo chown -R "$(whoami):$(whoami)" "$VENV_DIR"
    sudo chmod -R 755 "$VENV_DIR"
    
    # Clear the venv directory contents (preserve the mount point)
    log_info "Clearing virtual environment directory..."
    find "$VENV_DIR" -mindepth 1 -delete 2>/dev/null || {
        # Fallback if find fails
        rm -rf "$VENV_DIR"/* "$VENV_DIR"/.[!.]* 2>/dev/null || true
    }
    
    log_info "Creating fresh virtual environment..."
    uv venv --python "$REQUIRED_PYTHON" --relocatable "$VENV_DIR"
    
    # Verify and activate
    if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
        log_error "Failed to create virtual environment at $VENV_DIR"
        log_error "Check if the directory is properly mounted as a Docker volume"
        exit 1
    fi
    
    source "$VENV_DIR/bin/activate"
    
    # Ensure pip is available in the virtual environment
    if ! python -m pip --version &>/dev/null; then
        log_info "Installing pip in virtual environment..."
        uv pip install --upgrade pip
    fi
    
    log_success "Virtual environment created and activated: $(python --version)"
}

# # Install system tools into virtual environment
# install_development_tools() {
#     log_info "Installing development tools..."
    
#     # Install go-task using uv (package name is go-task-bin per official docs)
#     if ! python -c 'import shutil; import sys; sys.exit(0 if shutil.which("task") else 1)' 2>/dev/null; then
#         log_info "Installing go-task..."
#         uv pip install go-task-bin
#     fi
    
#     log_success "Development tools installed"
# }

# Install backend dependencies
install_backend_dependencies() {
    log_info "Installing backend dependencies..."
    
    cd "$BACKEND_DIR"
    
    if [[ ! -f "pyproject.toml" ]]; then
        log_error "pyproject.toml not found in $BACKEND_DIR"
        exit 1
    fi
    
    # Sync dependencies
    uv sync --frozen --no-install-package uwsgi ${UV_SYNC_EXTRA_OPTS:-}
    
    # Install uwsgi separately with CPU limit
    CPUCOUNT=1 uv sync --frozen ${UV_SYNC_EXTRA_OPTS:-}
    
    log_success "Backend dependencies installed"
}

# Install woob dependencies
install_woob_dependencies() {
    log_info "Installing woob dependencies..."
    
    cd "$WOOB_DIR"
    
    # Install woob requirements
    [[ -f ".ci/requirements.txt" ]] && uv pip install -r .ci/requirements.txt
    [[ -f ".ci/requirements_modules.txt" ]] && uv pip install -r .ci/requirements_modules.txt
    
    # Install specific versions
    uv pip install "requests==2.28.2" "Jinja2==3.0.0"
    
    # Install woob in development mode
    uv pip install -e .
    
    # Create compatibility symlink
    local site_packages="$VENV_DIR/lib/python3.9/site-packages"
    if [[ -d "$site_packages/modules" && ! -L "$site_packages/woob_modules" ]]; then
        ln -s modules "$site_packages/woob_modules"
    fi
    
    log_success "Woob dependencies installed"
}

# Setup SSH authorized keys for backend
setup_ssh_keys() {
    log_info "Setting up SSH authorized keys..."
    
    # Check if we have SSH keys available
    if [[ ! -f "$HOME/.ssh/id_rsa.pub" ]]; then
        log_warning "No SSH public key found at $HOME/.ssh/id_rsa.pub"
        log_info "SSH key setup skipped - backend SSH access may not work"
        return 0
    fi
    
    # Create /etc/bi directory if it doesn't exist
    sudo mkdir -p /etc/bi
    
    # Copy public key to authorized_keys if not already there
    if [[ ! -f "/etc/bi/authorized_keys" ]] || ! grep -q "$(cat "$HOME/.ssh/id_rsa.pub")" /etc/bi/authorized_keys 2>/dev/null; then
        log_info "Adding SSH public key to /etc/bi/authorized_keys..."
        cat "$HOME/.ssh/id_rsa.pub" | sudo tee -a /etc/bi/authorized_keys > /dev/null
        sudo chmod 600 /etc/bi/authorized_keys
        sudo chown root:root /etc/bi/authorized_keys
        log_success "SSH authorized keys configured"
    else
        log_info "SSH public key already present in authorized_keys"
    fi
}

# Setup bash functions and aliases
setup_bash_functions() {
    log_info "Setting up bash functions..."
    
    # Create functions file
    cat > "$HOME/.dev_functions" << 'EOF'
# Development environment functions

# Quick environment activation
devenv() {
    local venv_dir="$BUDGEA_VENV_DIR"
    if [[ -f "$venv_dir/bin/activate" ]]; then
        source "$venv_dir/bin/activate"
        echo "✅ Development environment activated"
    else
        echo "❌ Virtual environment not found. Run setup-environment.sh"
        return 1
    fi
}

# Aliases
alias gm="sudo service gearman-job-server start"
alias ll="ls -la"
alias la="ls -la"

# Database functions
setup_local_db() {
    python3 "$HOME/dev/backend/tools/setup_local_databases.py" -s --no-interactive --force-drop-databases
    export BUDGEA_TOKEN=$(sudo mysql -uroot -p1245487 -hmariadb -Dlocalhost_3158 -se "select token from bi_manage_token where scope='admin';")
}

create_budgea_db_user() {
    sudo mysql -uroot -p1245487 -hmariadb -e "CREATE USER IF NOT EXISTS 'budgea'@'%' IDENTIFIED BY '123456'; GRANT ALL PRIVILEGES ON *.* TO 'budgea'@'%' WITH GRANT OPTION;"
}

# Key management
create_keys() {
    python3 "$HOME/dev/backend/tools/gen_key.py"
    sudo mkdir -p /etc/bi
    sudo mv -f frontend.pkey /etc/bi/frontend.pkey
    sudo mv -f backend.key /etc/bi/backend.key
    sudo chmod 600 /etc/bi/frontend.pkey /etc/bi/backend.key
    sudo gpg --batch --yes --symmetric --cipher-algo AES256 --output /etc/bi/backend.key.gpg /etc/bi/backend.key
}

# Woob functions
update_woob() {
    python "$HOME/dev/woob/woob/woob_metadata/build_modules_metadata.py"
}

# Client creation
create_client() {
    budgea &
    local budgea_pid=$!
    budgea.wsgi &
    local wsgi_pid=$!
    sleep 10
    curl http://localhost:3158/clients -H "Authorization: Bearer $BUDGEA_TOKEN" -d ''
    export BUDGEA_CLIENT=$(sudo mysql -uroot -p1245487 -hmariadb -Dlocalhost_3158 -se "select id from bi_client;")
    sudo mysql -uroot -p1245487 -hmariadb -Dlocalhost_3158 -se "update bi_client set redirect_uris='[\"http://localhost:4200/\", \"https://example.org/user/settings\"]' where id=$BUDGEA_CLIENT;"
    budgeactl config localhost:3158 root.prefix ''
    kill $budgea_pid $wsgi_pid 2>/dev/null || true
}

# Full setup
full_setup() {
    cd "$HOME/dev/backend"
    devenv
    update_woob
    create_budgea_db_user
    [[ ! -f "/etc/bi/frontend.pkey" ]] && create_keys
    setup_local_db
    create_client
}
EOF

    # Source it in bashrc if not already there
    if ! grep -q ".dev_functions" "$HOME/.bashrc"; then
        echo "source $HOME/.dev_functions" >> "$HOME/.bashrc"
    fi
    
    source "$HOME/.dev_functions"
    log_success "Bash functions configured"
}

# Auto-activate environment on login
setup_auto_activation() {
    log_info "Setting up auto-activation..."
    
    cat >> "$HOME/.bashrc" << 'EOF'

# Auto-activate development environment
if [[ -f "$BUDGEA_VENV_DIR/bin/activate" ]] && [[ -z "$VIRTUAL_ENV" ]]; then
    devenv
fi

# Show available tasks if Taskfile exists
if command -v task &> /dev/null && [[ -f "$HOME/dev/Taskfile.yml" ]]; then
    echo "📋 Container tasks available - run 'task' to see commands"
fi
EOF

    log_success "Auto-activation configured"
}

# Main setup function
main() {
    log_info "Starting complete environment setup..."
    
    check_container_environment
    setup_environment
    install_uv
    setup_python_environment
    # install_development_tools
    install_backend_dependencies
    install_woob_dependencies
    setup_ssh_keys
    setup_bash_functions
    setup_auto_activation
    
    log_success "Environment setup complete!"
    log_info "🎉 Ready for development! Available commands:"
    log_info "  task dev:both     # Start both servers in tmux"
    log_info "  task setup:full   # Run application setup"
    log_info "  task --list       # See all available tasks"
    log_info "  devenv            # Activate environment manually"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi