# Module 4: Simple Ansible Modules - Deploy Nginx Website

## Objective
Learn essential Ansible modules by creating users, managing files, and deploying a simple nginx website about the Ansible Fundamentals course.

## Prerequisites
- Ansible configured with inventory
- SSH access to managed hosts
- Sudo privileges on target systems

## Lab Setup

### Create Inventory File
Create `hosts.yml`:

```yaml
all:
  hosts:
    localhost:
      ansible_connection: local
  children:
    aws:
      hosts:
        16.171.52.223:
          ansible_user: ubuntu
        56.228.82.5:
          ansible_user: ubuntu
      vars:
        ansible_user: ubuntu
        ansible_ssh_private_key_file: ~/.ssh/ansible_key
        ansible_python_interpreter: /usr/bin/python3
        ansible_ssh_common_args: "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
```

## Step-by-Step Playbooks

### Step 1: Create Users and Groups

```bash
cat > step1-users.yml << 'EOF'
---
- name: Create users and groups
  hosts: aws
  become: yes
  
  tasks:
    - name: Create webadmin group
      ansible.builtin.group:
        name: webadmin
        state: present
        
    - name: Create john user
      ansible.builtin.user:
        name: john
        group: webadmin
        create_home: yes
EOF
```

**Run this step:**
```bash
ansible-playbook -i hosts.yml step1-users.yml --private-key ~/.ssh/ansible_key -u ubuntu
```

### Step 2: Create Directories

```bash
cat > step2-files.yml << 'EOF'
---
- name: Create directories and files
  hosts: aws
  become: yes
  
  tasks:
    - name: Create web directory
      ansible.builtin.file:
        path: /var/www/html
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'
        
    - name: Create log directory
      ansible.builtin.file:
        path: /var/log/myapp
        state: directory
        owner: john
        group: webadmin
        mode: '0755'
EOF
```

**Run this step:**
```bash
ansible-playbook -i hosts.yml step2-files.yml --private-key ~/.ssh/ansible_key -u ubuntu
```

### Step 3: Copy Website Content

```bash
cat > step3-copy.yml << 'EOF'
---
- name: Copy files and content
  hosts: aws
  become: yes
  vars:
    page_title: "Ansible Fundamentals Course - Advancements"
  
  tasks:
    - name: Create simple HTML page
      ansible.builtin.copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>{{ page_title }}</title>
              <style>
                  body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
                  .header { color: #2c3e50; text-align: center; }
                  .content { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                  .highlight { color: #e74c3c; font-weight: bold; }
              </style>
          </head>
          <body>
              <div class="content">
                  <h1 class="header">{{ page_title }}</h1>
                  <h2 class="highlight">September 9-10, 2025</h2>
                  <h3>Welcome to ING Bank Ansible Training!</h3>
                  
                  <h4>What we're learning:</h4>
                  <ul>
                      <li>Ansible basics and installation</li>
                      <li>Ad-hoc commands</li>
                      <li>Inventory management</li>
                      <li>Writing playbooks</li>
                      <li>Using modules (user, file, copy, service)</li>
                      <li>Variables and templates</li>
                      <li>Roles and best practices</li>
                  </ul>
                  
                  <h4>Server Information:</h4>
                  <p><strong>Hostname:</strong> {{ ansible_hostname }}</p>
                  <p><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</p>
                  <p><strong>OS:</strong> {{ ansible_distribution }} {{ ansible_distribution_version }}</p>
                  
                  <p class="highlight">This page was deployed using Ansible!</p>
              </div>
          </body>
          </html>
        dest: /var/www/html/index.html
        owner: www-data
        group: www-data
        mode: '0644'
EOF
```

**Run this step:**
```bash
ansible-playbook -i hosts.yml step3-copy.yml --private-key ~/.ssh/ansible_key -u ubuntu
```

### Step 4: Install and Configure Nginx

```bash
cat > step4-nginx.yml << 'EOF'
---
- name: Install and configure nginx
  hosts: aws
  become: yes
  
  tasks:
    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: yes
        
    - name: Install nginx
      ansible.builtin.apt:
        name: nginx
        state: present
        
    - name: Start nginx service
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: yes
        
    - name: Allow HTTP through firewall
      ansible.builtin.ufw:
        rule: allow
        port: '80'
        proto: tcp
EOF
```

**Run this step:**
```bash
ansible-playbook -i hosts.yml step4-nginx.yml --private-key ~/.ssh/ansible_key -u ubuntu
```

## Complete All-in-One Playbook

```bash
cat > ansible-course-website.yml << 'EOF'
---
- name: Deploy Ansible Course Website
  hosts: aws
  become: yes
  gather_facts: yes
  
  tasks:
    # Step 1: Create users and groups
    - name: Create webadmin group
      ansible.builtin.group:
        name: webadmin
        state: present
        
    - name: Create john user
      ansible.builtin.user:
        name: john
        group: webadmin
        create_home: yes

    # Step 2: Install nginx
    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: yes
        
    - name: Install nginx
      ansible.builtin.apt:
        name: nginx
        state: present

    # Step 3: Create web content
    - name: Deploy course website
      ansible.builtin.copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Ansible Fundamentals Course</title>
              <style>
                  body { 
                      font-family: Arial, sans-serif; 
                      margin: 0; 
                      padding: 40px; 
                      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                      color: white;
                  }
                  .container { 
                      background: rgba(255,255,255,0.1); 
                      padding: 30px; 
                      border-radius: 15px; 
                      backdrop-filter: blur(10px);
                      max-width: 800px;
                      margin: 0 auto;
                  }
                  h1 { text-align: center; font-size: 2.5em; margin-bottom: 10px; }
                  h2 { color: #ffeb3b; text-align: center; }
                  .info-box { 
                      background: rgba(255,255,255,0.2); 
                      padding: 20px; 
                      margin: 20px 0; 
                      border-radius: 10px; 
                  }
                  ul li { margin: 8px 0; }
                  .highlight { color: #ffeb3b; font-weight: bold; }
                  .server-info { font-family: monospace; background: rgba(0,0,0,0.3); padding: 15px; border-radius: 5px; }
              </style>
          </head>
          <body>
              <div class="container">
                  <h1>Ansible Fundamentals</h1>
                  <h2>ING Bank Training</h2>
                  <h2 class="highlight">September 9-10, 2025</h2>
                  
                  <div class="info-box">
                      <h3>Course Modules:</h3>
                      <ul>
                          <li>Module 1: Introduction to Ansible</li>
                          <li>Module 2: Ad-hoc Commands</li>
                          <li>Module 3: Host Inventories</li>
                          <li>Module 4: YAML & Basic Playbooks</li>
                          <li>Module 5: Variables, Loops & Conditions</li>
                          <li>Module 6: Modules Deep Dive</li>
                          <li>Module 7: Templates & Jinja2</li>
                          <li>Module 8: Vault & Roles</li>
                      </ul>
                  </div>
                  
                  <div class="info-box">
                      <h3>Server Information:</h3>
                      <div class="server-info">
                          <p><strong>Hostname:</strong> {{ ansible_hostname }}</p>
                          <p><strong>IP Address:</strong> {{ ansible_default_ipv4.address }}</p>
                          <p><strong>Operating System:</strong> {{ ansible_distribution }} {{ ansible_distribution_version }}</p>
                          <p><strong>Architecture:</strong> {{ ansible_architecture }}</p>
                          <p><strong>Memory:</strong> {{ (ansible_memtotal_mb/1024)|round(1) }} GB</p>
                      </div>
                  </div>
                  
                  <div class="info-box">
                      <h3>Deployment Status:</h3>
                      <p class="highlight">This website was successfully deployed using Ansible!</p>
                      <p>User 'john' created in 'webadmin' group</p>
                      <p>Nginx web server installed and running</p>
                      <p>Firewall configured to allow HTTP traffic</p>
                  </div>
              </div>
          </body>
          </html>
        dest: /var/www/html/index.html
        owner: www-data
        group: www-data
        mode: '0644'

    # Step 4: Configure and start nginx
    - name: Start and enable nginx
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: yes
        
    - name: Allow HTTP through firewall
      ansible.builtin.ufw:
        rule: allow
        port: '80'
        proto: tcp
        
    # Step 5: Verify deployment
    - name: Check nginx status
      ansible.builtin.service:
        name: nginx
        state: started
      register: nginx_status
      
    - name: Display success message
      ansible.builtin.debug:
        msg: |
          SUCCESS! Ansible Course Website Deployed!
          
          Access your website at:
          http://{{ ansible_default_ipv4.address }}
          
          What was accomplished:
          - Created user 'john' in group 'webadmin'  
          - Installed nginx web server
          - Deployed custom HTML page about the course
          - Started nginx service
          - Configured firewall for HTTP access
EOF
```

## Running the Playbooks

### Step-by-step execution (for learning):
```bash
# Run each step individually to see what each does
ansible-playbook -i hosts.yml step1-users.yml --private-key ~/.ssh/ansible_key -u ubuntu
ansible-playbook -i hosts.yml step2-files.yml --private-key ~/.ssh/ansible_key -u ubuntu  
ansible-playbook -i hosts.yml step3-copy.yml --private-key ~/.ssh/ansible_key -u ubuntu
ansible-playbook -i hosts.yml step4-nginx.yml --private-key ~/.ssh/ansible_key -u ubuntu
```

### All-in-one execution (for final result):
```bash
# Run the complete playbook
ansible-playbook -i hosts.yml ansible-course-website.yml --private-key ~/.ssh/ansible_key -u ubuntu

# With verbose output to see everything that happens
ansible-playbook -i hosts.yml ansible-course-website.yml --private-key ~/.ssh/ansible_key -u ubuntu -v
```

## Verification Commands

### Check that nginx is running:
```bash
ansible aws -i hosts.yml -m service -a "name=nginx state=started" --private-key ~/.ssh/ansible_key -u ubuntu --become
```

### Test the website:
```bash
ansible aws -i hosts.yml -m uri -a "url=http://{{ ansible_default_ipv4.address }} return_content=yes" --private-key ~/.ssh/ansible_key -u ubuntu
```

### Check created users:
```bash
ansible aws -i hosts.yml -m command -a "id john" --private-key ~/.ssh/ansible_key -u ubuntu --become
```

### Check created directories:
```bash
ansible aws -i hosts.yml -m stat -a "path=/var/log/myapp" --private-key ~/.ssh/ansible_key -u ubuntu --become
```

## Key Learning Points

### Modules Used:
1. **ansible.builtin.group** - Create and manage groups
2. **ansible.builtin.user** - Create and manage users
3. **ansible.builtin.file** - Create directories and manage permissions
4. **ansible.builtin.copy** - Copy content to remote hosts
5. **ansible.builtin.apt** - Install packages on Ubuntu/Debian
6. **ansible.builtin.service** - Start and manage services
7. **ansible.builtin.ufw** - Configure Ubuntu firewall

### Best Practices Demonstrated:
1. **Idempotency** - All tasks can be run multiple times safely
2. **Descriptive task names** - Clear descriptions of what each task does
3. **Proper permissions** - Setting owner, group, and mode for files
4. **Service management** - Ensuring services are started and enabled
5. **Fact gathering** - Using ansible facts in templates

## Expected Results

After running the complete playbook, you will have:

- A user named 'john' in the 'webadmin' group
- Nginx web server installed and running
- A custom website about the Ansible Fundamentals course
- Website accessible via HTTP on port 80
- Firewall configured to allow HTTP traffic

The website will display:
- Course information for September 9-10, 2025
- Server details (hostname, IP, OS)
- Confirmation that the deployment was done with Ansible

## Troubleshooting

### If nginx fails to start:
```bash
ansible aws -i hosts.yml -m shell -a "systemctl status nginx" --private-key ~/.ssh/ansible_key -u ubuntu --become
```

### If website is not accessible:
```bash
ansible aws -i hosts.yml -m shell -a "ufw status" --private-key ~/.ssh/ansible_key -u ubuntu --become
```

### Check if HTML file exists:
```bash
ansible aws -i hosts.yml -m stat -a "path=/var/www/html/index.html" --private-key ~/.ssh/ansible_key -u ubuntu --become
```

This lab provides a practical introduction to essential Ansible modules while creating a functional website about your training course!
