# Module 6: Ansible Modules Deep Dive and Writing Idempotent Playbooks

## Objective
Gain in-depth understanding of Ansible modules, learn to write idempotent playbooks, and explore advanced module usage patterns for reliable automation.

## Prerequisites
- Solid understanding of basic Ansible concepts
- Experience with common modules
- Access to target hosts with appropriate privileges

## Understanding Idempotency

### What is Idempotency?
**Idempotency** means that running the same operation multiple times produces the same result without unwanted side effects. In Ansible context:
- First run: Makes necessary changes (CHANGED)
- Subsequent runs: No changes needed (OK)
- System remains in desired state regardless of execution count

### Why Idempotency Matters
1. **Reliability**: Safe to re-run playbooks
2. **Predictability**: Consistent results
3. **Safety**: No accidental duplications or conflicts
4. **Efficiency**: Only changes what's necessary

## Lab Setup

### Create Inventory
Create `hosts.ini`:

```ini
[web_servers]
web1 ansible_host=192.168.1.101 ansible_user=ansibleuser
web2 ansible_host=192.168.1.102 ansible_user=ansibleuser

[db_servers]
db1 ansible_host=192.168.1.103 ansible_user=ansibleuser

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

## Lab 1: Module Deep Dive

### Create Module Exploration Playbook

Create `module_deep_dive.yml`:

```yaml
---
- name: Deep Dive into Ansible Modules
  hosts: aws
  become: yes
  vars:
    app_name: "webapp"
    app_user: "webuser"
    app_group: "webadmin"
    config_dir: "/etc/webapp"
    
  tasks:
    # PACKAGE MODULE - Deep Dive
    - name: "PACKAGE: Install multiple packages with different states"
      package:
        name: "{{ item.name }}"
        state: "{{ item.state }}"
      loop:
        - { name: "nginx", state: "present" }
        - { name: "htop", state: "latest" }
        - { name: "vim", state: "present" }
        - { name: "wget", state: "present" }
      register: package_results
      
    - name: "PACKAGE: Display installation results"
      debug:
        msg: |
          Package: {{ item.item.name }}
          State: {{ item.item.state }}
          Changed: {{ item.changed }}
          {% if item.changed %}
          Action: {{ 'Installed' if 'installed' in item.msg else 'Updated' if 'upgraded' in item.msg else 'Modified' }}
          {% endif %}
      loop: "{{ package_results.results }}"
      
    # USER MODULE - Advanced Usage
    - name: "USER: Create application user with comprehensive attributes"
      user:
        name: "{{ app_user }}"
        group: "{{ app_group }}"
        groups: "www-data,sudo"
        append: yes
        shell: "/bin/bash"
        home: "/home/{{ app_user }}"
        create_home: yes
        uid: 3000
        comment: "Web Application User"
        password: "{{ 'SecurePassword123!' | password_hash('sha512') }}"
        update_password: on_create  # Only set password on creation
        expires: -1  # Never expires
        password_lock: no
        system: no
      register: user_creation
      
    - name: "USER: Generate SSH key for application user"
      user:
        name: "{{ app_user }}"
        generate_ssh_key: yes
        ssh_key_bits: 4096
        ssh_key_type: rsa
        ssh_key_comment: "{{ app_user }}@{{ ansible_hostname }}"
        ssh_key_file: ".ssh/id_rsa"
      register: ssh_key_gen
      
    # GROUP MODULE - Advanced Usage
    - name: "GROUP: Create application group"
      group:
        name: "{{ app_group }}"
        gid: 3000
        state: present
        system: no
      register: group_creation
      
    # FILE MODULE - Comprehensive Operations
    - name: "FILE: Create complex directory structure"
      file:
        path: "{{ item.path }}"
        state: "{{ item.state }}"
        owner: "{{ item.owner | default('root') }}"
        group: "{{ item.group | default('root') }}"
        mode: "{{ item.mode }}"
        recurse: "{{ item.recurse | default(false) }}"
      loop:
        - { path: "{{ config_dir }}", state: "directory", owner: "{{ app_user }}", group: "{{ app_group }}", mode: "0755" }
        - { path: "{{ config_dir }}/conf.d", state: "directory", owner: "{{ app_user }}", group: "{{ app_group }}", mode: "0755" }
        - { path: "{{ config_dir }}/ssl", state: "directory", owner: "{{ app_user }}", group: "{{ app_group }}", mode: "0700" }
        - { path: "/var/log/{{ app_name }}", state: "directory", owner: "{{ app_user }}", group: "{{ app_group }}", mode: "0755" }
        - { path: "/var/run/{{ app_name }}", state: "directory", owner: "{{ app_user }}", group: "{{ app_group }}", mode: "0755" }
        - { path: "{{ config_dir }}/temp.conf", state: "touch", owner: "{{ app_user }}", group: "{{ app_group }}", mode: "0644" }
      register: file_operations
      
    # COPY MODULE - Advanced Features
    - name: "COPY: Deploy configuration files with validation"
      copy:
        content: |
          # {{ app_name | upper }} Configuration File
          # Generated by Ansible on {{ ansible_date_time.iso8601 }}
          
          [main]
          app_name={{ app_name }}
          app_user={{ app_user }}
          app_group={{ app_group }}
          hostname={{ ansible_hostname }}
          
          [paths]
          config_dir={{ config_dir }}
          log_dir=/var/log/{{ app_name }}
          run_dir=/var/run/{{ app_name }}
          
          [system]
          os_family={{ ansible_os_family }}
          distribution={{ ansible_distribution }}
          architecture={{ ansible_architecture }}
          
          [resources]
          cpu_count={{ ansible_processor_vcpus }}
          memory_mb={{ ansible_memtotal_mb }}
        dest: "{{ config_dir }}/{{ app_name }}.conf"
        owner: "{{ app_user }}"
        group: "{{ app_group }}"
        mode: "0644"
        backup: yes
        validate: "grep -q 'app_name={{ app_name }}' %s"
      register: config_deployment
      
    # SERVICE MODULE - Advanced Management
    - name: "SERVICE: Configure and manage NGINX service"
      service:
        name: nginx
        state: started
        enabled: yes
        daemon_reload: yes  # For systemd systems
      register: service_management
      
    # LINEINFILE MODULE - Complex Modifications
    - name: "LINEINFILE: Configure system limits"
      lineinfile:
        path: /etc/security/limits.conf
        regexp: "^{{ app_user }}\\s+{{ item.type }}\\s+{{ item.item }}"
        line: "{{ app_user }} {{ item.type }} {{ item.item }} {{ item.value }}"
        backup: yes
        create: no
      loop:
        - { type: "soft", item: "nofile", value: "65536" }
        - { type: "hard", item: "nofile", value: "65536" }
        - { type: "soft", item: "nproc", value: "32768" }
        - { type: "hard", item: "nproc", value: "32768" }
      register: limits_config
      
    # TEMPLATE MODULE - Dynamic Content
    - name: "TEMPLATE: Create dynamic NGINX configuration"
      template:
        src: nginx_vhost.conf.j2
        dest: "/etc/nginx/sites-available/{{ app_name }}"
        owner: root
        group: root
        mode: "0644"
        backup: yes
      register: nginx_template
      notify: restart nginx
      
    # STAT MODULE - Information Gathering
    - name: "STAT: Gather information about created resources"
      stat:
        path: "{{ item }}"
      loop:
        - "{{ config_dir }}"
        - "{{ config_dir }}/{{ app_name }}.conf"
        - "/home/{{ app_user }}/.ssh/id_rsa.pub"
        - "/etc/nginx/sites-available/{{ app_name }}"
      register: resource_stats
      
    # DISPLAY MODULE USAGE RESULTS
    - name: "Display comprehensive module usage results"
      debug:
        msg: |
          === MODULE DEEP DIVE RESULTS ===
          
          PACKAGE MODULE:
          - Packages processed: {{ package_results.results | length }}
          - Changes made: {{ package_results.results | selectattr('changed') | list | length }}
          
          USER MODULE:
          - User created: {{ user_creation.changed }}
          - SSH key generated: {{ ssh_key_gen.changed }}
          - User UID: {{ user_creation.uid | default('N/A') }}
          
          GROUP MODULE:
          - Group created: {{ group_creation.changed }}
          - Group GID: {{ group_creation.gid | default('N/A') }}
          
          FILE MODULE:
          - Directories/files processed: {{ file_operations.results | length }}
          - Changes made: {{ file_operations.results | selectattr('changed') | list | length }}
          
          COPY MODULE:
          - Configuration deployed: {{ config_deployment.changed }}
          - Backup created: {{ config_deployment.backup_file is defined }}
          
          SERVICE MODULE:
          - Service state changed: {{ service_management.changed }}
          - Service enabled: {{ service_management.enabled | default('N/A') }}
          
          LINEINFILE MODULE:
          - Limits configured: {{ limits_config.results | selectattr('changed') | list | length }}
          
          TEMPLATE MODULE:
          - Template deployed: {{ nginx_template.changed | default('N/A') }}
          
  handlers:
    - name: restart nginx
      service:
        name: nginx
        state: restarted
```

### Create NGINX Template

Create `templates/nginx_vhost.conf.j2`:

```nginx
# {{ app_name }} Virtual Host Configuration
# Generated by Ansible on {{ ansible_date_time.iso8601 }}

server {
    listen 80;
    server_name {{ ansible_fqdn }} {{ ansible_hostname }};
    
    root /var/www/{{ app_name }};
    index index.html index.htm;
    
    # Logging
    access_log /var/log/{{ app_name }}/access.log;
    error_log /var/log/{{ app_name }}/error.log;
    
    # Performance optimizations based on system specs
{% if ansible_processor_vcpus > 2 %}
    # Multi-core system optimizations
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
{% endif %}
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Static file caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
    }
    
    location ~ ~$ {
        deny all;
    }
}
```

## Lab 2: Idempotency Testing and Demonstration

### Create Idempotency Test Playbook

Create `idempotency_test.yml`:

```yaml
---
- name: Idempotency Testing and Demonstration
  hosts: web_servers
  become: yes
  vars:
    test_app: "idempotency-test"
    test_user: "testuser"
    test_config: "/etc/idempotency-test.conf"
    
  tasks:
    # IDEMPOTENT: Package Installation
    - name: "IDEMPOTENT: Install required packages"
      package:
        name: "{{ item }}"
        state: present
      loop:
        - nginx
        - htop
        - curl
      register: package_install
      
    # IDEMPOTENT: User Management
    - name: "IDEMPOTENT: Create test user"
      user:
        name: "{{ test_user }}"
        shell: /bin/bash
        create_home: yes
        state: present
      register: user_create
      
    # IDEMPOTENT: Directory Creation
    - name: "IDEMPOTENT: Create application directories"
      file:
        path: "{{ item }}"
        state: directory
        owner: "{{ test_user }}"
        mode: "0755"
      loop:
        - "/opt/{{ test_app }}"
        - "/var/log/{{ test_app }}"
        - "/etc/{{ test_app }}"
      register: dir_create
      
    # IDEMPOTENT: Configuration File
    - name: "IDEMPOTENT: Deploy configuration file"
      copy:
        content: |
          # {{ test_app | upper }} Configuration
          # This file demonstrates idempotency
          
          app_name={{ test_app }}
          user={{ test_user }}
          created={{ ansible_date_time.date }}
          hostname={{ ansible_hostname }}
          
          # System Information
          os={{ ansible_distribution }}
          arch={{ ansible_architecture }}
          memory={{ ansible_memtotal_mb }}MB
        dest: "{{ test_config }}"
        owner: "{{ test_user }}"
        mode: "0644"
      register: config_deploy
      
    # IDEMPOTENT: Service Configuration
    - name: "IDEMPOTENT: Ensure NGINX is running and enabled"
      service:
        name: nginx
        state: started
        enabled: yes
      register: service_config
      
    # IDEMPOTENT: File Permissions
    - name: "IDEMPOTENT: Set file permissions"
      file:
        path: "{{ test_config }}"
        owner: "{{ test_user }}"
        group: "{{ test_user }}"
        mode: "0644"
      register: permissions_set
      
    # NON-IDEMPOTENT EXAMPLES (with fixes)
    - name: "NON-IDEMPOTENT: Bad example - always creates new file"
      shell: echo "{{ ansible_date_time.iso8601 }}" > /tmp/timestamp-bad.txt
      register: bad_example
      # This will ALWAYS show as changed
      
    - name: "IDEMPOTENT FIX: Better approach - use copy with content"
      copy:
        content: "Static content that doesn't change\n"
        dest: /tmp/timestamp-good.txt
      register: good_example
      # This will only change once
      
    # IDEMPOTENT: Complex Logic
    - name: "IDEMPOTENT: Conditional configuration based on facts"
      lineinfile:
        path: "{{ test_config }}"
        regexp: "^performance_mode="
        line: "performance_mode={{ 'high' if ansible_memtotal_mb > 2048 else 'standard' }}"
        create: yes
      register: performance_config
      
    # RESULTS ANALYSIS
    - name: "IDEMPOTENCY: Analyze results from first run"
      debug:
        msg: |
          === IDEMPOTENCY TEST RESULTS ===
          
          FIRST RUN EXPECTATIONS (should show CHANGED):
          - Package install: {{ package_install.changed }}
          - User creation: {{ user_create.changed }}
          - Directory creation: {{ dir_create.changed }}
          - Config deployment: {{ config_deploy.changed }}
          - Service config: {{ service_config.changed }}
          - Permissions set: {{ permissions_set.changed }}
          
          NON-IDEMPOTENT EXAMPLES:
          - Bad timestamp (always changes): {{ bad_example.changed }}
          - Good static content: {{ good_example.changed }}
          
          CONDITIONAL CONFIG:
          - Performance mode set: {{ performance_config.changed }}
          
          === RUN THIS PLAYBOOK AGAIN TO TEST IDEMPOTENCY ===
          Second run should show mostly OK (green) results.
      
    # CLEANUP OPTION
    - name: "CLEANUP: Remove test resources (when cleanup=true)"
      block:
        - name: "Remove test user"
          user:
            name: "{{ test_user }}"
            state: absent
            remove: yes
            
        - name: "Remove test directories"
          file:
            path: "{{ item }}"
            state: absent
          loop:
            - "/opt/{{ test_app }}"
            - "/var/log/{{ test_app }}"
            - "/etc/{{ test_app }}"
            - "{{ test_config }}"
            
        - name: "Remove test files"
          file:
            path: "{{ item }}"
            state: absent
          loop:
            - /tmp/timestamp-bad.txt
            - /tmp/timestamp-good.txt
            
      when: cleanup | default(false) | bool
```

## Lab 3: Advanced Idempotent Patterns

### Create Advanced Patterns Playbook

Create `advanced_idempotent_patterns.yml`:

```yaml
---
- name: Advanced Idempotent Patterns and Best Practices
  hosts: web_servers
  become: yes
  vars:
    webapp_name: "advanced-webapp"
    webapp_version: "2.1.0"
    
  tasks:
    # PATTERN 1: Idempotent Shell Commands
    - name: "PATTERN 1: Check if application is installed"
      stat:
        path: "/opt/{{ webapp_name }}/version"
      register: app_version_file
      
    - name: "PATTERN 1: Install application (only if not present or version differs)"
      shell: |
        mkdir -p /opt/{{ webapp_name }}
        echo "{{ webapp_version }}" > /opt/{{ webapp_name }}/version
        echo "Application {{ webapp_name }} v{{ webapp_version }} installed"
      register: app_install
      when: >
        not app_version_file.stat.exists or 
        (app_version_file.stat.exists and 
         lookup('file', '/opt/' + webapp_name + '/version', errors='ignore') != webapp_version)
      changed_when: app_install.rc == 0
      
    # PATTERN 2: Idempotent Configuration Management
    - name: "PATTERN 2: Generate configuration hash"
      set_fact:
        config_content: |
          # Advanced WebApp Configuration
          app_name={{ webapp_name }}
          version={{ webapp_version }}
          hostname={{ ansible_hostname }}
          cpu_count={{ ansible_processor_vcpus }}
          memory_mb={{ ansible_memtotal_mb }}
          
          # Performance settings
          worker_processes={{ ansible_processor_vcpus }}
          max_connections={{ (ansible_memtotal_mb / 4) | int }}
          
    - name: "PATTERN 2: Calculate configuration hash"
      set_fact:
        config_hash: "{{ config_content | hash('md5') }}"
        
    - name: "PATTERN 2: Check existing configuration hash"
      stat:
        path: "/opt/{{ webapp_name }}/config.hash"
      register: existing_hash_file
      
    - name: "PATTERN 2: Read existing hash"
      slurp:
        src: "/opt/{{ webapp_name }}/config.hash"
      register: existing_hash
      when: existing_hash_file.stat.exists
      
    - name: "PATTERN 2: Deploy configuration (only if changed)"
      block:
        - name: "Deploy new configuration"
          copy:
            content: "{{ config_content }}"
            dest: "/opt/{{ webapp_name }}/config.conf"
            backup: yes
            
        - name: "Update configuration hash"
          copy:
            content: "{{ config_hash }}"
            dest: "/opt/{{ webapp_name }}/config.hash"
            
        - name: "Restart service due to config change"
          debug:
            msg: "Configuration changed - service would be restarted here"
            
      when: >
        not existing_hash_file.stat.exists or
        (existing_hash is defined and 
         (existing_hash.content | b64decode | trim) != config_hash)
      register: config_updated
      
    # PATTERN 3: Idempotent Database Operations
    - name: "PATTERN 3: Create database schema (idempotent)"
      shell: |
        # Check if schema exists
        if [ ! -f /opt/{{ webapp_name }}/schema.lock ]; then
          # Create schema
          echo "Creating database schema..."
          # Simulate database operations
          mkdir -p /opt/{{ webapp_name }}/db
          echo "CREATE TABLE users (id INT PRIMARY KEY);" > /opt/{{ webapp_name }}/db/schema.sql
          touch /opt/{{ webapp_name }}/schema.lock
          echo "changed"
        else
          echo "unchanged"
        fi
      register: schema_result
      changed_when: "'changed' in schema_result.stdout"
      
    # PATTERN 4: Idempotent File Downloads
    - name: "PATTERN 4: Download file only if changed"
      get_url:
        url: "https://httpbin.org/json"
        dest: "/opt/{{ webapp_name }}/remote-data.json"
        mode: "0644"
        force: no  # Only download if file doesn't exist or is different
        timeout: 10
      register: file_download
      ignore_errors: yes
      
    # PATTERN 5: Idempotent Service Management
    - name: "PATTERN 5: Ensure service configuration is current"
      copy:
        content: |
          [Unit]
          Description={{ webapp_name | title }} Service
          After=network.target
          
          [Service]
          Type=simple
          User={{ webapp_name }}
          WorkingDirectory=/opt/{{ webapp_name }}
          ExecStart=/opt/{{ webapp_name }}/start.sh
          Restart=always
          
          [Install]
          WantedBy=multi-user.target
        dest: "/etc/systemd/system/{{ webapp_name }}.service"
        mode: "0644"
      register: service_file
      notify: reload systemd
      
    # PATTERN 6: Idempotent Cron Jobs
    - name: "PATTERN 6: Manage cron jobs idempotently"
      cron:
        name: "{{ webapp_name }} cleanup"
        minute: "0"
        hour: "2"
        job: "/opt/{{ webapp_name }}/cleanup.sh"
        user: root
        state: present
      register: cron_job
      
    # PATTERN 7: Idempotent Firewall Rules
    - name: "PATTERN 7: Configure firewall rules"
      ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
        comment: "{{ webapp_name }} service"
      loop:
        - "8080"
        - "8443"
      when: ansible_os_family == "Debian"
      register: firewall_rules
      ignore_errors: yes
      
    # RESULTS SUMMARY
    - name: "Display advanced patterns results"
      debug:
        msg: |
          === ADVANCED IDEMPOTENT PATTERNS RESULTS ===
          
          PATTERN 1 - Conditional Installation:
          - Application installed: {{ app_install.changed | default(false) }}
          
          PATTERN 2 - Configuration Hash Management:
          - Configuration updated: {{ config_updated.changed | default(false) }}
          - Current hash: {{ config_hash[:8] }}...
          
          PATTERN 3 - Database Schema:
          - Schema created: {{ schema_result.changed }}
          
          PATTERN 4 - File Downloads:
          - File downloaded: {{ file_download.changed | default(false) }}
          
          PATTERN 5 - Service Management:
          - Service file updated: {{ service_file.changed }}
          
          PATTERN 6 - Cron Jobs:
          - Cron job configured: {{ cron_job.changed }}
          
          PATTERN 7 - Firewall Rules:
          - Rules configured: {{ firewall_rules.changed | default(false) }}
          
  handlers:
    - name: reload systemd
      systemd:
        daemon_reload: yes
```

## Running the Labs

### Execute Module Deep Dive

```bash
# First create the template directory
mkdir -p templates

# Run the module deep dive
ansible-playbook -i hosts.ini module_deep_dive.yml

# Run with verbose output to see module details
ansible-playbook -i hosts.ini module_deep_dive.yml -v
```

### Execute Idempotency Tests

```bash
# First run - should show CHANGED for new resources
ansible-playbook -i hosts.ini idempotency_test.yml

# Second run - should show OK for existing resources (idempotency test)
ansible-playbook -i hosts.ini idempotency_test.yml

# Compare the outputs to see idempotency in action

# Cleanup test resources
ansible-playbook -i hosts.ini idempotency_test.yml -e "cleanup=true"
```

### Execute Advanced Patterns

```bash
# Run advanced idempotent patterns
ansible-playbook -i hosts.ini advanced_idempotent_patterns.yml

# Run again to verify idempotency
ansible-playbook -i hosts.ini advanced_idempotent_patterns.yml
```

## Key Learning Points

### Module Categories
1. **Core Modules**: Essential functionality (file, copy, service, user, etc.)
2. **Community Modules**: Extended functionality from community
3. **Custom Modules**: User-written modules for specific needs

### Module Parameters
- **Common Parameters**: All modules support (name, when, register, etc.)
- **Module-Specific Parameters**: Unique to each module
- **Return Values**: Consistent structure across modules

### Idempotency Best Practices
1. **Use Native Modules**: Prefer modules over shell/command
2. **Check Before Action**: Use stat, get_url with force=no
3. **Hash-Based Detection**: Compare content hashes for changes
4. **Conditional Logic**: Use when conditions appropriately
5. **State Management**: Always define desired end state

### Common Anti-Patterns
```yaml
# BAD: Always changes
- shell: echo "{{ ansible_date_time.iso8601 }}" > /tmp/timestamp

# GOOD: Only changes when needed
- copy:
    content: "Static content"
    dest: /tmp/file

# BAD: No change detection
- shell: wget http://example.com/file.tar.gz

# GOOD: Built-in change detection
- get_url:
    url: http://example.com/file.tar.gz
    dest: /tmp/file.tar.gz
```

### Error Handling in Modules
```yaml
# Ignore errors for optional operations
- package:
    name: optional-package
    state: present
  ignore_errors: yes

# Custom failure conditions
- shell: my-script.sh
  register: result
  failed_when: result.rc > 1

# Retry mechanisms
- uri:
    url: http://api.example.com/health
  register: health_check
  until: health_check.status == 200
  retries: 5
  delay: 10
```

This comprehensive module deep dive demonstrates how to leverage Ansible's powerful module system while maintaining idempotency for reliable, repeatable automation!
