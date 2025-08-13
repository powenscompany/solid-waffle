#!/bin/bash
# Validation script to test the new dependency management setup

set -euo pipefail

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

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

test_command() {
    local cmd="$1"
    local description="$2"
    
    if command -v "$cmd" &> /dev/null; then
        log_success "$description: $cmd available"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "$description: $cmd not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_file() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        log_success "$description: $file exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "$description: $file not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_directory() {
    local dir="$1"
    local description="$2"
    
    if [[ -d "$dir" ]]; then
        log_success "$description: $dir exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "$description: $dir not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_function() {
    local func="$1"
    local description="$2"
    
    if declare -f "$func" &> /dev/null; then
        log_success "$description: $func function available"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "$description: $func function not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

main() {
    log_info "Validating development environment setup..."
    
    # Source environment setup files if they exist
    [[ -f "$HOME/.env_setup" ]] && source "$HOME/.env_setup"
    [[ -f "$HOME/.dev_functions" ]] && source "$HOME/.dev_functions"
    
    echo
    
    # Test basic commands
    log_info "Testing basic commands..."
    test_command "python" "Python interpreter"
    test_command "uv" "UV package manager"
    test_command "task" "Task runner"
    test_command "tmux" "Tmux terminal multiplexer"
    echo
    
    # Test directories
    log_info "Testing directory structure..."
    test_directory "/home/budgea_user/dev/backend" "Backend directory"
    test_directory "/home/budgea_user/dev/woob" "Woob directory"
    test_directory "/home/budgea_user/dev/backend/.venv" "Virtual environment"
    test_directory "/var/log/bi" "Log directory"
    test_directory "/var/log/bi/data" "Log data directory"
    echo
    
    # Test files
    log_info "Testing important files..."
    test_file "/home/budgea_user/dev/Taskfile.yml" "Container Taskfile"
    test_file "/home/budgea_user/dev/scripts/setup-deps.sh" "Setup script"
    test_file "/home/budgea_user/dev/backend/pyproject.toml" "Backend pyproject.toml"
    echo
    
    # Test virtual environment
    log_info "Testing virtual environment..."
    if [[ -n "${VIRTUAL_ENV:-}" ]]; then
        log_success "Virtual environment activated: $VIRTUAL_ENV"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_warning "Virtual environment not activated"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Test UV command availability (UV is a standalone tool, not a Python package)
    if command -v uv &> /dev/null; then
        log_success "UV command available"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "UV command not available"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Test alembic specifically (the original failing command)
    if python -c "import alembic" 2>/dev/null; then
        log_success "Alembic package available in Python"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        
        # Test alembic command
        if command -v alembic &> /dev/null; then
            log_success "Alembic command available"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_error "Alembic command not found"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        log_error "Alembic package not available in Python"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo
    
    # Test log directory permissions
    log_info "Testing log directory permissions..."
    if [[ -d "/var/log/bi" ]]; then
        if touch /var/log/bi/test_write 2>/dev/null; then
            rm -f /var/log/bi/test_write
            log_success "Log directory is writable"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_error "Log directory is not writable"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        
        if touch /var/log/bi/data/test_write 2>/dev/null; then
            rm -f /var/log/bi/data/test_write
            log_success "Log data directory is writable"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_error "Log data directory is not writable"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
    echo
    
    # Test bash functions
    log_info "Testing bash functions..."
    test_function "devenv" "Development environment activation"
    test_function "full_setup" "Full setup function"
    test_function "setup_local_db" "Database setup function"
    echo
    
    # Test task availability
    log_info "Testing task commands..."
    if task --list &> /dev/null; then
        log_success "Task commands available"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        
        # Test specific tasks
        local important_tasks=("dev:both" "deps:install" "setup:full" "env:status")
        for task_name in "${important_tasks[@]}"; do
            if task --list | grep -q "$task_name"; then
                log_success "Task '$task_name' available"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                log_error "Task '$task_name' not found"
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
        done
    else
        log_error "Task commands not working"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo
    
    # Summary
    log_info "Validation Summary:"
    echo "  Tests passed: $TESTS_PASSED"
    echo "  Tests failed: $TESTS_FAILED"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed! Environment is ready for development."
        echo
        log_info "Try these commands:"
        echo "  task dev:both     # Start development servers"
        echo "  task setup:full   # Run complete setup"
        echo "  task --list       # See all available tasks"
        return 0
    else
        log_error "Some tests failed. Please check the setup."
        echo
        log_info "To fix issues, try:"
        echo "  ./scripts/setup-deps.sh   # Reinstall dependencies"
        echo "  devenv                    # Activate environment"
        echo "  task env:status           # Check environment status"
        return 1
    fi
}

# Run validation if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi