#!/bin/bash

# 🧇 Solid Waffle - Powens Full Stack Environment Validation

set -e

echo "🧪 Testing Solid Waffle - Powens Full Stack Environment..."

# Check which profile is running
DEV_RUNNING=false
PROD_RUNNING=false

if docker-compose ps backend 2>/dev/null | grep -q "Up"; then
    DEV_RUNNING=true
fi

if docker-compose ps backend-production 2>/dev/null | grep -q "Up"; then
    PROD_RUNNING=true
fi

if [ "$DEV_RUNNING" = false ] && [ "$PROD_RUNNING" = false ]; then
    echo "❌ No backend containers are running"
    echo "   Start development: docker-compose up -d (or make up)"
    echo "   Start production: docker-compose --profile production up -d (or make up-production)"
    exit 1
fi

echo "📊 Environment Status:"
if [ "$DEV_RUNNING" = true ]; then
    echo "   ✅ Development environment running (fast, native architecture)"
fi
if [ "$PROD_RUNNING" = true ]; then
    echo "   ✅ Production environment running (exact production match)"
fi
echo ""

# Test function for both environments
test_backend() {
    local BACKEND_SERVICE=$1
    local ENV_NAME=$2
    
    echo "🔍 Testing $ENV_NAME environment..."
    
    # Test Python environment
    echo "1. Testing Python environment..."
    if docker-compose exec -T $BACKEND_SERVICE python --version > /dev/null 2>&1; then
        PYTHON_VERSION=$(docker-compose exec -T $BACKEND_SERVICE python --version)
        echo "   ✅ Python is available: $PYTHON_VERSION"
    else
        echo "   ❌ Python is not available in container"
        return 1
    fi
    
    # Test virtual environment
    echo "2. Testing virtual environment..."
    if docker-compose exec -T $BACKEND_SERVICE bash -c "source /home/budgea_user/dev/backend/.venv/bin/activate && python -c 'import sys; print(sys.prefix)'" | grep -q ".venv"; then
        echo "   ✅ Virtual environment is working"
    else
        echo "   ❌ Virtual environment is not properly configured"
        return 1
    fi
    
    # Test mounted volumes
    echo "3. Testing mounted volumes..."
    VOLUMES_OK=true
    
    if docker-compose exec -T $BACKEND_SERVICE test -d /home/budgea_user/dev/budgea; then
        echo "   ✅ Backend volume mounted"
    else
        echo "   ❌ Backend volume not mounted"
        VOLUMES_OK=false
    fi
    
    if docker-compose exec -T $BACKEND_SERVICE test -d /home/budgea_user/dev/woob; then
        echo "   ✅ Woob volume mounted"
    else
        echo "   ❌ Woob volume not mounted"
        VOLUMES_OK=false
    fi
    
    if docker-compose exec -T $BACKEND_SERVICE test -d /home/budgea_user/dev/apishell; then
        echo "   ✅ Apishell volume mounted"
    else
        echo "   ❌ Apishell volume not mounted"
        VOLUMES_OK=false
    fi
    
    if ! $VOLUMES_OK; then
        return 1
    fi
    
    # Test environment variables
    echo "4. Testing environment variables..."
    if docker-compose exec -T $BACKEND_SERVICE bash -c 'echo $PW_CONFIG_FILES' | grep -q "backend.conf"; then
        echo "   ✅ Environment variables loaded"
    else
        echo "   ❌ Environment variables not properly loaded"
        echo "   Check your .env file"
        return 1
    fi
    
    # Test SSL certificate
    echo "5. Testing SSL certificate..."
    if docker-compose exec -T $BACKEND_SERVICE test -f /home/budgea_user/dev/proxynet.pem; then
        echo "   ✅ ProxyNet certificate mounted"
    else
        echo "   ❌ ProxyNet certificate not found"
        echo "   Ensure proxynet.pem exists in parent directory"
        return 1
    fi
    
    # Test backend packages (optional)
    echo "6. Testing backend packages..."
    if docker-compose exec -T $BACKEND_SERVICE bash -c "source /home/budgea_user/dev/backend/.venv/bin/activate && python -c 'import budgea'" > /dev/null 2>&1; then
        echo "   ✅ Backend packages available"
    else
        echo "   ⚠️  Backend packages not installed (run 'full_setup' in container)"
    fi
    
    echo ""
}

# Test development environment if running
if [ "$DEV_RUNNING" = true ]; then
    test_backend "backend" "Development"
fi

# Test production environment if running
if [ "$PROD_RUNNING" = true ]; then
    test_backend "backend-production" "Production"
fi

# Test shared services
echo "🔍 Testing shared services..."

# Test database connectivity
echo "1. Testing database connectivity..."
if docker-compose exec -T mariadb mysql -uroot -p1245487 -e "SELECT 1;" > /dev/null 2>&1; then
    echo "   ✅ Database connection works"
else
    echo "   ❌ Database connection failed"
    echo "   Check if MariaDB container is running: docker-compose ps mariadb"
    exit 1
fi

# Test gearman service
echo "2. Testing gearman service..."
if docker-compose ps gearmand | grep -q "Up"; then
    echo "   ✅ Gearman service is running"
else
    echo "   ❌ Gearman service is not running"
    exit 1
fi

# Test webview service
echo "3. Testing webview service..."
WEBVIEW_RUNNING=false
WEBVIEW_PROD_RUNNING=false

if docker-compose ps webview 2>/dev/null | grep -q "Up"; then
    WEBVIEW_RUNNING=true
    echo "   ✅ Development webview is running (port 8080)"
fi

if docker-compose ps webview-production 2>/dev/null | grep -q "Up"; then
    WEBVIEW_PROD_RUNNING=true
    echo "   ✅ Production webview is running (port 8081)"
fi

if [ "$WEBVIEW_RUNNING" = false ] && [ "$WEBVIEW_PROD_RUNNING" = false ]; then
    echo "   ⚠️  No webview containers running (frontend won't be accessible)"
    echo "   Start with: docker-compose up -d webview"
fi

echo ""
echo "🎉 Environment validation complete!"
echo ""
echo "🌐 Access your services:"
if [ "$DEV_RUNNING" = true ]; then
    echo "   Development Backend API: http://localhost:3158"
    echo "   API Documentation: http://localhost:3158/docs"
fi
if [ "$WEBVIEW_RUNNING" = true ]; then
    echo "   Development Webview: http://localhost:8080"
fi
if [ "$PROD_RUNNING" = true ]; then
    echo "   Production Backend API: http://localhost:3159"
fi
if [ "$WEBVIEW_PROD_RUNNING" = true ]; then
    echo "   Production Webview: http://localhost:8081"
fi
echo ""
echo "🚀 Next steps:"
echo "1. Connect to container: make shell (or make shell-production)"
echo "2. Run full setup: full_setup"
echo "3. Start developing!"
echo ""
echo "📝 Useful commands:"
echo "   make help           # Show all available commands"
echo "   make status         # Check service status"
echo "   make logs           # View logs"
echo "   make full-setup     # Run full setup in container"
echo "   make up             # Start development environment"
echo "   make up-production  # Start production environment"
