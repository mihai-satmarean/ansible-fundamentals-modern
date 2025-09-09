# Module 4: Commonly Used Modules - User, Group, File, Copy, Lineinfile

## Objective
Gain practical experience with essential Ansible modules: User, Group, File, Copy, and Lineinfile modules by performing common system administration tasks.

## Prerequisites
- Ansible properly configured with inventory
- SSH access to managed hosts
- Sudo privileges on target systems

## Lab Setup

### Create Inventory File
Create `hosts.ini`:

```ini
[lab_hosts]
target1 ansible_host=192.168.1.101 ansible_user=ansibleuser
target2 ansible_host=192.168.1.102 ansible_user=ansibleuser

[lab_hosts:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### Prepare Configuration File
Create `sample.conf` on your control machine:

```bash
# Create sample configuration file
cat > sample.conf << EOF
# Sample configuration file
PasswordAuthentication yes
Port 22
Protocol 2
MaxAuthTries 3
EOF
```

## Lab Steps

### Step 1: User and Group Management

Create the main playbook `lab_playbook.yml`:

```yaml
---
- name: Ansible Modules Hands-on Lab
  hosts: lab_hosts
  become: yes
  vars:
    app_user: john
    app_group: webadmin
    config_dir: /etc/myconfigs
    
  tasks:
    # GROUP MODULE
    - name: Ensure the group 'webadmin' exists
      group:
        name: "{{ app_group }}"
        state: present
        gid: 3000
        
    - name: Create additional groups
      group:
        name: "{{ item }}"
        state: present
      loop:
        - developers
        - operators
        - dbadmin
        
    # USER MODULE  
    - name: Create user 'john' with specific attributes
      user:
        name: "{{ app_user }}"
        group: "{{ app_group }}"
        groups: developers,operators
        create_home: yes
        shell: /bin/bash
        uid: 3001
        comment: "Application User John"
        password: "{{ 'secretpassword' | password_hash('sha512') }}"
        
    - name: Create additional users
      user:
        name: "{{ item.name }}"
        group: "{{ item.group }}"
        create_home: "{{ item.create_home | default(yes) }}"
        shell: "{{ item.shell | default('/bin/bash') }}"
        comment: "{{ item.comment }}"
      loop:
        - { name: alice, group: webadmin, comment: "Alice Developer" }
        - { name: bob, group: dbadmin, comment: "Bob Database Admin" }
        - { name: charlie, group: operators, comment: "Charlie Operations" }
        
    - name: Add users to additional groups
      user:
        name: alice
        groups: developers,webadmin
        append: yes
```

### Step 2: File and Directory Operations

Add these tasks to your playbook:

```yaml
    # FILE MODULE
    - name: Create configuration directory
      file:
        path: "{{ config_dir }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        mode: '0755'
        
    - name: Create subdirectories
      file:
        path: "{{ config_dir }}/{{ item }}"
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        mode: '0750'
      loop:
        - nginx
        - apache
        - ssl
        - backup
        
    - name: Create log directory with specific permissions
      file:
        path: /var/log/myapp
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        mode: '0755'
        
    - name: Create symbolic link
      file:
        src: "{{ config_dir }}"
        dest: /opt/myapp-config
        state: link
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        
    - name: Set permissions on existing files
      file:
        path: /tmp
        mode: '1777'
        state: directory
```

### Step 3: Copy Module Operations

Continue adding to your playbook:

```yaml
    # COPY MODULE
    - name: Copy configuration file to target
      copy:
        src: ./sample.conf
        dest: "{{ config_dir }}/sample.conf"
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        mode: '0644'
        backup: yes
        
    - name: Copy with content directly in playbook
      copy:
        content: |
          # Application Configuration
          app_name=MyApplication
          app_version=1.0.0
          debug=false
          log_level=INFO
          
          # Database Configuration  
          db_host=localhost
          db_port=5432
          db_name=myapp
          
          # Security Settings
          enable_ssl=true
          session_timeout=3600
        dest: "{{ config_dir }}/app.conf"
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        mode: '0600'
        
    - name: Copy multiple files
      copy:
        src: "{{ item }}"
        dest: "{{ config_dir }}/{{ item }}"
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        mode: '0644'
      loop:
        - sample.conf
      when: item is file
      
    - name: Copy directory recursively
      copy:
        src: configs/
        dest: "{{ config_dir }}/"
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        directory_mode: '0755'
        mode: '0644'
      # Note: This requires a 'configs' directory on control node
```

### Step 4: Lineinfile Module Operations

Add these lineinfile tasks:

```yaml
    # LINEINFILE MODULE
    - name: Disable password authentication in SSH config
      lineinfile:
        path: "{{ config_dir }}/sample.conf"
        regexp: '^PasswordAuthentication.*'
        line: 'PasswordAuthentication no'
        backup: yes
        
    - name: Add multiple configuration lines
      lineinfile:
        path: "{{ config_dir }}/sample.conf"
        line: "{{ item }}"
        create: yes
      loop:
        - 'AllowUsers john alice bob'
        - 'MaxStartups 10:30:100'
        - 'ClientAliveInterval 300'
        - 'ClientAliveCountMax 2'
        
    - name: Insert line after specific pattern
      lineinfile:
        path: "{{ config_dir }}/app.conf"
        insertafter: '^\[database\]'
        line: 'db_timeout=30'
        
    - name: Insert line before specific pattern
      lineinfile:
        path: "{{ config_dir }}/app.conf"
        insertbefore: '^\[security\]'
        line: '# Security configuration starts here'
        
    - name: Remove specific lines
      lineinfile:
        path: "{{ config_dir }}/sample.conf"
        regexp: '^Protocol.*'
        state: absent
        
    - name: Add line only if it doesn't exist
      lineinfile:
        path: "{{ config_dir }}/app.conf"
        line: 'maintenance_mode=false'
        insertafter: EOF
        
    - name: Modify system configuration
      lineinfile:
        path: /etc/security/limits.conf
        regexp: '^{{ app_user }}.*nofile'
        line: '{{ app_user }} soft nofile 65536'
        backup: yes
        
    - name: Configure sudoers for application user
      lineinfile:
        path: /etc/sudoers.d/myapp
        line: '{{ app_user }} ALL=(ALL) NOPASSWD: /bin/systemctl restart myapp'
        create: yes
        mode: '0440'
        validate: 'visudo -cf %s'
```

### Step 5: Advanced Module Usage

Add validation and advanced tasks:

```yaml
    # VALIDATION AND VERIFICATION
    - name: Verify user creation
      getent:
        database: passwd
        key: "{{ app_user }}"
      register: user_info
      
    - name: Display user information
      debug:
        msg: "User {{ app_user }} UID: {{ user_info.ansible_facts.getent_passwd[app_user][1] }}"
        
    - name: Verify group creation
      getent:
        database: group
        key: "{{ app_group }}"
      register: group_info
      
    - name: Check file permissions
      stat:
        path: "{{ config_dir }}/app.conf"
      register: file_stats
      
    - name: Display file information
      debug:
        msg: |
          File: {{ config_dir }}/app.conf
          Owner: {{ file_stats.stat.pw_name }}
          Group: {{ file_stats.stat.gr_name }}
          Mode: {{ file_stats.stat.mode }}
          Size: {{ file_stats.stat.size }} bytes
          
    # CLEANUP TASKS (optional)
    - name: Create cleanup script
      copy:
        content: |
          #!/bin/bash
          # Cleanup script for lab environment
          echo "Cleaning up lab resources..."
          
          # Remove users (except system users)
          for user in john alice bob charlie; do
              if id "$user" &>/dev/null; then
                  userdel -r "$user" 2>/dev/null
                  echo "Removed user: $user"
              fi
          done
          
          # Remove groups
          for group in webadmin developers operators dbadmin; do
              if getent group "$group" &>/dev/null; then
                  groupdel "$group" 2>/dev/null
                  echo "Removed group: $group"
              fi
          done
          
          # Remove directories
          rm -rf {{ config_dir }} /var/log/myapp /opt/myapp-config
          rm -f /etc/sudoers.d/myapp
          
          echo "Cleanup completed!"
        dest: /tmp/cleanup-lab.sh
        mode: '0755'
```

## Running the Lab

### Execute the Playbook

```bash
# Run the complete playbook
ansible-playbook -i hosts.ini lab_playbook.yml

# Run with verbose output
ansible-playbook -i hosts.ini lab_playbook.yml -v

# Check syntax first
ansible-playbook -i hosts.ini lab_playbook.yml --syntax-check

# Dry run (check what would change)
ansible-playbook -i hosts.ini lab_playbook.yml --check
```

### Verify Changes on Target Hosts

SSH into your target hosts and verify:

```bash
# Check users and groups
id john
id alice
getent group webadmin

# Check directories and files
ls -la /etc/myconfigs/
cat /etc/myconfigs/sample.conf
cat /etc/myconfigs/app.conf

# Check permissions
ls -la /var/log/myapp
ls -la /opt/myapp-config

# Check sudoers
cat /etc/sudoers.d/myapp
```

## Module-Specific Examples

### User Module Advanced Examples

```yaml
- name: Create system user (no home directory)
  user:
    name: sysuser
    system: yes
    shell: /bin/false
    home: /var/lib/sysuser
    create_home: no
    
- name: Lock user account
  user:
    name: john
    password_lock: yes
    
- name: Set user expiration date
  user:
    name: tempuser
    expires: 1640995200  # Unix timestamp
    
- name: Generate SSH key for user
  user:
    name: john
    generate_ssh_key: yes
    ssh_key_bits: 4096
    ssh_key_file: .ssh/id_rsa
```

### Group Module Advanced Examples

```yaml
- name: Create system group
  group:
    name: sysgroup
    system: yes
    
- name: Remove group
  group:
    name: oldgroup
    state: absent
```

### File Module Advanced Examples

```yaml
- name: Create file with specific attributes
  file:
    path: /etc/myapp/config.json
    state: touch
    mode: '0600'
    owner: myapp
    group: myapp
    modification_time: preserve
    access_time: preserve
    
- name: Remove file
  file:
    path: /tmp/unwanted-file
    state: absent
    
- name: Create hard link
  file:
    src: /etc/myapp/config.json
    dest: /etc/myapp/config.backup
    state: hard
```

### Copy Module Advanced Examples

```yaml
- name: Copy with validation
  copy:
    src: nginx.conf
    dest: /etc/nginx/nginx.conf
    backup: yes
    validate: 'nginx -t -c %s'
    
- name: Copy with templating (using variables)
  copy:
    content: |
      server_name={{ ansible_hostname }}
      listen_port={{ http_port | default(80) }}
    dest: /etc/myapp/server.conf
    
- name: Force copy (overwrite even if identical)
  copy:
    src: important.conf
    dest: /etc/important.conf
    force: yes
```

### Lineinfile Module Advanced Examples

```yaml
- name: Insert line at beginning of file
  lineinfile:
    path: /etc/hosts
    line: '127.0.0.1 myapp.local'
    insertbefore: BOF
    
- name: Replace entire line based on regex
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^#?Port.*'
    line: 'Port 2222'
    
- name: Use backreferences in replacement
  lineinfile:
    path: /etc/myapp.conf
    regexp: '^(server_name\s*=\s*).*'
    line: '\1{{ ansible_hostname }}'
    backrefs: yes
```

## Troubleshooting Common Issues

### Permission Errors
```bash
# Check sudo access
ansible lab_hosts -m shell -a "whoami" --become

# Verify file permissions
ansible lab_hosts -m stat -a "path=/etc/myconfigs"
```

### User/Group Issues
```bash
# Check if user exists
ansible lab_hosts -m shell -a "id john"

# List all groups
ansible lab_hosts -m shell -a "cat /etc/group | grep webadmin"
```

### File Operation Issues
```bash
# Check disk space
ansible lab_hosts -m shell -a "df -h"

# Verify file existence
ansible lab_hosts -m stat -a "path=/etc/myconfigs/sample.conf"
```

## Key Learning Points

### Module Characteristics
1. **Idempotency**: All modules are designed to be idempotent
2. **State Management**: Modules manage desired state, not commands
3. **Error Handling**: Built-in validation and error reporting
4. **Return Values**: Consistent return format across modules

### Best Practices
1. **Always use `backup: yes`** for critical file modifications
2. **Validate configurations** when possible (e.g., nginx -t)
3. **Set explicit permissions** rather than relying on defaults
4. **Use variables** for reusable values
5. **Document your tasks** with descriptive names

### Security Considerations
1. **Principle of least privilege** for user creation
2. **Secure file permissions** (especially for config files)
3. **Validate sudoers** entries to prevent lockout
4. **Use password hashing** for user passwords
5. **Regular cleanup** of temporary resources

## Expected Results

### Successful Execution Output:
```
PLAY [Ansible Modules Hands-on Lab] ******************************************

TASK [Ensure the group 'webadmin' exists] ************************************
changed: [target1]
changed: [target2]

TASK [Create user 'john' with specific attributes] ***************************
changed: [target1]
changed: [target2]

...

PLAY RECAP ********************************************************************
target1                    : ok=15   changed=12   unreachable=0    failed=0
target2                    : ok=15   changed=12   unreachable=0    failed=0
```

### Verification Results:
- Users `john`, `alice`, `bob`, `charlie` created with proper groups
- Directory `/etc/myconfigs` exists with correct permissions
- Configuration files copied and modified as expected
- SSH configuration updated with security settings
- All file permissions set correctly

## Cleanup

Run the cleanup script when done:

```bash
ansible lab_hosts -m shell -a "/tmp/cleanup-lab.sh" --become
```

This comprehensive lab demonstrates the power and flexibility of Ansible's core modules for system administration tasks!
