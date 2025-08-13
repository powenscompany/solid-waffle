#!/bin/bash

# 🧇 Solid Waffle - Powens Full Stack Development Environment Setup

set -e

echo "🧇 Setting up Solid Waffle - Powens Full Stack Environment..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  Creating .env file from template..."
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "📝 Please edit .env file with your actual environment variables"
        echo "🔑 You can find most values in your ~/.zshrc or ~/.bashrc file"
    else
        echo "❌ .env.example not found. Please create .env file manually."
        exit 1
    fi
fi

# Check if required directories exist
echo "📁 Checking required directories..."
REQUIRED_DIRS=(
    "../backend"
    "../woob" 
    "../apishell"
    "../proxynet.pem"
)

MISSING_DIRS=()
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -e "$dir" ]; then
        MISSING_DIRS+=("$dir")
    fi
done

if [ ${#MISSING_DIRS[@]} -ne 0 ]; then
    echo "❌ Missing required directories/files:"
    printf '%s\n' "${MISSING_DIRS[@]}"
    echo ""
    echo "Please ensure your directory structure matches:"
    echo "/Users/bob.sponge/dev/"
    echo "├── backend/                 # Backend source code (mounted for live changes)"
    echo "├── woob/                   # Woob source code (mounted for live changes)"
    echo "├── apishell/               # API shell utilities (mounted for live changes)"
    echo "├── proxynet.pem            # ProxyNet certificate"
    echo "└── solid-waffle/           # This project"
    echo ""
    echo "Note: webview uses pre-built Docker image (no local repo needed)"
    exit 1
fi

# Create required local directories
echo "📁 Creating local directories..."
mkdir -p etc_bi session_folders

# Check Docker login for ECR
echo "🔐 Checking Docker ECR access..."
if [ -f .env ]; then
    ECR_REGISTRY=$(grep "^ECR_REGISTRY=" .env | cut -d'=' -f2)
    if [ -n "$ECR_REGISTRY" ] && ! docker info | grep -q "$ECR_REGISTRY"; then
        echo "⚠️  You may need to login to ECR for webview image:"
        echo "   aws sso login --profile artifacts"
        echo "   aws ecr get-login-password --profile artifacts --region eu-west-3 | docker login --username AWS --password-stdin $ECR_REGISTRY"
    fi
fi

# Build the Docker image
echo "🔨 Building Docker images..."
docker-compose build

echo "✅ Setup complete! You can now run:"
echo ""
echo "🚀 Start the full stack (development - fast on all platforms):"
echo "   docker-compose up -d"
echo "   # or: make up"
echo ""
echo "🔗 Connect to the container:"
echo "   docker-compose exec backend bash"
echo "   # or: make shell"
echo ""
echo "🏗️  Inside the container, run full setup:"
echo "   full_setup"
echo ""
echo "🌐 Services will be available at:"
echo "   Webview (Frontend): http://localhost:8080"
echo "   Backend API: http://localhost:3158"
echo "   API Documentation: http://localhost:3158/docs"
echo ""
echo "📝 Useful commands:"
echo "   make help           # Show all available commands"
echo "   make status         # Check service status"
echo "   make logs           # View logs"
echo "   make shell          # Connect to container"
echo "   make full-setup     # Run full setup in container"
