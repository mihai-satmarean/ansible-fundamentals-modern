# Module 1: Installing Ansible on the Control Node

## Objective
Learn how to install Ansible on different operating systems and verify the installation.

## Prerequisites
- A machine with Python 2.6 or higher
- The control node can run Windows, Linux, or Mac OS
- Internet connectivity for package downloads

## Lab Steps

### Method 1: Using pip (Python Package Manager)

```bash
# Install Ansible using pip
pip install ansible
```

### Method 2: Using OS Package Manager

#### On Ubuntu/Debian:
```bash
# Update package list
sudo apt update

# Install Ansible
sudo apt install ansible
```

#### On Fedora/CentOS/RHEL:
```bash
# Install Ansible using dnf (Fedora) or yum (CentOS/RHEL)
sudo dnf install ansible
# OR
sudo yum install ansible
```

### Verifying the Installation

After installation, verify that Ansible is properly installed:

```bash
# Check Ansible version and configuration
ansible --version
```

This command will display:
- The version of Ansible installed
- Configuration file location
- Module library paths
- Python version
- Other configuration information

## Expected Output

You should see output similar to:
```
ansible [core 2.15.x]
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/home/user/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3/site-packages/ansible
  ansible collection location = /home/user/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/bin/ansible
  python version = 3.x.x
```

## Key Learning Points

1. **Multiple Installation Methods**: Ansible can be installed via pip or system package managers
2. **Cross-Platform**: Works on Windows, Linux, and macOS
3. **Python Dependency**: Requires Python 2.6 or higher
4. **Verification**: Always verify installation with `ansible --version`

## Next Steps

Once Ansible is installed, you're ready to:
- Configure your first inventory
- Run ad-hoc commands
- Create and execute playbooks
