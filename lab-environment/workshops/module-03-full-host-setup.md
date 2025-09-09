# Module 3: Performing Full Setup of Hosts for Ansible Management

## Objective
Perform a complete setup of hosts including creating a dedicated user, implementing key-based authentication, configuring sudo permissions, setting up static inventory, and testing the configuration.

## Prerequisites
- Ansible installed on control node
- Root or sudo access on managed hosts
- Network connectivity between control and managed nodes

## Lab Steps

### Step 1: Create a Dedicated Ansible User

#### On the Control Node
Create a dedicated user for Ansible operations:

```bash
# Create the ansible user
sudo useradd -m -s /bin/bash ansibleuser

# Set password for the user (if required)
sudo passwd ansibleuser

# Switch to the ansible user
sudo -i -u ansibleuser
```

#### Add to Sudoers (Optional for Control Node)
If you want the Ansible user to have sudo privileges on the control node:

```bash
# Edit sudoers file
sudo visudo

# Add this line:
ansibleuser ALL=(ALL) NOPASSWD:ALL
```

### Step 2: Configure Key-Based Authentication

#### Generate SSH Key Pair
As the `ansibleuser`, generate SSH keys:

```bash
# Switch to ansible user
sudo -i -u ansibleuser

# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "ansibleuser@yourdomain.com"

# Press Enter for default location and empty passphrase
# Keys will be saved in /home/ansibleuser/.ssh/
```

#### Copy SSH Keys to Managed Hosts
Distribute the public key to all managed hosts:

```bash
# Copy key to each managed host
ssh-copy-id ansibleuser@192.168.1.100
ssh-copy-id ansibleuser@192.168.1.101
ssh-copy-id ansibleuser@192.168.1.102

# Test SSH connection (should work without password)
ssh ansibleuser@192.168.1.100
```

### Step 3: Create Ansible User on Managed Hosts

#### Create User and Configure Sudo on Each Managed Host

Run this on each managed host or use an initial playbook:

```bash
# Create ansible user on managed host
sudo useradd -m -s /bin/bash ansibleuser

# Set password (temporary, will use keys)
sudo passwd ansibleuser

# Add to sudoers with NOPASSWD
sudo visudo

# Add this line:
ansibleuser ALL=(ALL) NOPASSWD:ALL
```

#### Alternative: Use Initial Playbook
Create `setup-users.yml` to automate user creation:

```yaml
---
- name: Setup Ansible User on Managed Hosts
  hosts: all
  become: yes
  vars:
    ansible_user_name: ansibleuser
    
  tasks:
    - name: Create ansible user
      user:
        name: "{{ ansible_user_name }}"
        state: present
        create_home: yes
        shell: /bin/bash
        
    - name: Add ansible user to sudoers
      lineinfile:
        path: /etc/sudoers
        line: "{{ ansible_user_name }} ALL=(ALL) NOPASSWD:ALL"
        validate: 'visudo -cf %s'
        
    - name: Create .ssh directory
      file:
        path: "/home/{{ ansible_user_name }}/.ssh"
        state: directory
        owner: "{{ ansible_user_name }}"
        group: "{{ ansible_user_name }}"
        mode: '0700'
        
    - name: Set authorized key
      authorized_key:
        user: "{{ ansible_user_name }}"
        state: present
        key: "{{ lookup('file', '/home/ansibleuser/.ssh/id_rsa.pub') }}"
```

Run the playbook:
```bash
# Run as root initially to create the user
ansible-playbook -i initial-hosts.ini setup-users.yml -u root --ask-pass
```

### Step 4: Set Up Static Host Inventory

#### Create Comprehensive Inventory File

Create `hosts.ini` with groups and variables:

```ini
# Web servers
[webservers]
web1 ansible_host=192.168.1.100
web2 ansible_host=192.168.1.101

# Database servers  
[databases]
db1 ansible_host=192.168.1.102

# Load balancers
[loadbalancers]
lb1 ansible_host=192.168.1.103

# Group of groups
[production:children]
webservers
databases
loadbalancers

# Variables for all hosts
[all:vars]
ansible_user=ansibleuser
ansible_ssh_private_key_file=/home/ansibleuser/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

# Variables for web servers
[webservers:vars]
http_port=80
https_port=443

# Variables for databases
[databases:vars]
mysql_port=3306
```

#### Alternative YAML Inventory Format

Create `hosts.yml`:

```yaml
all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 192.168.1.100
        web2:
          ansible_host: 192.168.1.101
      vars:
        http_port: 80
        https_port: 443
        
    databases:
      hosts:
        db1:
          ansible_host: 192.168.1.102
      vars:
        mysql_port: 3306
        
    loadbalancers:
      hosts:
        lb1:
          ansible_host: 192.168.1.103
          
    production:
      children:
        webservers:
        databases:
        loadbalancers:
        
  vars:
    ansible_user: ansibleuser
    ansible_ssh_private_key_file: /home/ansibleuser/.ssh/id_rsa
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
```

### Step 5: Set Default Inventory

#### Configure Ansible to Use Your Inventory

Create or modify `ansible.cfg`:

```ini
[defaults]
inventory = ./hosts.ini
remote_user = ansibleuser
host_key_checking = False
roles_path = ./roles
timeout = 30

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

### Step 6: Test Ansible Commands

#### Basic Connectivity Tests

```bash
# Test ping to all hosts
ansible all -m ping

# Test ping to specific groups
ansible webservers -m ping
ansible databases -m ping

# Test with specific inventory file
ansible all -i hosts.ini -m ping
```

#### System Information Gathering

```bash
# Gather all facts
ansible all -m setup

# Get specific facts
ansible all -m setup -a "filter=ansible_os_family"
ansible all -m setup -a "filter=ansible_distribution*"

# Check disk space
ansible all -m shell -a "df -h"

# Check memory
ansible all -m shell -a "free -m"

# Check network interfaces
ansible all -m setup -a "filter=ansible_interfaces"
```

#### Privilege Escalation Tests

```bash
# Test sudo access
ansible all -m shell -a "whoami" --become

# Install a package (requires sudo)
ansible webservers -m package -a "name=htop state=present" --become

# Check sudo configuration
ansible all -m shell -a "sudo -l" --become
```

#### File and Directory Operations

```bash
# Create directory
ansible all -m file -a "path=/tmp/ansible-test state=directory"

# Create file with content
ansible all -m copy -a "content='Ansible managed' dest=/tmp/ansible-test/managed.txt"

# Check file permissions
ansible all -m stat -a "path=/tmp/ansible-test/managed.txt"

# Change file ownership
ansible all -m file -a "path=/tmp/ansible-test/managed.txt owner=ansibleuser group=ansibleuser" --become
```

### Step 7: Advanced Inventory Testing

#### Test Group Operations

```bash
# Operations on specific groups
ansible webservers -m shell -a "echo 'Web server: $(hostname)'"
ansible databases -m shell -a "echo 'Database server: $(hostname)'"

# Use group variables
ansible webservers -m debug -a "var=http_port"
ansible databases -m debug -a "var=mysql_port"
```

#### Test Host Patterns

```bash
# Single host
ansible web1 -m ping

# Multiple hosts
ansible web1,db1 -m ping

# All hosts in multiple groups
ansible webservers,databases -m ping

# All except specific hosts
ansible all:!lb1 -m ping

# Intersection of groups
ansible webservers:&production -m ping
```

## Verification Checklist

### ✅ User Setup Complete
- [ ] `ansibleuser` exists on control node
- [ ] `ansibleuser` exists on all managed hosts
- [ ] SSH keys generated on control node
- [ ] Public keys copied to all managed hosts
- [ ] Passwordless SSH working from control to managed hosts

### ✅ Sudo Configuration Complete
- [ ] `ansibleuser` has NOPASSWD sudo on managed hosts
- [ ] Privilege escalation works with `--become`
- [ ] Can install packages and modify system files

### ✅ Inventory Configuration Complete
- [ ] Static inventory file created with proper groups
- [ ] Host variables and group variables defined
- [ ] `ansible.cfg` configured with default inventory
- [ ] All hosts respond to `ansible all -m ping`

### ✅ Testing Complete
- [ ] Basic connectivity confirmed
- [ ] Fact gathering works
- [ ] Ad-hoc commands execute successfully
- [ ] Group operations work correctly
- [ ] Privilege escalation functions properly

## Troubleshooting Common Issues

### SSH Key Issues
```bash
# Check SSH key permissions
ls -la /home/ansibleuser/.ssh/
chmod 600 /home/ansibleuser/.ssh/id_rsa
chmod 644 /home/ansibleuser/.ssh/id_rsa.pub
chmod 700 /home/ansibleuser/.ssh/

# Test manual SSH
ssh -i /home/ansibleuser/.ssh/id_rsa ansibleuser@target-host
```

### Sudo Issues
```bash
# Test sudo manually
ssh ansibleuser@target-host "sudo whoami"

# Check sudoers syntax
sudo visudo -c

# Verify user in sudoers
sudo grep ansibleuser /etc/sudoers
```

### Inventory Issues
```bash
# List all hosts
ansible all --list-hosts

# List hosts in specific group
ansible webservers --list-hosts

# Show inventory graph
ansible-inventory --graph

# Validate inventory syntax
ansible-inventory --list
```

## Expected Results

### Successful Ping Test:
```
web1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
web2 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

### Successful Privilege Escalation:
```
web1 | CHANGED | rc=0 >>
root

web2 | CHANGED | rc=0 >>
root
```

## Key Learning Points

1. **Dedicated Users**: Security best practice to use dedicated service accounts
2. **Key-Based Authentication**: More secure and convenient than passwords
3. **Sudo Configuration**: Proper privilege escalation setup
4. **Inventory Organization**: Logical grouping of hosts with variables
5. **Configuration Management**: Using `ansible.cfg` for defaults
6. **Testing Strategy**: Systematic verification of setup components

## Next Steps

With your hosts fully configured, you can now:
- Create and execute complex playbooks
- Use advanced inventory features
- Implement role-based automation
- Deploy applications and services
- Manage configuration at scale

Your infrastructure is now ready for comprehensive Ansible automation!
