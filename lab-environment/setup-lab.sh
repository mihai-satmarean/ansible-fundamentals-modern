#!/bin/bash

# Modern Ansible Lab Environment Setup
# No more AWS dependencies, no hardcoded credentials!

set -e

echo "Setting up Modern Ansible Lab Environment..."

# Function to fix Docker Compose issues on Ubuntu
fix_docker_compose() {
    echo "Checking Docker Compose installation..."
    
    # Check if we have the old docker-compose
    if command -v docker-compose &> /dev/null; then
        echo "Found docker-compose version:"
        if ! docker-compose --version &> /dev/null; then
            echo "Docker Compose appears to be broken, fixing..."
            
            # Install Docker Compose V2 (modern version)
            echo "Installing Docker Compose V2..."
            
            if command -v docker &> /dev/null; then
                echo "Docker is installed, installing Compose V2..."
                
                # Download and install Docker Compose V2
                sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
                
                # Create symlink for compatibility
                sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
                
                echo "Docker Compose V2 installed!"
                docker-compose --version
                
            else
                echo "Docker not found. Please install Docker first:"
                echo "   sudo apt update"
                echo "   sudo apt install docker.io"
                echo "   sudo usermod -aG docker \$USER"
                echo "   # Then logout and login again"
                exit 1
            fi
        else
            echo "Docker Compose is working properly"
        fi
    else
        echo "Docker Compose not found, installing..."
        if command -v docker &> /dev/null; then
            # Download and install Docker Compose V2
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
            echo "Docker Compose V2 installed!"
        else
            echo "Docker not found. Please install Docker first."
            exit 1
        fi
    fi
    
    echo ""
    echo "Note: You can also use the new syntax:"
    echo "   docker compose up -d    (instead of docker-compose up -d)"
    echo "   docker compose down     (instead of docker-compose down)"
    echo ""
}

# Fix Docker Compose if needed
fix_docker_compose

# Create necessary directories
mkdir -p ssh-keys playbooks inventory scenarios nginx-config

# Generate SSH keys for lab
if [ ! -f ssh-keys/id_rsa ]; then
    echo "Generating SSH keys for lab..."
    ssh-keygen -t rsa -N '' -f ssh-keys/id_rsa
    echo "SSH keys generated"
fi

# Create basic inventory
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

# Start the lab environment
echo "Starting Docker containers..."

# Try docker-compose first, fallback to docker compose
if command -v docker-compose &> /dev/null && docker-compose --version &> /dev/null; then
    docker-compose up -d
elif command -v docker &> /dev/null; then
    docker compose up -d
else
    echo "Neither docker-compose nor docker compose is available"
    exit 1
fi

echo "Waiting for services to be ready..."
sleep 30

echo "Testing lab environment..."
docker exec ansible-control ansible all -i /home/runner/inventory/hosts.yml -m ping || echo "Initial connectivity test failed - this is normal, containers may still be starting"

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
echo "   Stop lab: docker-compose down (or docker compose down)"
echo ""
echo "Ready for Module 1: Modern Ansible Introduction!"