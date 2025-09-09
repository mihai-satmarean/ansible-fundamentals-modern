# Module 2: Testing Ansible Connection to Remote Servers

## Objective
Test Ansible's connection to remote servers using both password and key-based authentication methods by running Ad-Hoc commands.

## Prerequisites
- Ansible installed on control node
- Access to one or more remote Linux servers
- SSH access to remote servers

## Lab Steps

### Step 1: Set up Key-Based Authentication

#### Generate SSH Key Pair
Generate an SSH key pair on your control node:

```bash
# Generate SSH key pair (press Enter for defaults)
ssh-keygen -t rsa -b 4096

# The simplest way - no arguments, follow prompts
ssh-keygen
```

#### Copy Public Key to Managed Hosts
Transfer your public key to the remote servers:

```bash
# Copy SSH key to remote host
ssh-copy-id username@remote-server-ip

# Example:
ssh-copy-id ubuntu@192.168.1.100
```

### Step 2: Test Connection with Key-Based Authentication

#### Create Basic Inventory File
Create a simple inventory file (`hosts.ini`):

```ini
[webservers]
server1 ansible_host=192.168.1.100 ansible_user=ubuntu
server2 ansible_host=192.168.1.101 ansible_user=ubuntu

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

#### Test with Ping Module
```bash
# Test connection to all hosts
ansible all -i hosts.ini -m ping

# Test connection to specific group
ansible webservers -i hosts.ini -m ping

# Test connection to specific host
ansible server1 -i hosts.ini -m ping
```

### Step 3: Set up Password Authentication

#### Configure SSH on Remote Hosts
On each remote host, ensure SSH allows password authentication:

```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Ensure this line is present and uncommented:
PasswordAuthentication yes

# Restart SSH service
sudo systemctl restart ssh
# OR
sudo service ssh restart
```

### Step 4: Test Connection with Password Authentication

```bash
# Test with password prompt
ansible all -i hosts.ini -m ping --ask-pass

# You'll be prompted to enter the SSH password
```

### Step 5: Run Additional Ad-Hoc Commands

#### Gather System Information
```bash
# Get system facts
ansible all -i hosts.ini -m setup

# Get specific fact
ansible all -i hosts.ini -m setup -a "filter=ansible_os_family"

# Check disk space
ansible all -i hosts.ini -m shell -a "df -h"

# Check memory usage
ansible all -i hosts.ini -m shell -a "free -m"

# Check running processes
ansible all -i hosts.ini -m shell -a "ps aux | head -10"
```

#### File Operations
```bash
# Create a directory
ansible all -i hosts.ini -m file -a "path=/tmp/ansible-test state=directory"

# Create a file with content
ansible all -i hosts.ini -m copy -a "content='Hello from Ansible' dest=/tmp/ansible-test/hello.txt"

# Check if file exists
ansible all -i hosts.ini -m stat -a "path=/tmp/ansible-test/hello.txt"
```

#### Service Management
```bash
# Check service status
ansible all -i hosts.ini -m service -a "name=ssh state=started"

# List all services
ansible all -i hosts.ini -m shell -a "systemctl list-units --type=service --state=running"
```

## Troubleshooting Common Issues

### SSH Key Issues
```bash
# Check SSH agent
ssh-add -l

# Add key to SSH agent if needed
ssh-add ~/.ssh/id_rsa

# Test manual SSH connection
ssh -i ~/.ssh/id_rsa username@remote-host
```

### Permission Issues
```bash
# Check SSH key permissions
ls -la ~/.ssh/
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### Connection Issues
```bash
# Test with verbose output
ansible all -i hosts.ini -m ping -vvv

# Test specific connection method
ansible all -i hosts.ini -m ping -c ssh
ansible all -i hosts.ini -m ping -c paramiko
```

## Expected Results

### Successful Key-Based Connection:
```
server1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

### Successful Password-Based Connection:
```
SSH password: [enter password]
server1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

## Key Learning Points

1. **Two Authentication Methods**: Key-based (more secure) and password-based
2. **Ad-Hoc Commands**: Quick way to run single tasks across multiple hosts
3. **Inventory Files**: Define and organize your managed hosts
4. **Module Usage**: Different modules for different tasks (ping, setup, shell, etc.)
5. **Connection Testing**: Always verify connectivity before running complex playbooks

## Security Best Practices

1. **Prefer SSH Keys**: More secure than passwords
2. **Use SSH Agent**: Manage keys efficiently
3. **Disable Root Login**: Use sudo for privilege escalation
4. **Strong Passwords**: If using password authentication
5. **Firewall Rules**: Restrict SSH access to necessary networks

## Next Steps

Now that you can connect to remote hosts, you're ready to:
- Set up more complex inventories
- Create static host inventories with groups
- Configure dedicated Ansible users
- Implement proper SSH key management
