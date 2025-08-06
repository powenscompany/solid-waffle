#!/bin/bash
set -e

echo "🐍 Installing Python dependencies..."

# TODO put repoforge URL in env
# Configure uv for private repositories if token is available
if [ -n "$REPOFORGE_API_TOKEN" ]; then
    echo "🔑 Configuring private repository access..."
    export UV_EXTRA_INDEX_URL="https://api:${REPOFORGE_API_TOKEN}@api.repoforge.io/OJDhXySqK"
    echo $UV_EXTRA_INDEX_URL
else
    echo "⚠️  REPOFORGE_API_TOKEN not set - private dependencies may fail"
fi

echo $UV_EXTRA_INDEX_URL
echo "📦 Installing backend dependencies..."
# TODO: what is frozen?
uv sync --frozen --no-install-package uwsgi ${UV_SYNC_EXTRA_OPTS}
CPUCOUNT=1 uv sync --frozen ${UV_SYNC_EXTRA_OPTS}

# Create woob_modules symlink (for tests compatibility)
echo "🔗 Creating woob_modules symlink..."
cd ~/dev/.venv/lib/python3.9/site-packages
if [ -d "modules" ] && [ ! -L "woob_modules" ]; then
    ln -s modules woob_modules
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
echo "🔧 Configuring woob..."
mkdir -p /home/budgea/.config/woob
echo "file://~/dev/woob/modules" > /home/budgea/.config/woob/sources.list

echo "✅ All dependencies installed successfully!"
echo "💡 Run 'full_setup' to complete the environment setup."
