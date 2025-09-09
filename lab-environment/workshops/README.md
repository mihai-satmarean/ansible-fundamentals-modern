# Ansible Fundamentals Workshops

This directory contains comprehensive hands-on workshops extracted from the official Ansible Fundamentals training presentation. Each workshop is designed to provide practical, real-world experience with Ansible automation.

## Workshop Structure

### Module 1: Foundation
- **[Installing Ansible](module-01-installing-ansible.md)** - Get Ansible up and running on your control node
- **[Testing Ansible Connection](module-02-testing-ansible-connection.md)** - Connect to remote servers using SSH keys and passwords

### Module 2: Basic Operations
- **[Full Host Setup](module-03-full-host-setup.md)** - Complete host preparation for Ansible management
- **[Prepare Hosts Playbook](module-04-prepare-hosts-playbook.md)** - Automate host preparation with playbooks

### Module 3: Core Modules and Commands
- **[Commonly Used Modules](module-04-commonly-used-modules.md)** - Master User, Group, File, Copy, and Lineinfile modules
- **[Raw vs Command vs Shell](module-04-raw-vs-command-vs-shell.md)** - Understand the differences and use cases
- **[Task Results Analysis](module-04-task-results-analysis.md)** - Interpret OK vs Changed vs Failed states

### Module 4: Advanced Concepts
- **[Facts, Variables, Loops and Conditions](module-05-facts-variables-loops-conditions.md)** - Dynamic automation with system facts and control structures
- **[Modules Deep Dive and Idempotency](module-06-modules-deep-dive-idempotency.md)** - Advanced module usage and writing reliable playbooks

### Module 5: Professional Features
- **[Templates, Jinja2, and Filters](module-07-templates-jinja2-filters.md)** - Create dynamic configurations with templating
- **[Vault, Roles, and Reusable Playbooks](module-08-vault-roles-reusable-playbooks.md)** - Secure data management and code organization

## Prerequisites

### System Requirements
- **Control Node**: Linux, macOS, or WSL2 with Python 3.6+
- **Managed Hosts**: Linux systems with SSH access
- **Network**: Connectivity between control node and managed hosts

### Required Software
- Ansible 2.9+ (recommended: latest stable version)
- SSH client and server
- Text editor (vim, nano, VS Code, etc.)
- Basic command-line tools (curl, wget, etc.)

### Knowledge Prerequisites
- Basic Linux command-line experience
- Understanding of SSH and networking concepts
- Familiarity with YAML syntax
- Basic understanding of system administration

## Getting Started

### 1. Environment Setup
```bash
# Clone or download the workshop materials
git clone <repository-url>
cd workshops

# Set up your lab environment
# Option A: Use provided Vagrant/Docker setup
# Option B: Use cloud instances (AWS, GCP, Azure)
# Option C: Use local VMs or containers
```

### 2. Inventory Configuration
Create your inventory file with your lab hosts:
```ini
[webservers]
web1 ansible_host=192.168.1.101 ansible_user=your_user
web2 ansible_host=192.168.1.102 ansible_user=your_user

[databases]
db1 ansible_host=192.168.1.103 ansible_user=your_user

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### 3. SSH Key Setup
```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096

# Copy keys to managed hosts
ssh-copy-id user@host1
ssh-copy-id user@host2
```

### 4. Test Connectivity
```bash
# Test basic connectivity
ansible all -i inventory.ini -m ping
```

## Workshop Progression

### Beginner Path (Modules 1-3)
1. Start with **Installing Ansible** to set up your environment
2. Progress through **Testing Ansible Connection** to establish connectivity
3. Complete **Full Host Setup** to prepare your infrastructure
4. Practice with **Commonly Used Modules** to build core skills

### Intermediate Path (Modules 4-5)
1. Master **Raw vs Command vs Shell** to understand execution methods
2. Learn **Task Results Analysis** for better debugging
3. Explore **Facts, Variables, Loops and Conditions** for dynamic automation

### Advanced Path (Modules 6-8)
1. Study **Modules Deep Dive and Idempotency** for professional practices
2. Master **Templates, Jinja2, and Filters** for configuration management
3. Complete **Vault, Roles, and Reusable Playbooks** for enterprise automation

## Lab Environment Options

### Option 1: iximiuz Labs (Recommended)
- **Platform**: [iximiuz Labs Playgrounds](https://labs.iximiuz.com/playgrounds)
- **Benefits**: Pre-configured environments, no setup required
- **Environments**: Ubuntu 24.04, FlexBox, Docker, Debian
- **Access**: Instant browser-based terminals

### Option 2: Cloud Providers
- **AWS**: EC2 instances with security groups configured
- **GCP**: Compute Engine instances
- **Azure**: Virtual Machines
- **DigitalOcean**: Droplets

### Option 3: Local Environment
- **Vagrant**: Multi-VM local environment
- **Docker**: Containerized lab hosts
- **VirtualBox/VMware**: Traditional VMs

### Option 4: Hybrid Setup
- **Control Node**: Local machine or cloud instance
- **Managed Hosts**: Mix of local and cloud resources

## Best Practices for Workshops

### Learning Approach
1. **Read First**: Review the workshop objectives and concepts
2. **Practice**: Follow the hands-on exercises step by step
3. **Experiment**: Modify examples to understand behavior
4. **Troubleshoot**: Work through any issues that arise
5. **Document**: Keep notes of key learnings and solutions

### Safety Guidelines
1. **Use Lab Environment**: Never run exercises on production systems
2. **Backup Data**: Backup any important configurations before modification
3. **Understand Commands**: Read and understand each command before execution
4. **Start Small**: Begin with simple examples before complex scenarios

### Troubleshooting Tips
1. **Check Connectivity**: Verify SSH access and network connectivity
2. **Validate Syntax**: Use `--syntax-check` for playbooks
3. **Use Verbose Mode**: Add `-v`, `-vv`, or `-vvv` for detailed output
4. **Read Error Messages**: Ansible provides detailed error information
5. **Test Incrementally**: Run tasks individually to isolate issues

## Workshop Features

### Hands-On Focus
- **Practical Examples**: Real-world scenarios and use cases
- **Progressive Complexity**: Building from simple to advanced concepts
- **Multiple Approaches**: Different ways to accomplish tasks
- **Error Handling**: How to deal with common issues

### Production Ready
- **Best Practices**: Industry-standard approaches and patterns
- **Security Focus**: Proper handling of sensitive data and access
- **Scalability**: Techniques that work for large environments
- **Maintainability**: Code organization and documentation

### Comprehensive Coverage
- **All Core Modules**: Essential Ansible modules with examples
- **Advanced Features**: Templates, roles, vault, and more
- **Integration Patterns**: How components work together
- **Troubleshooting**: Common issues and solutions

## Additional Resources

### Documentation
- [Official Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Ansible Galaxy](https://galaxy.ansible.com/) - Community roles and collections

### Community
- [Ansible Community Forum](https://forum.ansible.com/)
- [Reddit r/ansible](https://www.reddit.com/r/ansible/)
- [Stack Overflow Ansible Tag](https://stackoverflow.com/questions/tagged/ansible)

### Advanced Learning
- [Ansible for DevOps](https://www.ansiblefordevops.com/) - Book by Jeff Geerling
- [Ansible Molecule](https://molecule.readthedocs.io/) - Testing framework
- [AWX/Ansible Tower](https://github.com/ansible/awx) - Web-based interface

## Contributing

### Feedback Welcome
- Report issues or improvements via GitHub issues
- Suggest additional workshop topics
- Share your lab environment configurations
- Contribute fixes or enhancements

### Workshop Development
- Follow the established format and structure
- Include comprehensive examples and explanations
- Test all code examples in multiple environments
- Provide troubleshooting guidance

## License and Usage

These workshops are designed for educational purposes and can be used freely for:
- Individual learning and skill development
- Corporate training programs
- Educational institutions
- Community workshops and meetups

Please maintain attribution to the original Ansible Fundamentals training program when using these materials.

---

**Happy Learning!** 🚀

Start your Ansible journey with Module 1 and work your way through to become an Ansible automation expert!
