#!/bin/bash

# Check ECR authentication status
# This script verifies if Docker is authenticated with AWS ECR

set -e

ECR_REGISTRY="737968113546.dkr.ecr.eu-west-3.amazonaws.com"
PROFILE="artifacts"
REGION="eu-west-3"

echo "🔍 Checking ECR authentication status..."

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first."
    echo ""
    echo "🔧 Installation instructions:"
    echo "   https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    echo ""
    exit 1
fi

# Check if AWS SSO session is active
echo "📋 Checking AWS SSO session..."
if ! aws sts get-caller-identity --profile "$PROFILE" &> /dev/null; then
    echo "❌ AWS SSO session expired or not logged in."
    echo ""
    echo "🔧 To fix this, run:"
    echo "   task ecr-login"
    echo ""
    echo "   Or manually:"
    echo "   aws sso login --profile $PROFILE"
    echo "   aws ecr get-login-password --profile $PROFILE --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY"
    echo ""
    exit 1
fi

# Check if Docker is authenticated with ECR
echo "🐳 Checking Docker ECR authentication..."

# Try to test authentication by checking if we can access the registry
if docker manifest inspect "$ECR_REGISTRY/docker/webview:${WEBVIEW_RELEASE_TAG:-latest}" &> /dev/null; then
    echo "✅ Docker is authenticated with ECR and can access webview image"
else
    echo "🔐 Docker not authenticated or authentication expired. Attempting to authenticate..."
    if aws ecr get-login-password --profile "$PROFILE" --region "$REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"; then
        echo "✅ Successfully authenticated with ECR"
        
        # Test again after authentication
        echo "🖼️  Testing webview image access..."
        WEBVIEW_TAG="${WEBVIEW_RELEASE_TAG:-latest}"
        if docker manifest inspect "$ECR_REGISTRY/docker/webview:$WEBVIEW_TAG" &> /dev/null; then
            echo "✅ Webview image is accessible"
        else
            echo "❌ Cannot access webview image even after authentication"
            echo ""
            echo "🔧 This might be due to:"
            echo "   - Image tag '$WEBVIEW_TAG' doesn't exist"
            echo "   - Network connectivity issues"
            echo "   - Insufficient permissions"
            echo ""
            exit 1
        fi
    else
        echo "❌ Failed to authenticate with ECR"
        echo ""
        echo "🔧 To fix this, run:"
        echo "   task ecr-login"
        echo ""
        echo "   Or check if your AWS configuration is correct:"
        echo "   aws configure list --profile $PROFILE"
        echo ""
        exit 1
    fi
fi

echo ""
echo "🎉 All ECR authentication checks passed!"
echo "💡 You can now run 'task up' to start the services."