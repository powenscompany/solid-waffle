#!/bin/bash
# TODO: need extra "uo pipefail"?
set -euo pipefail

echo "🐍 Installing Python dependencies..."

# Ensure go-task is available in the venv (pip package)
VENV_DIR="$HOME/dev/backend/.venv"
if [[ -x "$VENV_DIR/bin/python" ]]; then
  if ! "$VENV_DIR/bin/python" -c 'import shutil; import sys; sys.exit(0 if shutil.which("task") else 1)'; then
    echo "🧰 Installing go-task (pip) into venv..."
    "$VENV_DIR/bin/python" -m pip install -U go-task
  fi
else
  echo "⚠️  Virtualenv not found at $VENV_DIR; skipping go-task install"
fi

echo $UV_EXTRA_INDEX_URL
echo "📦 Installing backend dependencies..."
# uv pip install "pyyaml==6.0"
# echo "✅ Forced installed newer PyYAML (==6.0)."
# TODO: what is frozen?
uv sync --frozen --no-install-package uwsgi ${UV_SYNC_EXTRA_OPTS}
CPUCOUNT=1 uv sync --frozen ${UV_SYNC_EXTRA_OPTS}

# Create woob_modules symlink (for tests compatibility)
echo "🔗 Creating woob_modules symlink..."
# cd ~/dev/.venv/lib/python3.9/site-packages
# if [ -d "modules" ] && [ ! -L "woob_modules" ]; then
#     ln -s modules woob_modules
SITE_PACKAGES="$HOME/dev/backend/.venv/lib/python3.9/site-packages"
if [[ -d "$SITE_PACKAGES/modules" && ! -L "$SITE_PACKAGES/woob_modules" ]]; then
  ln -s modules "$SITE_PACKAGES/woob_modules"
fi

# TODO: leave backend uv sync do its thing once woob pyproject in place
# TODO: add playwright install command after installing the library
# TODO: to clean up
# Install woob dependencies
echo "📦 Installing woob dependencies..."
cd ~/dev/woob
uv pip install -r .ci/requirements.txt
uv pip install -r .ci/requirements_modules.txt
uv pip install "requests==2.28.2" "Jinja2==3.0.0"
uv pip install -e .

# Configure woob
# echo "🔧 Configuring woob..."
# mkdir -p /home/budgea/.config/woob
# echo "file://~/dev/woob/modules" > /home/budgea/.config/woob/sources.list

echo "✅ All dependencies installed successfully!"
# echo "💡 Run 'full_setup' to complete the environment setup."
