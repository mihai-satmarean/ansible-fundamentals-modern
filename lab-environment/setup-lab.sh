#!/bin/bash

# Modern Ansible Lab Environment Setup
# Automated Docker and Docker Compose installation

set -e

echo "Setting up Modern Ansible Lab Environment..."

# Function to install Docker
install_docker() {
    echo "Installing Docker..."
    
    # Detect OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        echo "Cannot detect OS. Please install Docker manually."
        exit 1
    fi
    
    case $OS in
        ubuntu|debian)
            echo "Installing Docker on Ubuntu/Debian..."
            
            # Update package index
            sudo apt-get update
            
            # Install prerequisites
            sudo apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # Add Docker's official GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # Set up repository
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Update package index again
            sudo apt-get update
            
            # Install Docker Engine
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            
            # Add current user to docker group
            sudo usermod -aG docker $USER
            
            echo "Docker installed successfully!"
            echo "Note: You may need to logout and login again for group changes to take effect."
            ;;
            
        centos|rhel|fedora)
            echo "Installing Docker on CentOS/RHEL/Fedora..."
            
            # Install prerequisites
            sudo yum install -y yum-utils
            
            # Add Docker repository
            sudo yum-config-manager \
                --add-repo \
                https://download.docker.com/linux/centos/docker-ce.repo
            
            # Install Docker Engine
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            
            # Start and enable Docker
            sudo systemctl start docker
            sudo systemctl enable docker
            
            # Add current user to docker group
            sudo usermod -aG docker $USER
            
            echo "Docker installed successfully!"
            ;;
            
        *)
            echo "Unsupported OS: $OS"
            echo "Please install Docker manually from https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
}

# Function to install Docker Compose (standalone)
install_docker_compose() {
    echo "Installing Docker Compose..."
    
    # Download and install Docker Compose V2
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # Make it executable
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for compatibility
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    echo "Docker Compose ${COMPOSE_VERSION} installed successfully!"
}

# Function to check and setup Docker environment
setup_docker_environment() {
    echo "Checking Docker installation..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Docker not found. Installing Docker..."
        install_docker
        
        # Start Docker service if not running
        if ! sudo systemctl is-active --quiet docker; then
            echo "Starting Docker service..."
            sudo systemctl start docker
            sudo systemctl enable docker
        fi
        
        # Test Docker installation
        echo "Testing Docker installation..."
        if sudo docker run --rm hello-world &> /dev/null; then
            echo "Docker is working correctly!"
        else
            echo "Docker installation may have issues. Continuing anyway..."
        fi
    else
        echo "Docker is already installed."
        docker --version
        
        # Ensure Docker service is running
        if ! sudo systemctl is-active --quiet docker; then
            echo "Starting Docker service..."
            sudo systemctl start docker
        fi
    fi
    
    # Check if current user is in docker group
    if ! groups $USER | grep &> /dev/null '\bdocker\b'; then
        echo "Adding current user to docker group..."
        sudo usermod -aG docker $USER
        echo "Note: You may need to logout and login again, or run 'newgrp docker'"
    fi
    
    # Check Docker Compose
    echo "Checking Docker Compose installation..."
    
    if command -v docker-compose &> /dev/null; then
        echo "Found docker-compose:"
        if docker-compose --version &> /dev/null; then
            echo "Docker Compose is working properly"
            docker-compose --version
        else
            echo "Docker Compose appears to be broken, reinstalling..."
            install_docker_compose
        fi
    elif docker compose version &> /dev/null 2>&1; then
        echo "Found Docker Compose plugin:"
        docker compose version
    else
        echo "Docker Compose not found, installing..."
        install_docker_compose
    fi
    
    echo ""
    echo "Docker environment setup complete!"
    echo "Available commands:"
    echo "  - docker compose up -d    (recommended)"
    echo "  - docker-compose up -d    (fallback)"
    echo ""
}

# Setup Docker environment
setup_docker_environment

# Create necessary directories
echo "Creating lab directory structure..."
mkdir -p ssh-keys playbooks inventory scenarios nginx-config

# Generate SSH keys for lab
if [ ! -f ssh-keys/id_rsa ]; then
    echo "Generating SSH keys for lab..."
    ssh-keygen -t rsa -N '' -f ssh-keys/id_rsa
    echo "SSH keys generated"
fi

# Create basic inventory
echo "Creating Ansible inventory..."
cat > inventory/hosts.yml << 'EOF'
---
all:
  children:
    webservers:
      hosts:
        web1.ansible.lab:
          ansible_host: web1
          ansible_user: root
        web2.ansible.lab:
          ansible_host: web2
          ansible_user: root
    databases:
      hosts:
        db1.ansible.lab:
          ansible_host: db1
          ansible_user: root
    loadbalancers:
      hosts:
        lb1.ansible.lab:
          ansible_host: lb1
          ansible_user: root
  vars:
    ansible_python_interpreter: /usr/bin/python3
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF

# Create nginx config for load balancer
echo "Creating nginx configuration..."
cat > nginx-config/default.conf << 'EOF'
upstream webservers {
    server web1:80;
    server web2:80;
}

server {
    listen 80;
    server_name localhost;
    
    location / {
        proxy_pass http://webservers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Create sample playbook
echo "Creating test playbook..."
cat > playbooks/test-connection.yml << 'EOF'
---
- name: Test lab environment connectivity
  hosts: all
  gather_facts: false
  tasks:
    - name: Ping all hosts
      ansible.builtin.ping:
      
    - name: Check Python availability
      ansible.builtin.command: python3 --version
      register: python_version
      
    - name: Display Python version
      ansible.builtin.debug:
        msg: "Python version on {{ inventory_hostname }}: {{ python_version.stdout }}"
EOF

echo "Lab structure created successfully!"

# Check if docker-compose.yml exists
if [ ! -f docker-compose.yml ]; then
    echo "Warning: docker-compose.yml not found in current directory."
    echo "Please ensure you have the Docker Compose configuration file."
    echo "Lab setup completed, but containers cannot be started without docker-compose.yml"
    exit 0
fi

# Start the lab environment
echo "Starting Docker containers..."

# Try different Docker Compose commands
if command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
    echo "Using Docker Compose plugin..."
    docker compose up -d
elif command -v docker-compose &> /dev/null && docker-compose --version &> /dev/null; then
    echo "Using standalone Docker Compose..."
    docker-compose up -d
else
    echo "Docker Compose not available. Please run one of:"
    echo "  docker compose up -d"
    echo "  docker-compose up -d"
    exit 1
fi

echo "Waiting for services to be ready..."
sleep 30

echo "Testing lab environment..."
if docker ps | grep -q ansible-control; then
    docker exec ansible-control ansible all -i /home/runner/inventory/hosts.yml -m ping || echo "Initial connectivity test failed - this is normal, containers may still be starting"
else
    echo "ansible-control container not found. Please check docker-compose.yml configuration."
fi

echo ""
echo "Lab Environment Ready!"
echo ""
echo "Access Methods:"
echo "   Control Node SSH: ssh -p 2200 runner@localhost"
echo "   Web UI: http://localhost:8080 (if available)"
echo "   Load Balancer: http://localhost:8081"
echo ""
echo "Lab Commands:"
echo "   Enter control node: docker exec -it ansible-control bash"
echo "   Run playbooks: docker exec ansible-control ansible-playbook ..."
echo "   Stop lab: docker compose down (or docker-compose down)"
echo ""
echo "Ready for Module 1: Modern Ansible Introduction!"

# Check if user needs to logout/login for docker group
if ! docker ps &> /dev/null; then
    echo ""
    echo "Note: If you get permission errors, you may need to:"
    echo "1. Run 'newgrp docker' to refresh group membership"
    echo "2. Or logout and login again"
    echo "3. Or run commands with 'sudo' prefix"
fi