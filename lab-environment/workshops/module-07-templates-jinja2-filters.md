# Module 7: Templates, Jinja2, and Filters

## Objective
Master Ansible templating using Jinja2, learn to use filters for data transformation, and create dynamic configurations that adapt to different environments and system characteristics.

## Prerequisites
- Understanding of Ansible basics and variables
- Familiarity with YAML syntax
- Access to target hosts with web server capabilities

## Understanding Jinja2 Templating

### What is Jinja2?
- **Template Engine**: Powerful and flexible templating language
- **Dynamic Content**: Generate files based on variables and logic
- **Ansible Integration**: Native support for Jinja2 templates
- **Syntax**: Uses `{{ }}` for variables, `{% %}` for logic, `{# #}` for comments

### Template Components
1. **Variables**: `{{ variable_name }}`
2. **Expressions**: `{{ variable | filter }}`
3. **Control Structures**: `{% if %} {% for %} {% endif %}`
4. **Comments**: `{# This is a comment #}`

## Lab Setup

### Create Inventory
Create `hosts.ini`:

```ini
[webservers]
web1 ansible_host=192.168.1.101 ansible_user=ansibleuser http_port=80 ssl_enabled=true
web2 ansible_host=192.168.1.102 ansible_user=ansibleuser http_port=8080 ssl_enabled=false

[databases]
db1 ansible_host=192.168.1.103 ansible_user=ansibleuser db_type=postgresql

[webservers:vars]
server_role=web
max_connections=1000

[databases:vars]
server_role=database
max_connections=500

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
environment=production
admin_email=admin@company.com
```

### Create Templates Directory
```bash
mkdir -p templates
```

## Lab 1: Basic Template Usage

### Create Basic Template

Create `templates/index.html.j2`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to {{ server_name | default('Our Web Server') }}</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background-color: #f5f5f5;
        }
        .container { 
            background: white; 
            padding: 30px; 
            border-radius: 10px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .info-box { 
            background: #e3f2fd; 
            padding: 15px; 
            margin: 15px 0; 
            border-left: 4px solid #2196f3; 
        }
        .success { background-color: #d4edda; border-color: #28a745; }
        .warning { background-color: #fff3cd; border-color: #ffc107; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hello from {{ server_name | default('Our Web Server') | title }}!</h1>
        
        <div class="info-box">
            <h3>Server Information</h3>
            <p><strong>Hostname:</strong> {{ ansible_hostname }}</p>
            <p><strong>FQDN:</strong> {{ ansible_fqdn }}</p>
            <p><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</p>
            <p><strong>Operating System:</strong> {{ ansible_distribution }} {{ ansible_distribution_version }}</p>
            <p><strong>Architecture:</strong> {{ ansible_architecture }}</p>
            <p><strong>Server Time:</strong> {{ ansible_date_time.iso8601 }}</p>
        </div>
        
        <div class="info-box success">
            <h3>Application Information</h3>
            <p><strong>Environment:</strong> {{ environment | upper }}</p>
            <p><strong>Server Role:</strong> {{ server_role | title }}</p>
            <p><strong>HTTP Port:</strong> {{ http_port | default(80) }}</p>
            <p><strong>SSL Enabled:</strong> {{ ssl_enabled | default(false) | ternary('Yes', 'No') }}</p>
        </div>
        
        {% if custom_message %}
        <div class="info-box warning">
            <h3>Custom Message</h3>
            <p>{{ custom_message }}</p>
        </div>
        {% endif %}
        
        <div class="info-box">
            <h3>System Resources</h3>
            <p><strong>CPU Cores:</strong> {{ ansible_processor_vcpus }}</p>
            <p><strong>Memory:</strong> {{ (ansible_memtotal_mb / 1024) | round(1) }} GB</p>
            <p><strong>Disk Usage (root):</strong> 
                {% for mount in ansible_mounts %}
                    {% if mount.mount == '/' %}
                        {{ ((mount.size_total - mount.size_available) / mount.size_total * 100) | round(1) }}% used
                    {% endif %}
                {% endfor %}
            </p>
        </div>
    </div>
</body>
</html>
```

### Create Basic Template Playbook

Create `basic_templates.yml`:

```yaml
---
- name: Basic Jinja2 Template Usage
  hosts: webservers
  become: yes
  vars:
    server_name: "{{ inventory_hostname }}"
    custom_message: "This server is managed by Ansible automation"
    
  tasks:
    - name: "Install NGINX web server"
      package:
        name: nginx
        state: present
        
    - name: "Start and enable NGINX"
      service:
        name: nginx
        state: started
        enabled: yes
        
    - name: "Deploy templated index.html"
      template:
        src: index.html.j2
        dest: /var/www/html/index.html
        owner: www-data
        group: www-data
        mode: '0644'
        backup: yes
      register: template_deploy
      
    - name: "Display template deployment result"
      debug:
        msg: |
          Template deployed: {{ template_deploy.changed }}
          {% if template_deploy.backup_file is defined %}
          Backup created: {{ template_deploy.backup_file }}
          {% endif %}
          Server URL: http://{{ ansible_default_ipv4.address }}:{{ http_port | default(80) }}
```

## Lab 2: Advanced Templates with Filters

### Create Advanced NGINX Configuration Template

Create `templates/nginx_advanced.conf.j2`:

```nginx
{# Advanced NGINX Configuration Template #}
{# Generated by Ansible on {{ ansible_date_time.iso8601 }} #}

user nginx;
worker_processes {{ ansible_processor_vcpus }};
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections {{ (ansible_memtotal_mb * 10) | int }};
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging format
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout {{ 65 if ansible_memtotal_mb > 1024 else 30 }};
    types_hash_max_size 2048;
    
    # Server tokens
    server_tokens {{ 'off' if environment == 'production' else 'on' }};

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level {{ 6 if ansible_processor_vcpus >= 2 else 4 }};
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    # Rate limiting
    {% if environment == 'production' %}
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
    {% endif %}

    # SSL settings (if SSL is enabled)
    {% if ssl_enabled | default(false) %}
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    {% endif %}

    # Virtual Host Configuration
    server {
        listen {{ http_port | default(80) }};
        {% if ssl_enabled | default(false) %}
        listen {{ https_port | default(443) }} ssl http2;
        ssl_certificate /etc/ssl/certs/{{ inventory_hostname }}.crt;
        ssl_certificate_key /etc/ssl/private/{{ inventory_hostname }}.key;
        {% endif %}
        
        server_name {{ ansible_fqdn }} {{ ansible_hostname }};
        root /var/www/html;
        index index.html index.htm;

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        {% if ssl_enabled | default(false) %}
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        {% endif %}

        # Main location
        location / {
            try_files $uri $uri/ =404;
            
            {% if environment == 'production' %}
            # Rate limiting for production
            limit_req zone=api burst=20 nodelay;
            {% endif %}
        }

        # Static file caching
        location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2)$ {
            expires {{ '1y' if environment == 'production' else '1h' }};
            add_header Cache-Control "public, immutable";
        }

        # API endpoint (if applicable)
        {% if server_role == 'web' and 'api' in group_names | default([]) %}
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Rate limiting for API
            limit_req zone=api burst=10 nodelay;
        }
        {% endif %}

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # Deny access to sensitive files
        location ~ /\.(ht|git|svn) {
            deny all;
        }

        # Custom error pages
        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }
    }

    # Upstream servers (if load balancing)
    {% if groups['webservers'] | length > 1 %}
    upstream backend {
        {% for host in groups['webservers'] %}
        {% if host != inventory_hostname %}
        server {{ hostvars[host]['ansible_default_ipv4']['address'] }}:{{ hostvars[host]['http_port'] | default(80) }};
        {% endif %}
        {% endfor %}
    }
    {% endif %}
}
```

### Create Filter Demonstration Template

Create `templates/filter_demo.html.j2`:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Jinja2 Filters Demonstration</title>
    <style>
        body { font-family: monospace; margin: 20px; }
        .filter-example { 
            background: #f0f0f0; 
            padding: 10px; 
            margin: 10px 0; 
            border-left: 3px solid #007acc; 
        }
        .original { color: #666; }
        .result { color: #007acc; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Jinja2 Filters Demonstration</h1>
    
    <h2>String Filters</h2>
    <div class="filter-example">
        <div class="original">Original: {{ server_name | default('example server') }}</div>
        <div class="result">Capitalize: {{ server_name | default('example server') | capitalize }}</div>
        <div class="result">Title: {{ server_name | default('example server') | title }}</div>
        <div class="result">Upper: {{ server_name | default('example server') | upper }}</div>
        <div class="result">Lower: {{ server_name | default('example server') | lower }}</div>
    </div>
    
    <h2>Number Filters</h2>
    <div class="filter-example">
        <div class="original">Memory MB: {{ ansible_memtotal_mb }}</div>
        <div class="result">Memory GB (rounded): {{ (ansible_memtotal_mb / 1024) | round(2) }}</div>
        <div class="result">Memory GB (int): {{ (ansible_memtotal_mb / 1024) | int }}</div>
        <div class="result">Random number (1-100): {{ 100 | random }}</div>
        <div class="result">Absolute value: {{ -42 | abs }}</div>
    </div>
    
    <h2>List Filters</h2>
    <div class="filter-example">
        <div class="original">Network interfaces: {{ ansible_interfaces }}</div>
        <div class="result">First interface: {{ ansible_interfaces | first }}</div>
        <div class="result">Last interface: {{ ansible_interfaces | last }}</div>
        <div class="result">Interface count: {{ ansible_interfaces | length }}</div>
        <div class="result">Joined: {{ ansible_interfaces | join(', ') }}</div>
        <div class="result">Sorted: {{ ansible_interfaces | sort | join(', ') }}</div>
        <div class="result">Unique: {{ ansible_interfaces | unique | join(', ') }}</div>
    </div>
    
    <h2>Date/Time Filters</h2>
    <div class="filter-example">
        <div class="original">Current datetime: {{ ansible_date_time.iso8601 }}</div>
        <div class="result">Date only: {{ ansible_date_time.date }}</div>
        <div class="result">Time only: {{ ansible_date_time.time }}</div>
        <div class="result">Epoch: {{ ansible_date_time.epoch }}</div>
        <div class="result">Custom format: {{ ansible_date_time.iso8601 | strftime('%B %d, %Y at %I:%M %p') }}</div>
    </div>
    
    <h2>IP Address Filters</h2>
    <div class="filter-example">
        <div class="original">IP Address: {{ ansible_default_ipv4.address }}</div>
        <div class="result">Network: {{ ansible_default_ipv4.address | ipaddr('network') }}</div>
        <div class="result">Netmask: {{ ansible_default_ipv4.address | ipaddr('netmask') }}</div>
        <div class="result">Reversed: {{ ansible_default_ipv4.address | reverse }}</div>
    </div>
    
    <h2>Hash and Encoding Filters</h2>
    <div class="filter-example">
        <div class="original">Server name: {{ server_name | default('example') }}</div>
        <div class="result">MD5 hash: {{ server_name | default('example') | hash('md5') }}</div>
        <div class="result">SHA256 hash: {{ server_name | default('example') | hash('sha256') }}</div>
        <div class="result">Base64 encode: {{ server_name | default('example') | b64encode }}</div>
        <div class="result">URL encode: {{ server_name | default('example server') | urlencode }}</div>
    </div>
    
    <h2>Conditional Filters</h2>
    <div class="filter-example">
        <div class="original">SSL Enabled: {{ ssl_enabled | default(false) }}</div>
        <div class="result">Ternary: {{ ssl_enabled | default(false) | ternary('HTTPS', 'HTTP') }}</div>
        <div class="result">Default value: {{ undefined_var | default('Default Value') }}</div>
        <div class="result">Bool filter: {{ ssl_enabled | default(false) | bool }}</div>
    </div>
    
    <h2>Custom Logic Filters</h2>
    <div class="filter-example">
        <div class="original">Memory: {{ ansible_memtotal_mb }} MB</div>
        <div class="result">Performance class: {{ 
            'High' if ansible_memtotal_mb > 4096 else 
            'Medium' if ansible_memtotal_mb > 2048 else 
            'Low' 
        }}</div>
        <div class="result">CPU class: {{ 
            'Multi-core' if ansible_processor_vcpus > 1 else 'Single-core' 
        }}</div>
    </div>
    
    <h2>File and Path Filters</h2>
    <div class="filter-example">
        <div class="original">Example path: /etc/nginx/nginx.conf</div>
        <div class="result">Basename: {{ '/etc/nginx/nginx.conf' | basename }}</div>
        <div class="result">Dirname: {{ '/etc/nginx/nginx.conf' | dirname }}</div>
        <div class="result">Extension: {{ '/etc/nginx/nginx.conf' | splitext | last }}</div>
    </div>
    
    <h2>JSON and Data Filters</h2>
    <div class="filter-example">
        <div class="original">System info object:</div>
        <div class="result">Pretty JSON: 
            <pre>{{ {
                'hostname': ansible_hostname,
                'os': ansible_distribution,
                'memory_gb': (ansible_memtotal_mb / 1024) | round(1),
                'cpu_count': ansible_processor_vcpus
            } | to_nice_json }}</pre>
        </div>
    </div>
</body>
</html>
```

### Create Advanced Templates Playbook

Create `advanced_templates.yml`:

```yaml
---
- name: Advanced Jinja2 Templates and Filters
  hosts: webservers
  become: yes
  vars:
    server_name: "{{ inventory_hostname | replace('.', '-') }}"
    https_port: 443
    
  tasks:
    - name: "Ensure NGINX is installed and running"
      package:
        name: nginx
        state: present
      notify: start nginx
      
    - name: "Deploy advanced NGINX configuration"
      template:
        src: nginx_advanced.conf.j2
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
        backup: yes
        validate: 'nginx -t -c %s'
      register: nginx_config
      notify: restart nginx
      
    - name: "Deploy filter demonstration page"
      template:
        src: filter_demo.html.j2
        dest: /var/www/html/filters.html
        owner: www-data
        group: www-data
        mode: '0644'
      register: filter_demo
      
    - name: "Create SSL certificates (self-signed for demo)"
      shell: |
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/{{ inventory_hostname }}.key \
        -out /etc/ssl/certs/{{ inventory_hostname }}.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN={{ inventory_hostname }}"
      args:
        creates: "/etc/ssl/certs/{{ inventory_hostname }}.crt"
      when: ssl_enabled | default(false)
      notify: restart nginx
      
    - name: "Display template results"
      debug:
        msg: |
          === TEMPLATE DEPLOYMENT RESULTS ===
          
          NGINX Configuration:
          - Updated: {{ nginx_config.changed }}
          - Backup: {{ nginx_config.backup_file | default('None') }}
          
          Filter Demo Page:
          - Deployed: {{ filter_demo.changed }}
          
          Access URLs:
          - Main page: http://{{ ansible_default_ipv4.address }}:{{ http_port | default(80) }}
          - Filters demo: http://{{ ansible_default_ipv4.address }}:{{ http_port | default(80) }}/filters.html
          {% if ssl_enabled | default(false) %}
          - HTTPS: https://{{ ansible_default_ipv4.address }}:{{ https_port }}
          {% endif %}
          
  handlers:
    - name: start nginx
      service:
        name: nginx
        state: started
        enabled: yes
        
    - name: restart nginx
      service:
        name: nginx
        state: restarted
```

## Lab 3: Complex Templates with Loops and Conditions

### Create Multi-Service Configuration Template

Create `templates/multi_service.conf.j2`:

```ini
{# Multi-Service Configuration Template #}
{# Demonstrates complex Jinja2 logic #}

# Configuration for {{ inventory_hostname }}
# Generated on {{ ansible_date_time.iso8601 }}
# Environment: {{ environment | upper }}

[global]
hostname = {{ ansible_hostname }}
fqdn = {{ ansible_fqdn }}
environment = {{ environment }}
admin_email = {{ admin_email }}

# System information
os_family = {{ ansible_os_family }}
distribution = {{ ansible_distribution }} {{ ansible_distribution_version }}
architecture = {{ ansible_architecture }}
cpu_cores = {{ ansible_processor_vcpus }}
memory_gb = {{ (ansible_memtotal_mb / 1024) | round(1) }}

{# Performance settings based on system specs #}
[performance]
{% if ansible_memtotal_mb > 4096 and ansible_processor_vcpus >= 4 %}
# High-performance system detected
profile = high_performance
worker_processes = {{ ansible_processor_vcpus * 2 }}
max_connections = {{ (ansible_memtotal_mb / 2) | int }}
cache_size = {{ (ansible_memtotal_mb / 4) | int }}MB
{% elif ansible_memtotal_mb > 2048 and ansible_processor_vcpus >= 2 %}
# Medium-performance system
profile = standard
worker_processes = {{ ansible_processor_vcpus }}
max_connections = {{ (ansible_memtotal_mb / 4) | int }}
cache_size = {{ (ansible_memtotal_mb / 8) | int }}MB
{% else %}
# Low-resource system
profile = low_resource
worker_processes = 1
max_connections = 100
cache_size = 64MB
{% endif %}

{# Network configuration #}
[network]
primary_interface = {{ ansible_default_ipv4.interface }}
primary_ip = {{ ansible_default_ipv4.address }}
gateway = {{ ansible_default_ipv4.gateway | default('not_configured') }}

# All network interfaces
{% for interface in ansible_interfaces %}
{% if interface != 'lo' %}
{% set interface_var = 'ansible_' + interface %}
{% if hostvars[inventory_hostname][interface_var] is defined %}
interface_{{ loop.index }} = {{ interface }}
{% if hostvars[inventory_hostname][interface_var]['ipv4'] is defined %}
ip_{{ loop.index }} = {{ hostvars[inventory_hostname][interface_var]['ipv4']['address'] }}
{% endif %}
{% endif %}
{% endif %}
{% endfor %}

{# Service-specific configuration based on group membership #}
{% if 'webservers' in group_names %}
[webserver]
role = webserver
http_port = {{ http_port | default(80) }}
https_port = {{ https_port | default(443) }}
ssl_enabled = {{ ssl_enabled | default(false) | lower }}
max_connections = {{ max_connections | default(1000) }}

# Load balancer members
{% if groups['webservers'] | length > 1 %}
load_balancer_members = {{ groups['webservers'] | difference([inventory_hostname]) | join(',') }}
{% endif %}

# Security settings for web servers
{% if environment == 'production' %}
security_level = high
rate_limiting = enabled
ssl_required = {{ ssl_enabled | default(false) | lower }}
{% else %}
security_level = standard
rate_limiting = disabled
ssl_required = false
{% endif %}
{% endif %}

{% if 'databases' in group_names %}
[database]
role = database
db_type = {{ db_type | default('postgresql') }}
max_connections = {{ max_connections | default(500) }}

# Database-specific tuning
{% if db_type | default('postgresql') == 'postgresql' %}
shared_buffers = {{ (ansible_memtotal_mb / 4) | int }}MB
effective_cache_size = {{ (ansible_memtotal_mb * 0.75) | int }}MB
work_mem = {{ (ansible_memtotal_mb / 100) | int }}MB
{% elif db_type | default('postgresql') == 'mysql' %}
innodb_buffer_pool_size = {{ (ansible_memtotal_mb * 0.7) | int }}M
query_cache_size = {{ (ansible_memtotal_mb / 10) | int }}M
{% endif %}
{% endif %}

{# Environment-specific settings #}
[environment_{{ environment }}]
{% if environment == 'production' %}
debug = false
log_level = warn
monitoring = enabled
backup_enabled = true
backup_retention_days = 30
{% elif environment == 'staging' %}
debug = true
log_level = info
monitoring = enabled
backup_enabled = true
backup_retention_days = 7
{% else %}
debug = true
log_level = debug
monitoring = disabled
backup_enabled = false
{% endif %}

{# Storage configuration #}
[storage]
{% for mount in ansible_mounts %}
{% if mount.size_total > 0 %}
mount_{{ loop.index }} = {{ mount.mount }}
device_{{ loop.index }} = {{ mount.device }}
fstype_{{ loop.index }} = {{ mount.fstype }}
size_gb_{{ loop.index }} = {{ (mount.size_total / 1024 / 1024 / 1024) | round(1) }}
used_percent_{{ loop.index }} = {{ ((mount.size_total - mount.size_available) / mount.size_total * 100) | round(1) }}
{% if ((mount.size_total - mount.size_available) / mount.size_total * 100) > 80 %}
# WARNING: Mount {{ mount.mount }} is over 80% full!
{% endif %}
{% endif %}
{% endfor %}

{# Custom application settings based on variables #}
{% if app_configs is defined %}
[applications]
{% for app_name, app_config in app_configs.items() %}
[app_{{ app_name }}]
{% for key, value in app_config.items() %}
{{ key }} = {{ value }}
{% endfor %}
{% endfor %}
{% endif %}

{# Host-specific overrides #}
{% if inventory_hostname in hostvars %}
{% set host_vars = hostvars[inventory_hostname] %}
{% if host_vars.custom_config is defined %}
[host_overrides]
{% for key, value in host_vars.custom_config.items() %}
{{ key }} = {{ value }}
{% endfor %}
{% endif %}
{% endif %}

# End of configuration
# Total lines: {{ (self | string).count('\n') + 1 }}
# Generated by Ansible template engine
```

### Create Complex Templates Playbook

Create `complex_templates.yml`:

```yaml
---
- name: Complex Template Usage with Loops and Conditions
  hosts: all
  become: yes
  vars:
    app_configs:
      webapp:
        port: 8080
        threads: "{{ ansible_processor_vcpus * 2 }}"
        memory_limit: "{{ (ansible_memtotal_mb / 2) | int }}M"
        debug: "{{ environment != 'production' }}"
      api:
        port: 3000
        workers: "{{ ansible_processor_vcpus }}"
        timeout: 30
        rate_limit: "{{ 1000 if environment == 'production' else 10000 }}"
        
  tasks:
    - name: "Set host-specific custom configuration"
      set_fact:
        custom_config:
          special_setting: "{{ 'enabled' if ansible_memtotal_mb > 2048 else 'disabled' }}"
          optimization_level: "{{ 'aggressive' if environment == 'production' else 'conservative' }}"
          monitoring_interval: "{{ 60 if environment == 'production' else 300 }}"
          
    - name: "Deploy complex multi-service configuration"
      template:
        src: multi_service.conf.j2
        dest: "/etc/{{ inventory_hostname }}-config.conf"
        owner: root
        group: root
        mode: '0644'
        backup: yes
      register: complex_config
      
    - name: "Create service-specific directories"
      file:
        path: "{{ item }}"
        state: directory
        owner: root
        group: root
        mode: '0755'
      loop:
        - "/etc/services"
        - "/var/log/services"
        - "/var/run/services"
      when: "'webservers' in group_names or 'databases' in group_names"
      
    - name: "Generate service startup scripts"
      template:
        src: service_script.j2
        dest: "/etc/services/{{ item }}.sh"
        owner: root
        group: root
        mode: '0755'
      loop: "{{ app_configs.keys() | list }}"
      when: "'webservers' in group_names"
      
    - name: "Display complex template results"
      debug:
        msg: |
          === COMPLEX TEMPLATE RESULTS ===
          
          Configuration File:
          - Generated: {{ complex_config.changed }}
          - Location: /etc/{{ inventory_hostname }}-config.conf
          - Backup: {{ complex_config.backup_file | default('None') }}
          
          Host Classification:
          - Performance Profile: {{ 
            'High Performance' if (ansible_memtotal_mb > 4096 and ansible_processor_vcpus >= 4) else
            'Standard' if (ansible_memtotal_mb > 2048 and ansible_processor_vcpus >= 2) else
            'Low Resource'
          }}
          - Service Role: {{ 
            'Web Server' if 'webservers' in group_names else
            'Database Server' if 'databases' in group_names else
            'Generic Server'
          }}
          
          Applications Configured: {{ app_configs.keys() | list | join(', ') }}
```

### Create Service Script Template

Create `templates/service_script.j2`:

```bash
#!/bin/bash
# {{ item | title }} Service Script
# Generated by Ansible on {{ ansible_date_time.iso8601 }}

SERVICE_NAME="{{ item }}"
CONFIG_FILE="/etc/{{ inventory_hostname }}-config.conf"
PID_FILE="/var/run/services/${SERVICE_NAME}.pid"
LOG_FILE="/var/log/services/${SERVICE_NAME}.log"

# Service configuration from template variables
{% set service_config = app_configs[item] %}
PORT={{ service_config.port }}
{% if 'threads' in service_config %}
THREADS={{ service_config.threads }}
{% endif %}
{% if 'workers' in service_config %}
WORKERS={{ service_config.workers }}
{% endif %}

# System information
HOSTNAME="{{ ansible_hostname }}"
ENVIRONMENT="{{ environment }}"
CPU_CORES={{ ansible_processor_vcpus }}
MEMORY_MB={{ ansible_memtotal_mb }}

start() {
    echo "Starting ${SERVICE_NAME} service..."
    echo "Configuration: ${CONFIG_FILE}"
    echo "Port: ${PORT}"
    echo "Environment: ${ENVIRONMENT}"
    
    # Create necessary directories
    mkdir -p $(dirname ${PID_FILE})
    mkdir -p $(dirname ${LOG_FILE})
    
    # Start service (placeholder)
    echo "Service ${SERVICE_NAME} started on port ${PORT}" | tee -a ${LOG_FILE}
    echo $$ > ${PID_FILE}
    
    return 0
}

stop() {
    echo "Stopping ${SERVICE_NAME} service..."
    if [ -f ${PID_FILE} ]; then
        rm -f ${PID_FILE}
        echo "Service ${SERVICE_NAME} stopped" | tee -a ${LOG_FILE}
    else
        echo "Service ${SERVICE_NAME} was not running"
    fi
    return 0
}

status() {
    if [ -f ${PID_FILE} ]; then
        echo "${SERVICE_NAME} is running (PID: $(cat ${PID_FILE}))"
        return 0
    else
        echo "${SERVICE_NAME} is not running"
        return 1
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit $?
```

## Running the Labs

### Execute Basic Templates

```bash
# Run basic template deployment
ansible-playbook -i hosts.ini basic_templates.yml

# Check the deployed pages
curl http://192.168.1.101/
```

### Execute Advanced Templates

```bash
# Deploy advanced NGINX configuration with filters
ansible-playbook -i hosts.ini advanced_templates.yml

# Check the filter demonstration page
curl http://192.168.1.101/filters.html
```

### Execute Complex Templates

```bash
# Deploy complex multi-service configuration
ansible-playbook -i hosts.ini complex_templates.yml

# Check generated configuration
ansible webservers -i hosts.ini -m shell -a "head -20 /etc/{{ inventory_hostname }}-config.conf"
```

## Key Learning Points

### Jinja2 Template Syntax
1. **Variables**: `{{ variable_name }}`
2. **Filters**: `{{ variable | filter_name }}`
3. **Control Structures**: `{% if %} {% for %} {% endif %}`
4. **Comments**: `{# comment text #}`

### Essential Filters
- **String**: `upper`, `lower`, `title`, `capitalize`, `truncate`
- **Number**: `round`, `int`, `float`, `abs`, `random`
- **List**: `first`, `last`, `length`, `join`, `sort`, `unique`
- **Logic**: `default`, `ternary`, `bool`
- **Data**: `to_json`, `to_nice_json`, `from_json`

### Advanced Features
- **Conditionals**: Complex if/elif/else logic
- **Loops**: Iterate over lists, dictionaries, and ranges
- **Macros**: Reusable template snippets
- **Inheritance**: Template extension and blocks
- **Custom Filters**: User-defined filter functions

### Best Practices
1. **Use descriptive comments** in templates
2. **Validate template syntax** before deployment
3. **Handle undefined variables** with defaults
4. **Keep templates readable** with proper indentation
5. **Use filters appropriately** for data transformation
6. **Test templates** with different variable values

### Security Considerations
1. **Validate input data** before templating
2. **Escape user-provided content** when necessary
3. **Use appropriate file permissions** for generated files
4. **Backup original files** before replacement
5. **Validate generated configurations** when possible

This comprehensive templating lab demonstrates the power of Jinja2 for creating dynamic, intelligent configuration files that adapt to different environments and system characteristics!
