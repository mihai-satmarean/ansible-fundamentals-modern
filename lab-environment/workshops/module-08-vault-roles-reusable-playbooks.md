# Module 8: Ansible Vault, Roles, and Building Reusable Playbooks

## Objective
Master Ansible Vault for secure data management, understand and create Ansible roles for code organization, and build reusable automation components for scalable infrastructure management.

## Prerequisites
- Solid understanding of Ansible playbooks and templates
- Experience with variables and inventory management
- Access to target hosts with appropriate privileges

## Understanding Core Concepts

### Ansible Vault
- **Purpose**: Encrypt sensitive data (passwords, keys, certificates)
- **Security**: AES256 encryption with password-based access
- **Integration**: Seamless use within playbooks and variables
- **Management**: Create, edit, view, and decrypt encrypted files

### Ansible Roles
- **Organization**: Structured way to organize playbooks, variables, templates, and files
- **Reusability**: Share and reuse automation code across projects
- **Modularity**: Break complex playbooks into manageable components
- **Standards**: Follow Ansible Galaxy directory structure

## Lab Setup

### Create Project Structure
```bash
mkdir -p ansible-vault-roles-lab
cd ansible-vault-roles-lab
mkdir -p {group_vars,host_vars,roles,playbooks,inventory}
```

### Create Inventory
Create `inventory/hosts.ini`:

```ini
[webservers]
web1 ansible_host=192.168.1.101 ansible_user=ansibleuser
web2 ansible_host=192.168.1.102 ansible_user=ansibleuser

[databases]
db1 ansible_host=192.168.1.103 ansible_user=ansibleuser

[loadbalancers]
lb1 ansible_host=192.168.1.104 ansible_user=ansibleuser

[production:children]
webservers
databases
loadbalancers

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

## Lab 1: Ansible Vault Fundamentals

### Create Encrypted Variables

```bash
# Create encrypted file for sensitive data
ansible-vault create group_vars/all/vault.yml
```

When prompted for password, use: `SecureVaultPassword123!`

Add this content to `vault.yml`:

```yaml
---
# Encrypted sensitive variables
vault_database_password: "SuperSecretDBPassword123!"
vault_api_key: "abc123def456ghi789jkl012"
vault_ssl_private_key_password: "SSLKeyPassword456!"
vault_admin_password: "AdminPassword789!"
vault_backup_encryption_key: "BackupKey321xyz"

# Database credentials
vault_db_users:
  - name: "webapp_user"
    password: "WebAppDBPass123!"
    privileges: "SELECT,INSERT,UPDATE,DELETE"
  - name: "readonly_user"  
    password: "ReadOnlyPass456!"
    privileges: "SELECT"

# API credentials
vault_external_apis:
  payment_gateway:
    api_key: "pg_live_abc123def456"
    secret_key: "pg_secret_xyz789"
  monitoring_service:
    token: "monitor_token_123456"
    webhook_secret: "webhook_secret_abc123"

# SSL certificates (base64 encoded content would go here)
vault_ssl_certificate: |
  -----BEGIN CERTIFICATE-----
  MIIDXTCCAkWgAwIBAgIJAKL0UG+/JwIcMA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
  [... certificate content ...]
  -----END CERTIFICATE-----

vault_ssl_private_key: |
  -----BEGIN PRIVATE KEY-----
  MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC7VJTUt9Us8cKB
  [... private key content ...]
  -----END PRIVATE KEY-----
```

### Create Public Variables

Create `group_vars/all/main.yml`:

```yaml
---
# Public variables that reference vault variables
database_password: "{{ vault_database_password }}"
api_key: "{{ vault_api_key }}"
ssl_private_key_password: "{{ vault_ssl_private_key_password }}"
admin_password: "{{ vault_admin_password }}"

# Application configuration
app_name: "secure-webapp"
app_version: "2.1.0"
environment: "production"

# Database configuration
database_host: "{{ groups['databases'][0] }}"
database_name: "{{ app_name }}_{{ environment }}"
database_users: "{{ vault_db_users }}"

# External service configuration
external_apis: "{{ vault_external_apis }}"

# SSL configuration
ssl_certificate: "{{ vault_ssl_certificate }}"
ssl_private_key: "{{ vault_ssl_private_key }}"
ssl_enabled: true

# Backup configuration
backup_enabled: true
backup_encryption_key: "{{ vault_backup_encryption_key }}"
backup_schedule: "0 2 * * *"  # Daily at 2 AM
```

### Create Vault Management Playbook

Create `playbooks/vault_demo.yml`:

```yaml
---
- name: Ansible Vault Demonstration
  hosts: webservers
  become: yes
  vars:
    temp_password_file: "/tmp/secure_passwords.txt"
    
  tasks:
    - name: "Display non-sensitive configuration"
      debug:
        msg: |
          === PUBLIC CONFIGURATION ===
          App Name: {{ app_name }}
          Version: {{ app_version }}
          Environment: {{ environment }}
          Database Host: {{ database_host }}
          Database Name: {{ database_name }}
          SSL Enabled: {{ ssl_enabled }}
          Backup Enabled: {{ backup_enabled }}
          
    - name: "Verify vault variables are accessible"
      debug:
        msg: |
          === VAULT VARIABLE ACCESS TEST ===
          Database password length: {{ database_password | length }} characters
          API key prefix: {{ api_key[:10] }}...
          Admin password complexity: {{ 'Strong' if admin_password | length > 10 else 'Weak' }}
          SSL certificate present: {{ ssl_certificate is defined and ssl_certificate | length > 100 }}
          
    - name: "Create secure configuration file"
      template:
        src: secure_config.j2
        dest: /etc/{{ app_name }}/secure.conf
        owner: root
        group: root
        mode: '0600'  # Restrictive permissions
        backup: yes
      register: secure_config
      
    - name: "Create database users configuration"
      copy:
        content: |
          # Database Users Configuration
          # Generated: {{ ansible_date_time.iso8601 }}
          
          {% for user in database_users %}
          [user_{{ user.name }}]
          username={{ user.name }}
          password_hash={{ user.password | password_hash('sha512') }}
          privileges={{ user.privileges }}
          
          {% endfor %}
        dest: /etc/{{ app_name }}/db_users.conf
        owner: root
        group: root
        mode: '0600'
      register: db_users_config
      
    - name: "Deploy SSL certificates"
      copy:
        content: "{{ ssl_certificate }}"
        dest: "/etc/ssl/certs/{{ app_name }}.crt"
        owner: root
        group: root
        mode: '0644'
      register: ssl_cert_deploy
      
    - name: "Deploy SSL private key"
      copy:
        content: "{{ ssl_private_key }}"
        dest: "/etc/ssl/private/{{ app_name }}.key"
        owner: root
        group: ssl-cert
        mode: '0640'
      register: ssl_key_deploy
      
    - name: "Test external API connectivity"
      uri:
        url: "https://httpbin.org/headers"
        method: GET
        headers:
          Authorization: "Bearer {{ external_apis.monitoring_service.token }}"
        return_content: yes
      register: api_test
      ignore_errors: yes
      
    - name: "Display vault usage results"
      debug:
        msg: |
          === VAULT USAGE RESULTS ===
          
          Secure Config: {{ 'Created' if secure_config.changed else 'Already exists' }}
          DB Users Config: {{ 'Created' if db_users_config.changed else 'Already exists' }}
          SSL Certificate: {{ 'Deployed' if ssl_cert_deploy.changed else 'Already exists' }}
          SSL Private Key: {{ 'Deployed' if ssl_key_deploy.changed else 'Already exists' }}
          
          API Test: {{ 'Success' if api_test.status == 200 else 'Failed' }}
          
          Files created with restricted permissions:
          - /etc/{{ app_name }}/secure.conf (600)
          - /etc/{{ app_name }}/db_users.conf (600)
          - /etc/ssl/private/{{ app_name }}.key (640)
```

### Create Secure Configuration Template

Create `templates/secure_config.j2`:

```ini
# Secure Configuration for {{ app_name | title }}
# Generated: {{ ansible_date_time.iso8601 }}
# WARNING: This file contains sensitive information

[database]
host={{ database_host }}
name={{ database_name }}
password={{ database_password }}

[api_keys]
main_api_key={{ api_key }}
payment_gateway_key={{ external_apis.payment_gateway.api_key }}
payment_gateway_secret={{ external_apis.payment_gateway.secret_key }}
monitoring_token={{ external_apis.monitoring_service.token }}

[ssl]
certificate_path=/etc/ssl/certs/{{ app_name }}.crt
private_key_path=/etc/ssl/private/{{ app_name }}.key
private_key_password={{ ssl_private_key_password }}

[backup]
enabled={{ backup_enabled | lower }}
encryption_key={{ backup_encryption_key }}
schedule={{ backup_schedule }}

[security]
admin_password_hash={{ admin_password | password_hash('sha512') }}
session_secret={{ api_key | hash('md5') }}
```

## Lab 2: Creating Ansible Roles

### Create NGINX Role Structure

```bash
# Create role directory structure
ansible-galaxy init roles/nginx_server
```

This creates:
```
roles/nginx_server/
├── defaults/main.yml
├── files/
├── handlers/main.yml
├── meta/main.yml
├── tasks/main.yml
├── templates/
├── tests/
└── vars/main.yml
```

### Configure NGINX Role

Edit `roles/nginx_server/defaults/main.yml`:

```yaml
---
# Default variables for nginx_server role
nginx_server_name: "{{ ansible_fqdn }}"
nginx_port: 80
nginx_ssl_port: 443
nginx_ssl_enabled: false
nginx_worker_processes: "{{ ansible_processor_vcpus }}"
nginx_worker_connections: 1024
nginx_keepalive_timeout: 65
nginx_client_max_body_size: "64M"

# Document root and index files
nginx_document_root: "/var/www/html"
nginx_index_files: "index.html index.htm"

# Logging
nginx_access_log: "/var/log/nginx/access.log"
nginx_error_log: "/var/log/nginx/error.log"
nginx_log_level: "warn"

# Security headers
nginx_security_headers:
  - "X-Frame-Options DENY"
  - "X-Content-Type-Options nosniff"
  - "X-XSS-Protection '1; mode=block'"
  - "Referrer-Policy strict-origin-when-cross-origin"

# Rate limiting
nginx_rate_limiting_enabled: false
nginx_rate_limit: "10r/s"
nginx_rate_burst: 20

# Gzip compression
nginx_gzip_enabled: true
nginx_gzip_types:
  - "text/plain"
  - "text/css"
  - "text/xml"
  - "text/javascript"
  - "application/javascript"
  - "application/xml+rss"
  - "application/json"

# Virtual hosts
nginx_virtual_hosts: []
# Example:
# nginx_virtual_hosts:
#   - name: "example.com"
#     port: 80
#     document_root: "/var/www/example.com"
#     ssl_enabled: false
```

Edit `roles/nginx_server/vars/main.yml`:

```yaml
---
# Variables that shouldn't be overridden
nginx_config_path: "/etc/nginx"
nginx_sites_available: "{{ nginx_config_path }}/sites-available"
nginx_sites_enabled: "{{ nginx_config_path }}/sites-enabled"
nginx_user: "nginx"
nginx_group: "nginx"

# OS-specific package names
nginx_package_name: "nginx"
nginx_service_name: "nginx"

# SSL paths
nginx_ssl_cert_path: "/etc/ssl/certs"
nginx_ssl_key_path: "/etc/ssl/private"
```

Edit `roles/nginx_server/tasks/main.yml`:

```yaml
---
# Main tasks for nginx_server role
- name: "Include OS-specific variables"
  include_vars: "{{ ansible_os_family }}.yml"
  ignore_errors: yes

- name: "Install NGINX package"
  package:
    name: "{{ nginx_package_name }}"
    state: present
  register: nginx_install

- name: "Ensure NGINX user exists"
  user:
    name: "{{ nginx_user }}"
    system: yes
    shell: "/bin/false"
    home: "/var/cache/nginx"
    create_home: no
  when: ansible_os_family == "RedHat"

- name: "Create NGINX directories"
  file:
    path: "{{ item }}"
    state: directory
    owner: root
    group: root
    mode: '0755'
  loop:
    - "{{ nginx_sites_available }}"
    - "{{ nginx_sites_enabled }}"
    - "{{ nginx_document_root }}"
    - "/var/log/nginx"

- name: "Deploy main NGINX configuration"
  template:
    src: nginx.conf.j2
    dest: "{{ nginx_config_path }}/nginx.conf"
    owner: root
    group: root
    mode: '0644'
    backup: yes
    validate: 'nginx -t -c %s'
  notify: restart nginx
  register: nginx_main_config

- name: "Deploy default virtual host"
  template:
    src: default_vhost.j2
    dest: "{{ nginx_sites_available }}/default"
    owner: root
    group: root
    mode: '0644'
  notify: restart nginx

- name: "Enable default virtual host"
  file:
    src: "{{ nginx_sites_available }}/default"
    dest: "{{ nginx_sites_enabled }}/default"
    state: link
  notify: restart nginx

- name: "Deploy custom virtual hosts"
  template:
    src: vhost.j2
    dest: "{{ nginx_sites_available }}/{{ item.name }}"
    owner: root
    group: root
    mode: '0644'
  loop: "{{ nginx_virtual_hosts }}"
  notify: restart nginx
  register: custom_vhosts

- name: "Enable custom virtual hosts"
  file:
    src: "{{ nginx_sites_available }}/{{ item.name }}"
    dest: "{{ nginx_sites_enabled }}/{{ item.name }}"
    state: link
  loop: "{{ nginx_virtual_hosts }}"
  when: item.enabled | default(true)
  notify: restart nginx

- name: "Create document root directories for virtual hosts"
  file:
    path: "{{ item.document_root }}"
    state: directory
    owner: "{{ nginx_user }}"
    group: "{{ nginx_group }}"
    mode: '0755'
  loop: "{{ nginx_virtual_hosts }}"
  when: item.document_root is defined

- name: "Deploy SSL certificates"
  copy:
    content: "{{ item.ssl_certificate }}"
    dest: "{{ nginx_ssl_cert_path }}/{{ item.name }}.crt"
    owner: root
    group: root
    mode: '0644'
  loop: "{{ nginx_virtual_hosts }}"
  when: 
    - item.ssl_enabled | default(false)
    - item.ssl_certificate is defined
  notify: restart nginx

- name: "Deploy SSL private keys"
  copy:
    content: "{{ item.ssl_private_key }}"
    dest: "{{ nginx_ssl_key_path }}/{{ item.name }}.key"
    owner: root
    group: "ssl-cert"
    mode: '0640'
  loop: "{{ nginx_virtual_hosts }}"
  when: 
    - item.ssl_enabled | default(false)
    - item.ssl_private_key is defined
  notify: restart nginx

- name: "Start and enable NGINX service"
  service:
    name: "{{ nginx_service_name }}"
    state: started
    enabled: yes
  register: nginx_service

- name: "Verify NGINX configuration"
  command: nginx -t
  register: nginx_config_test
  changed_when: false
  failed_when: nginx_config_test.rc != 0

- name: "Display NGINX role results"
  debug:
    msg: |
      === NGINX ROLE DEPLOYMENT RESULTS ===
      
      Installation: {{ 'Completed' if nginx_install.changed else 'Already installed' }}
      Configuration: {{ 'Updated' if nginx_main_config.changed else 'Current' }}
      Service: {{ 'Started' if nginx_service.changed else 'Already running' }}
      Config Test: {{ 'PASSED' if nginx_config_test.rc == 0 else 'FAILED' }}
      
      Virtual Hosts: {{ nginx_virtual_hosts | length }}
      SSL Enabled: {{ nginx_virtual_hosts | selectattr('ssl_enabled', 'defined') | selectattr('ssl_enabled') | list | length }}
      
      Access URLs:
      - Main site: http://{{ ansible_default_ipv4.address }}:{{ nginx_port }}
      {% for vhost in nginx_virtual_hosts %}
      - {{ vhost.name }}: http://{{ ansible_default_ipv4.address }}:{{ vhost.port | default(nginx_port) }}
      {% endfor %}
```

Edit `roles/nginx_server/handlers/main.yml`:

```yaml
---
# Handlers for nginx_server role
- name: restart nginx
  service:
    name: "{{ nginx_service_name }}"
    state: restarted
  listen: "restart nginx"

- name: reload nginx
  service:
    name: "{{ nginx_service_name }}"
    state: reloaded
  listen: "reload nginx"

- name: validate nginx config
  command: nginx -t
  listen: "validate nginx config"
```

### Create NGINX Templates

Create `roles/nginx_server/templates/nginx.conf.j2`:

```nginx
# NGINX Configuration
# Generated by Ansible on {{ ansible_date_time.iso8601 }}

user {{ nginx_user }};
worker_processes {{ nginx_worker_processes }};
pid /var/run/nginx.pid;

events {
    worker_connections {{ nginx_worker_connections }};
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log {{ nginx_access_log }} main;
    error_log {{ nginx_error_log }} {{ nginx_log_level }};

    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout {{ nginx_keepalive_timeout }};
    types_hash_max_size 2048;
    client_max_body_size {{ nginx_client_max_body_size }};

    # Security
    server_tokens off;
    
    {% if nginx_gzip_enabled %}
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        {% for type in nginx_gzip_types %}
        {{ type }}{% if not loop.last %}{% endif %}
        {% endfor %};
    {% endif %}

    {% if nginx_rate_limiting_enabled %}
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate={{ nginx_rate_limit }};
    {% endif %}

    # Virtual hosts
    include {{ nginx_sites_enabled }}/*;
}
```

Create `roles/nginx_server/templates/default_vhost.j2`:

```nginx
# Default Virtual Host
server {
    listen {{ nginx_port }} default_server;
    listen [::]:{{ nginx_port }} default_server;
    
    {% if nginx_ssl_enabled %}
    listen {{ nginx_ssl_port }} ssl http2 default_server;
    listen [::]:{{ nginx_ssl_port }} ssl http2 default_server;
    {% endif %}

    server_name {{ nginx_server_name }} _;
    root {{ nginx_document_root }};
    index {{ nginx_index_files }};

    {% if nginx_ssl_enabled %}
    # SSL Configuration
    ssl_certificate {{ nginx_ssl_cert_path }}/{{ nginx_server_name }}.crt;
    ssl_certificate_key {{ nginx_ssl_key_path }}/{{ nginx_server_name }}.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    {% endif %}

    # Security headers
    {% for header in nginx_security_headers %}
    add_header {{ header }};
    {% endfor %}

    location / {
        try_files $uri $uri/ =404;
        
        {% if nginx_rate_limiting_enabled %}
        limit_req zone=api burst={{ nginx_rate_burst }} nodelay;
        {% endif %}
    }

    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
```

### Create Load Balancer Role

```bash
# Create load balancer role
ansible-galaxy init roles/load_balancer
```

Edit `roles/load_balancer/defaults/main.yml`:

```yaml
---
# Load balancer configuration
lb_algorithm: "round_robin"  # round_robin, least_conn, ip_hash
lb_port: 80
lb_ssl_port: 443
lb_ssl_enabled: false

# Backend servers
lb_backend_servers: []
# Example:
# lb_backend_servers:
#   - name: "web1"
#     address: "192.168.1.101"
#     port: 80
#     weight: 1
#     backup: false

# Health checks
lb_health_check_enabled: true
lb_health_check_path: "/health"
lb_health_check_interval: "30s"
lb_health_check_timeout: "5s"

# Session persistence
lb_session_persistence: false
lb_session_cookie: "SERVERID"
```

Edit `roles/load_balancer/tasks/main.yml`:

```yaml
---
# Load balancer role tasks
- name: "Install NGINX for load balancing"
  package:
    name: nginx
    state: present

- name: "Deploy load balancer configuration"
  template:
    src: load_balancer.conf.j2
    dest: "/etc/nginx/conf.d/load_balancer.conf"
    owner: root
    group: root
    mode: '0644'
    backup: yes
    validate: 'nginx -t'
  notify: restart nginx

- name: "Remove default NGINX site"
  file:
    path: "/etc/nginx/sites-enabled/default"
    state: absent
  notify: restart nginx

- name: "Start and enable NGINX"
  service:
    name: nginx
    state: started
    enabled: yes

- name: "Display load balancer configuration"
  debug:
    msg: |
      === LOAD BALANCER CONFIGURATION ===
      
      Algorithm: {{ lb_algorithm }}
      Frontend Port: {{ lb_port }}
      SSL Enabled: {{ lb_ssl_enabled }}
      
      Backend Servers:
      {% for server in lb_backend_servers %}
      - {{ server.name }}: {{ server.address }}:{{ server.port }} (weight: {{ server.weight | default(1) }})
      {% endfor %}
      
      Health Checks: {{ 'Enabled' if lb_health_check_enabled else 'Disabled' }}
```

Create `roles/load_balancer/templates/load_balancer.conf.j2`:

```nginx
# Load Balancer Configuration
# Generated by Ansible

upstream backend {
    {% if lb_algorithm == 'least_conn' %}
    least_conn;
    {% elif lb_algorithm == 'ip_hash' %}
    ip_hash;
    {% endif %}
    
    {% for server in lb_backend_servers %}
    server {{ server.address }}:{{ server.port }}{% if server.weight is defined %} weight={{ server.weight }}{% endif %}{% if server.backup | default(false) %} backup{% endif %};
    {% endfor %}
    
    {% if lb_health_check_enabled %}
    # Health check configuration would go here
    {% endif %}
}

server {
    listen {{ lb_port }};
    {% if lb_ssl_enabled %}
    listen {{ lb_ssl_port }} ssl http2;
    {% endif %}
    
    server_name _;

    {% if lb_ssl_enabled %}
    # SSL configuration
    ssl_certificate /etc/ssl/certs/loadbalancer.crt;
    ssl_certificate_key /etc/ssl/private/loadbalancer.key;
    {% endif %}

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Connection settings
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        {% if lb_session_persistence %}
        # Session persistence
        proxy_cookie_path / "/; HttpOnly; Secure";
        {% endif %}
    }

    {% if lb_health_check_enabled %}
    location {{ lb_health_check_path }} {
        access_log off;
        return 200 "Load balancer healthy\n";
        add_header Content-Type text/plain;
    }
    {% endif %}
}
```

Edit `roles/load_balancer/handlers/main.yml`:

```yaml
---
- name: restart nginx
  service:
    name: nginx
    state: restarted
```

## Lab 3: Using Roles in Playbooks

### Create Role-Based Playbook

Create `playbooks/deploy_infrastructure.yml`:

```yaml
---
- name: Deploy Web Infrastructure with Roles
  hosts: all
  become: yes
  vars:
    # Global variables
    environment: "production"
    ssl_enabled: true
    
  tasks:
    - name: "Update system packages"
      package:
        name: "*"
        state: latest
      when: ansible_os_family == "RedHat"
      
    - name: "Update system packages (Debian)"
      apt:
        upgrade: dist
        update_cache: yes
      when: ansible_os_family == "Debian"

- name: Deploy Web Servers
  hosts: webservers
  become: yes
  vars:
    # NGINX configuration
    nginx_virtual_hosts:
      - name: "webapp.local"
        port: 80
        ssl_enabled: "{{ ssl_enabled }}"
        document_root: "/var/www/webapp"
        ssl_certificate: "{{ vault_ssl_certificate }}"
        ssl_private_key: "{{ vault_ssl_private_key }}"
      - name: "api.local"
        port: 8080
        ssl_enabled: false
        document_root: "/var/www/api"
        
  roles:
    - role: nginx_server
      nginx_ssl_enabled: "{{ ssl_enabled }}"
      nginx_worker_processes: "{{ ansible_processor_vcpus * 2 }}"
      nginx_worker_connections: "{{ (ansible_memtotal_mb * 10) | int }}"
      
  post_tasks:
    - name: "Deploy application files"
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head><title>{{ item.name | title }}</title></head>
          <body>
            <h1>Welcome to {{ item.name | title }}</h1>
            <p>Server: {{ ansible_hostname }}</p>
            <p>Environment: {{ environment }}</p>
            <p>SSL: {{ item.ssl_enabled | ternary('Enabled', 'Disabled') }}</p>
          </body>
          </html>
        dest: "{{ item.document_root }}/index.html"
        owner: nginx
        group: nginx
        mode: '0644'
      loop: "{{ nginx_virtual_hosts }}"

- name: Deploy Load Balancer
  hosts: loadbalancers
  become: yes
  vars:
    lb_backend_servers:
      - name: "web1"
        address: "{{ hostvars[groups['webservers'][0]]['ansible_default_ipv4']['address'] }}"
        port: 80
        weight: 1
      - name: "web2"
        address: "{{ hostvars[groups['webservers'][1]]['ansible_default_ipv4']['address'] }}"
        port: 80
        weight: 1
        
  roles:
    - role: load_balancer
      lb_algorithm: "round_robin"
      lb_ssl_enabled: "{{ ssl_enabled }}"
      lb_health_check_enabled: true

- name: Final Infrastructure Verification
  hosts: all
  become: yes
  tasks:
    - name: "Verify services are running"
      service:
        name: nginx
        state: started
      register: service_check
      
    - name: "Test HTTP connectivity"
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:80/health"
        method: GET
      register: http_test
      ignore_errors: yes
      
    - name: "Display final results"
      debug:
        msg: |
          === INFRASTRUCTURE DEPLOYMENT COMPLETE ===
          
          Host: {{ inventory_hostname }}
          Role: {{ group_names | join(', ') }}
          Service Status: {{ 'Running' if service_check.state == 'started' else 'Failed' }}
          HTTP Test: {{ 'Success' if http_test.status == 200 else 'Failed' }}
          
          {% if 'webservers' in group_names %}
          Web Server URLs:
          {% for vhost in nginx_virtual_hosts | default([]) %}
          - http://{{ ansible_default_ipv4.address }}:{{ vhost.port }}/
          {% endfor %}
          {% endif %}
          
          {% if 'loadbalancers' in group_names %}
          Load Balancer: http://{{ ansible_default_ipv4.address }}:{{ lb_port }}/
          Backend Servers: {{ lb_backend_servers | length }}
          {% endif %}
```

## Running the Labs

### Execute Vault Operations

```bash
# List encrypted files
ansible-vault view group_vars/all/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/all/vault.yml

# Run playbook with vault
ansible-playbook -i inventory/hosts.ini playbooks/vault_demo.yml --ask-vault-pass

# Use vault password file (create .vault_pass with your password)
echo "SecureVaultPassword123!" > .vault_pass
ansible-playbook -i inventory/hosts.ini playbooks/vault_demo.yml --vault-password-file .vault_pass
```

### Execute Role-Based Deployment

```bash
# Deploy complete infrastructure using roles
ansible-playbook -i inventory/hosts.ini playbooks/deploy_infrastructure.yml --ask-vault-pass

# Run specific roles only
ansible-playbook -i inventory/hosts.ini playbooks/deploy_infrastructure.yml --tags "nginx" --ask-vault-pass
```

### Test Role Reusability

```bash
# Create different environment
cp group_vars/all/main.yml group_vars/staging.yml
# Edit staging.yml with different values

# Deploy to staging
ansible-playbook -i inventory/hosts.ini playbooks/deploy_infrastructure.yml -e "environment=staging" --ask-vault-pass
```

## Key Learning Points

### Ansible Vault Best Practices
1. **Separate Vault Files**: Keep encrypted data in separate files
2. **Reference Variables**: Use vault variables in public files
3. **Descriptive Names**: Prefix vault variables with `vault_`
4. **Password Management**: Use password files or environment variables
5. **File Permissions**: Protect vault password files (600)

### Role Design Principles
1. **Single Responsibility**: Each role should have one clear purpose
2. **Parameterization**: Use variables for customization
3. **Idempotency**: All tasks should be idempotent
4. **Documentation**: Include README and meta information
5. **Testing**: Include test scenarios and validation

### Role Structure Best Practices
- **defaults/**: Default variable values (lowest precedence)
- **vars/**: Role-specific variables (high precedence)
- **tasks/**: Main automation logic
- **handlers/**: Event-driven tasks
- **templates/**: Dynamic configuration files
- **files/**: Static files to be copied
- **meta/**: Role metadata and dependencies

### Security Considerations
1. **Vault Encryption**: Always encrypt sensitive data
2. **File Permissions**: Set appropriate permissions on sensitive files
3. **Access Control**: Limit vault password access
4. **Audit Trail**: Track vault file changes
5. **Key Rotation**: Regularly update encrypted passwords

This comprehensive lab demonstrates how to build secure, reusable automation components using Ansible Vault and Roles for enterprise-grade infrastructure management!
