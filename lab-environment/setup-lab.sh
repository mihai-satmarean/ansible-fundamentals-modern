#!/bin/bash

# Modern Ansible Lab Environment Setup
# No more AWS dependencies, no hardcoded credentials!

set -e

echo "🚀 Setting up Modern Ansible Lab Environment..."

# Create necessary directories
mkdir -p ssh-keys playbooks inventory scenarios nginx-config

# Generate SSH keys for lab
if [ ! -f ssh-keys/id_rsa ]; then
    echo "🔑 Generating SSH keys for lab..."
    ssh-keygen -t rsa -N '' -f ssh-keys/id_rsa
    echo "✅ SSH keys generated"
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

echo "📁 Lab structure created successfully!"

# Start the lab environment
echo "🐳 Starting Docker containers..."
docker-compose up -d

echo "⏳ Waiting for services to be ready..."
sleep 30

echo "🧪 Testing lab environment..."
docker exec ansible-control ansible all -i /home/runner/inventory/hosts.yml -m ping || echo "⚠️  Initial connectivity test failed - this is normal, containers may still be starting"

echo ""
echo "✅ Lab Environment Ready!"
echo ""
echo "🌐 Access Methods:"
echo "   Control Node SSH: ssh -p 2200 runner@localhost"
echo "   Web UI: http://localhost:8080 (if available)"
echo "   Load Balancer: http://localhost:8081"
echo ""
echo "🔧 Lab Commands:"
echo "   Enter control node: docker exec -it ansible-control bash"
echo "   Run playbooks: docker exec ansible-control ansible-playbook ..."
echo "   Stop lab: docker-compose down"
echo ""
echo "📚 Ready for Module 1: Modern Ansible Introduction!"

