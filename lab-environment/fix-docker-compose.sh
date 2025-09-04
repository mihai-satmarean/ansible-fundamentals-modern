#!/bin/bash

# Fix for Ubuntu docker-compose distutils issue
# This script installs the modern Docker Compose V2

echo "🔧 Fixing Docker Compose issue on Ubuntu..."

# Check if we have the old docker-compose
if command -v docker-compose &> /dev/null; then
    echo "📦 Found old docker-compose version:"
    docker-compose --version || echo "❌ docker-compose is broken"
fi

# Install Docker Compose V2 (modern version)
echo "🚀 Installing Docker Compose V2..."

# Method 1: Install via Docker's official repository (recommended)
if command -v docker &> /dev/null; then
    echo "✅ Docker is installed, installing Compose V2..."
    
    # Download and install Docker Compose V2
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for compatibility
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    echo "✅ Docker Compose V2 installed!"
    docker-compose --version
    
else
    echo "❌ Docker not found. Please install Docker first:"
    echo "   sudo apt update"
    echo "   sudo apt install docker.io"
    echo "   sudo usermod -aG docker \$USER"
    echo "   # Then logout and login again"
    exit 1
fi

# Alternative: Use 'docker compose' (V2 integrated command)
echo ""
echo "💡 You can also use the new syntax:"
echo "   docker compose up -d    (instead of docker-compose up -d)"
echo "   docker compose down     (instead of docker-compose down)"
echo ""

# Test the installation
echo "🧪 Testing Docker Compose..."
if docker-compose --version; then
    echo "✅ Docker Compose is working!"
    echo "🚀 Ready to run the lab setup again!"
else
    echo "❌ Still having issues. Try the alternative method below."
    echo ""
    echo "🔄 Alternative: Use Docker Compose V2 integrated command:"
    echo "   Instead of: docker-compose up -d"
    echo "   Use: docker compose up -d"
fi
