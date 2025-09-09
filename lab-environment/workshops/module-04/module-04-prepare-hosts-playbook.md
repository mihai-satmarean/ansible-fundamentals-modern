# Module 4: Prepare Hosts for Ansible Management with Playbooks

## Objective
Learn how to write and use Ansible Playbooks to prepare hosts for Ansible management by creating dedicated users, generating SSH keys, and configuring proper authentication.

## Prerequisites
- Ansible installed and configured
- Access to target hosts (initially with root/admin access)
- Basic understanding of YAML syntax

## Lab Steps

### Step 1: Understanding the Playbook Structure

A playbook to prepare hosts needs to:
1. Create a dedicated Ansible user
2. Generate SSH key pairs
3. Set up SSH directories with proper permissions
4. Configure authorized keys for passwordless authentication

### Step 2: Create the Host Preparation Playbook

Create `prepare_host.yml`:

```yaml
---
- name: Prepare Host for Ansible Management
  hosts: all
  become: yes
  vars:
    ansible_user_name: ansibleuser
    ansible_user_home: "/home/{{ ansible_user_name }}"
    
  tasks:
    - name: Create dedicated ansible user
      user:
        name: "{{ ansible_user_name }}"
        state: present
        create_home: yes
        shell: /bin/bash
        comment: "Dedicated Ansible Management User"
        
    - name: Add ansible user to sudoers with NOPASSWD
      lineinfile:
        path: /etc/sudoers
        line: "{{ ansible_user_name }} ALL=(ALL) NOPASSWD:ALL"
        validate: 'visudo -cf %s'
        backup: yes
        
    - name: Generate SSH key pair on control machine
      openssh_keypair:
        path: "{{ ansible_user_home }}/.ssh/id_rsa"
        size: 2048
        state: present
        owner: "{{ ansible_user_name }}"
        group: "{{ ansible_user_name }}"
      delegate_to: localhost
      run_once: true
      become: no
      
    - name: Create .ssh directory on remote host
      file:
        path: "{{ ansible_user_home }}/.ssh"
        state: directory
        mode: '0700'
        owner: "{{ ansible_user_name }}"
        group: "{{ ansible_user_name }}"
        
    - name: Set authorized key for ansible user
      authorized_key:
        user: "{{ ansible_user_name }}"
        state: present
        key: "{{ lookup('file', ansible_user_home + '/.ssh/id_rsa.pub') }}"
        
    - name: Test SSH connection as new user
      ping:
      become: no
      remote_user: "{{ ansible_user_name }}"
```

### Step 3: Create Inventory for Initial Setup

Create `initial-hosts.ini` for the initial setup:

```ini
[targets]
server1 ansible_host=192.168.1.100 ansible_user=root
server2 ansible_host=192.168.1.101 ansible_user=root  
server3 ansible_host=192.168.1.102 ansible_user=root

[targets:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### Step 4: Run the Preparation Playbook

Execute the playbook to set up your hosts:

```bash
# Run the playbook (will prompt for root password)
ansible-playbook -i initial-hosts.ini prepare_host.yml --ask-pass

# Or if using SSH keys for root access
ansible-playbook -i initial-hosts.ini prepare_host.yml
```

### Step 5: Create Production Inventory

After successful setup, create `hosts.ini` for ongoing management:

```ini
[webservers]
server1 ansible_host=192.168.1.100
server2 ansible_host=192.168.1.101

[databases]
server3 ansible_host=192.168.1.102

[all:vars]
ansible_user=ansibleuser
ansible_ssh_private_key_file=/home/ansibleuser/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### Step 6: Verify the Setup

Test the new configuration:

```bash
# Test connectivity with new user
ansible all -i hosts.ini -m ping

# Test privilege escalation
ansible all -i hosts.ini -m shell -a "whoami" --become

# Gather system facts
ansible all -i hosts.ini -m setup -a "filter=ansible_distribution*"
```

## Advanced Playbook Examples

### Enhanced Preparation Playbook

Create `advanced_prepare_host.yml` with additional security and configuration:

```yaml
---
- name: Advanced Host Preparation for Ansible
  hosts: all
  become: yes
  vars:
    ansible_user_name: ansibleuser
    ansible_user_home: "/home/{{ ansible_user_name }}"
    ssh_port: 22
    allowed_ssh_users: ["{{ ansible_user_name }}", "ubuntu", "admin"]
    
  tasks:
    - name: Update system packages
      package:
        name: "*"
        state: latest
      when: ansible_os_family == "RedHat"
      
    - name: Update system packages (Debian/Ubuntu)
      apt:
        upgrade: dist
        update_cache: yes
      when: ansible_os_family == "Debian"
      
    - name: Install essential packages
      package:
        name:
          - vim
          - htop
          - curl
          - wget
          - git
          - python3
          - python3-pip
        state: present
        
    - name: Create ansible user with specific UID
      user:
        name: "{{ ansible_user_name }}"
        uid: 2000
        state: present
        create_home: yes
        shell: /bin/bash
        comment: "Ansible Management User"
        groups: wheel
        append: yes
      when: ansible_os_family == "RedHat"
      
    - name: Create ansible user (Debian/Ubuntu)
      user:
        name: "{{ ansible_user_name }}"
        uid: 2000
        state: present
        create_home: yes
        shell: /bin/bash
        comment: "Ansible Management User"
        groups: sudo
        append: yes
      when: ansible_os_family == "Debian"
        
    - name: Configure sudoers for ansible user
      copy:
        content: |
          # Ansible user sudoers configuration
          {{ ansible_user_name }} ALL=(ALL) NOPASSWD:ALL
          
          # Allow ansible user to manage services
          {{ ansible_user_name }} ALL=(ALL) NOPASSWD: /bin/systemctl start *, /bin/systemctl stop *, /bin/systemctl restart *, /bin/systemctl reload *
        dest: "/etc/sudoers.d/{{ ansible_user_name }}"
        mode: '0440'
        validate: 'visudo -cf %s'
        
    - name: Generate SSH key pair on control machine
      openssh_keypair:
        path: "{{ ansible_user_home }}/.ssh/id_rsa"
        size: 4096
        type: rsa
        state: present
        comment: "{{ ansible_user_name }}@ansible-control"
      delegate_to: localhost
      run_once: true
      become: no
      
    - name: Create .ssh directory with proper permissions
      file:
        path: "{{ ansible_user_home }}/.ssh"
        state: directory
        mode: '0700'
        owner: "{{ ansible_user_name }}"
        group: "{{ ansible_user_name }}"
        
    - name: Set authorized key for ansible user
      authorized_key:
        user: "{{ ansible_user_name }}"
        state: present
        key: "{{ lookup('file', ansible_user_home + '/.ssh/id_rsa.pub') }}"
        key_options: 'no-port-forwarding,no-X11-forwarding'
        
    - name: Configure SSH for security
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        backup: yes
      loop:
        - { regexp: '^#?PermitRootLogin', line: 'PermitRootLogin no' }
        - { regexp: '^#?PasswordAuthentication', line: 'PasswordAuthentication no' }
        - { regexp: '^#?PubkeyAuthentication', line: 'PubkeyAuthentication yes' }
        - { regexp: '^#?AllowUsers', line: "AllowUsers {{ allowed_ssh_users | join(' ') }}" }
      notify: restart ssh
      
    - name: Set up firewall (UFW - Ubuntu/Debian)
      ufw:
        rule: allow
        port: "{{ ssh_port }}"
        proto: tcp
      when: ansible_os_family == "Debian"
      
    - name: Enable firewall
      ufw:
        state: enabled
      when: ansible_os_family == "Debian"
      
    - name: Test connection as ansible user
      ping:
      become: no
      remote_user: "{{ ansible_user_name }}"
      
  handlers:
    - name: restart ssh
      service:
        name: ssh
        state: restarted
      when: ansible_os_family == "Debian"
      
    - name: restart ssh
      service:
        name: sshd
        state: restarted
      when: ansible_os_family == "RedHat"
```

### Step 7: Testing and Validation Playbook

Create `validate_setup.yml` to verify your configuration:

```yaml
---
- name: Validate Ansible Setup
  hosts: all
  vars:
    ansible_user_name: ansibleuser
    
  tasks:
    - name: Check if ansible user exists
      getent:
        database: passwd
        key: "{{ ansible_user_name }}"
      register: user_check
      
    - name: Verify user home directory
      stat:
        path: "/home/{{ ansible_user_name }}"
      register: home_dir
      
    - name: Check SSH key authentication
      stat:
        path: "/home/{{ ansible_user_name }}/.ssh/authorized_keys"
      register: auth_keys
      
    - name: Test sudo access
      shell: "sudo -n whoami"
      register: sudo_test
      become: no
      
    - name: Display validation results
      debug:
        msg: |
          User exists: {{ user_check.ansible_facts.getent_passwd[ansible_user_name] is defined }}
          Home directory exists: {{ home_dir.stat.exists }}
          SSH keys configured: {{ auth_keys.stat.exists }}
          Sudo access: {{ sudo_test.stdout == 'root' }}
          
    - name: Fail if validation unsuccessful
      fail:
        msg: "Host setup validation failed"
      when: >
        not user_check.ansible_facts.getent_passwd[ansible_user_name] is defined or
        not home_dir.stat.exists or
        not auth_keys.stat.exists or
        sudo_test.stdout != 'root'
```

Run the validation:

```bash
ansible-playbook -i hosts.ini validate_setup.yml
```

## Key Learning Points

### Playbook Structure
1. **Plays**: Top-level organization unit
2. **Tasks**: Individual actions to perform
3. **Variables**: Dynamic values used throughout playbooks
4. **Handlers**: Tasks triggered by notifications
5. **Modules**: The actual work units (user, file, authorized_key, etc.)

### Best Practices Demonstrated
1. **Idempotency**: Tasks can be run multiple times safely
2. **Error Handling**: Using `validate` parameter for critical files
3. **Security**: Proper file permissions and SSH configuration
4. **Modularity**: Separate playbooks for different purposes
5. **Documentation**: Clear task names and comments

### Module Usage Examples

#### User Module
```yaml
- name: Create user with specific attributes
  user:
    name: username
    uid: 1001
    shell: /bin/bash
    create_home: yes
    groups: sudo
    append: yes
```

#### File Module
```yaml
- name: Create directory with permissions
  file:
    path: /path/to/directory
    state: directory
    mode: '0755'
    owner: username
    group: groupname
```

#### Authorized_key Module
```yaml
- name: Add SSH key
  authorized_key:
    user: username
    key: "{{ lookup('file', '/path/to/public/key') }}"
    state: present
```

### Troubleshooting Common Issues

#### SSH Key Generation Issues
```bash
# Check if key exists
ls -la ~/.ssh/

# Generate manually if needed
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Set proper permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

#### Sudoers Configuration Issues
```bash
# Test sudoers syntax
sudo visudo -c

# Check specific user
sudo -u ansibleuser sudo -n whoami
```

#### Playbook Debugging
```bash
# Run with verbose output
ansible-playbook playbook.yml -vvv

# Check syntax
ansible-playbook playbook.yml --syntax-check

# Dry run (check mode)
ansible-playbook playbook.yml --check
```

## Expected Results

### Successful Playbook Execution:
```
PLAY [Prepare Host for Ansible Management] ************************************

TASK [Gathering Facts] *******************************************************
ok: [server1]
ok: [server2]

TASK [Create dedicated ansible user] ****************************************
changed: [server1]
changed: [server2]

TASK [Add ansible user to sudoers with NOPASSWD] ****************************
changed: [server1]
changed: [server2]

...

PLAY RECAP *******************************************************************
server1                    : ok=6    changed=4    unreachable=0    failed=0
server2                    : ok=6    changed=4    unreachable=0    failed=0
```

### Validation Success:
```
TASK [Display validation results] *******************************************
ok: [server1] => {
    "msg": "User exists: True\nHome directory exists: True\nSSH keys configured: True\nSudo access: True\n"
}
```

## Next Steps

With hosts properly prepared using playbooks, you can now:
- Create more complex automation workflows
- Implement configuration management
- Deploy applications and services
- Use advanced playbook features like roles and includes
- Build reusable automation components

This foundation provides a secure, manageable infrastructure ready for comprehensive Ansible automation!
