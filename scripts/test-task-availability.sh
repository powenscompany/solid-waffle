#!/bin/bash
# Test script to verify Task is available both inside and outside venv

set -euo pipefail

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

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

VENV_DIR="$HOME/dev/backend/.venv"

log_info "Testing Task availability..."

# Test 1: Task available without venv
log_info "Test 1: Task availability without virtual environment"
if command -v task &> /dev/null; then
    log_success "Task found in system PATH: $(which task)"
    log_success "Task version: $(task --version)"
else
    log_error "Task not found in system PATH"
    exit 1
fi

# Test 2: Task available with venv activated
if [[ -f "$VENV_DIR/bin/activate" ]]; then
    log_info "Test 2: Task availability with virtual environment activated"
    
    # shellcheck source=/dev/null
    source "$VENV_DIR/bin/activate"
    
    if command -v task &> /dev/null; then
        log_success "Task still available with venv: $(which task)"
        log_success "Task version: $(task --version)"
    else
        log_error "Task not found with venv activated"
        exit 1
    fi
    
    deactivate
else
    log_info "Test 2: Skipped (virtual environment not found)"
fi

# Test 3: Task can run from different directories
log_info "Test 3: Task execution from different directories"

cd /tmp
if task --version &> /dev/null; then
    log_success "Task works from /tmp"
else
    log_error "Task fails from /tmp"
    exit 1
fi

cd "$HOME"
if task --version &> /dev/null; then
    log_success "Task works from home directory"
else
    log_error "Task fails from home directory"
    exit 1
fi

log_success "All Task availability tests passed!"
log_info "Task is properly installed system-wide and works independently of virtual environment"