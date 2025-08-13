#!/bin/bash
# Migration status checker - shows which approach is being used

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

echo "🔍 Container Migration Status Check"
echo "=================================="
echo

# Check Dockerfile type
log_info "Checking Dockerfile approach..."
if grep -q "python3-flask\|python3-requests" Dockerfile 2>/dev/null; then
    log_warning "Using FAT container approach (old)"
    echo "  - Dockerfile installs Python packages at build time"
    echo "  - May have package manager conflicts"
    echo "  - Consider migrating to lean approach"
    DOCKERFILE_TYPE="fat"
elif grep -q "Lean Dockerfile following container best practices" Dockerfile 2>/dev/null; then
    log_success "Using LEAN container approach (new)"
    echo "  - Dockerfile only installs system dependencies"
    echo "  - Python packages handled at runtime"
    echo "  - Follows container best practices"
    DOCKERFILE_TYPE="lean"
else
    log_warning "Unknown Dockerfile type"
    DOCKERFILE_TYPE="unknown"
fi
echo

# Check available setup scripts
log_info "Checking available setup methods..."

if [[ -f "scripts/setup-environment.sh" ]]; then
    log_success "New setup script available: scripts/setup-environment.sh"
    echo "  - Complete environment setup"
    echo "  - Better error handling"
    echo "  - Follows lean container approach"
else
    log_error "New setup script missing: scripts/setup-environment.sh"
fi

if [[ -f "install_deps.sh" ]]; then
    log_info "Legacy setup script available: install_deps.sh"
    echo "  - Original dependency installer"
    echo "  - Still functional for backward compatibility"
else
    log_warning "Legacy setup script missing: install_deps.sh"
fi

if [[ -f "additional_bashrc" ]]; then
    log_info "Legacy bashrc available: additional_bashrc"
else
    log_warning "Legacy bashrc missing: additional_bashrc"
fi

if [[ -f "container-bashrc" ]]; then
    log_success "New bashrc available: container-bashrc"
    echo "  - Cleaner, more maintainable"
    echo "  - Focused on essential functions"
else
    log_error "New bashrc missing: container-bashrc"
fi
echo

# Check Taskfile setup
log_info "Checking task configuration..."

if [[ -f "container-Taskfile.yml" ]]; then
    if grep -q "setup:environment" container-Taskfile.yml; then
        log_success "Container Taskfile has new setup tasks"
    else
        log_warning "Container Taskfile missing new setup tasks"
    fi
else
    log_error "Container Taskfile missing: container-Taskfile.yml"
fi

if [[ -f "Taskfile.yml" ]]; then
    if grep -q "setup:environment" Taskfile.yml; then
        log_success "Main Taskfile has new setup tasks"
    else
        log_warning "Main Taskfile missing new setup tasks"
    fi
else
    log_error "Main Taskfile missing: Taskfile.yml"
fi
echo

# Overall status
log_info "Migration Status Summary:"
echo

if [[ "$DOCKERFILE_TYPE" == "lean" ]]; then
    log_success "✅ MIGRATION COMPLETE - Using lean container approach"
    echo
    echo "🎉 You're now using container best practices!"
    echo
    echo "Next steps:"
    echo "  1. Rebuild container: task build"
    echo "  2. Start services: task up"
    echo "  3. Run setup: task full-setup"
    echo "  4. Test environment: task validate:setup"
    echo
    echo "New commands available:"
    echo "  task setup:environment    # Complete environment setup"
    echo "  task container:task -- dev:both  # Start development servers"
    
elif [[ "$DOCKERFILE_TYPE" == "fat" ]]; then
    log_warning "⚠️  MIGRATION INCOMPLETE - Still using fat container"
    echo
    echo "You have the new scripts but are still using the old Dockerfile."
    echo
    echo "To complete migration:"
    echo "  1. Your current Dockerfile is backed up as Dockerfile.backup"
    echo "  2. Replace with lean version: cp Dockerfile.lean Dockerfile"
    echo "  3. Rebuild: task build"
    echo "  4. Test: task up && task full-setup"
    
else
    log_error "❌ MIGRATION STATUS UNCLEAR"
    echo
    echo "Please check your Dockerfile and ensure migration files are present."
fi

echo
echo "📚 Documentation:"
echo "  - CONTAINER_MIGRATION_GUIDE.md - Complete migration guide"
echo "  - CONTAINER_BEST_PRACTICES.md - Container best practices"
echo "  - DEPENDENCY_MIGRATION.md - Dependency management guide"