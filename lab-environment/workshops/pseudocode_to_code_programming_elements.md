# Ansible Programming Elements - From Ideas to Code

## Thinking Like a Programmer

Before writing Ansible code, think about what you want to do step by step. This is called pseudocode - writing your ideas in simple English before converting to actual code.

## From Idea to Pseudocode to Ansible

### Example 1: Install Software

**Your idea:** "I want to install nginx on my web servers"

**Pseudocode:**

```bash
FOR each web server:
INSTALL nginx package
START nginx service
````


**Ansible code:**
```yaml
- name: Setup nginx
  hosts: webservers
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
    - name: Start nginx
      service:
        name: nginx
        state: started
```

### Example 2: Create Multiple Users

**Your idea:** "I need to create users john, alice, and bob"

**Pseudocode:**
```bash
LIST users = [john, alice, bob]
FOR each user IN users:
CREATE user
```

**Ansible code:**
```yaml
- name: Create users
  hosts: all
  tasks:
    - name: Create user accounts
      user:
        name: "{{ item }}"
        state: present
      loop:
        - john
        - alice
        - bob
```

## Variables - Storing Information

Variables are like boxes where you store information to use later.

### Why Use Variables?

1. **Avoid repetition** - Write once, use many times
2. **Easy changes** - Change in one place, updates everywhere
3. **Make code flexible** - Same code works in different situations

### Simple Variables

```yaml
vars:
  web_package: nginx
  web_port: 80
  admin_user: webadmin

tasks:
  - name: Install web server
    apt:
      name: "{{ web_package }}"
      state: present
```

### List Variables

When you have multiple items of the same type:

```yaml
vars:
  packages:
    - nginx
    - mysql-server
    - php
  
tasks:
  - name: Install packages
    apt:
      name: "{{ item }}"
      state: present
    loop: "{{ packages }}"
```

### Dictionary Variables

When you have related information grouped together:

```yaml
vars:
  database:
    name: myapp
    user: dbuser
    password: secret123
    
tasks:
  - name: Create database
    mysql_db:
      name: "{{ database.name }}"
      state: present
```

## Loops - Doing Things Multiple Times

Instead of writing the same task many times, use loops.

### Basic Loop

```yaml
- name: Create directories
  file:
    path: "/tmp/{{ item }}"
    state: directory
  loop:
    - folder1
    - folder2
    - folder3
```

### Loop with Dictionary

```yaml
- name: Create users with details
  user:
    name: "{{ item.name }}"
    group: "{{ item.group }}"
    shell: "{{ item.shell }}"
  loop:
    - { name: john, group: admin, shell: /bin/bash }
    - { name: alice, group: users, shell: /bin/zsh }
```

## Conditions - Making Decisions

Run tasks only when certain conditions are true.

### Simple Condition

```yaml
- name: Install nginx (Ubuntu only)
  apt:
    name: nginx
    state: present
  when: ansible_distribution == "Ubuntu"
```

### Multiple Conditions

```yaml
- name: Install heavy software
  apt:
    name: mysql-server
    state: present
  when:
    - ansible_distribution == "Ubuntu"
    - ansible_memtotal_mb > 2048
```

## Practice: Converting Ideas

### Exercise 1
**Idea:** "Install git, vim, and htop on Ubuntu servers only"

**Your pseudocode:**




**Solution pseudocode:**
```bash
IF system is Ubuntu:
INSTALL git
INSTALL vim
INSTALL htop
```

**Ansible solution:**
```yaml
- name: Install development tools
  apt:
    name: "{{ item }}"
    state: present
  loop:
    - git
    - vim
    - htop
  when: ansible_distribution == "Ubuntu"
```

### Exercise 2
**Idea:** "Create 3 directories: logs, configs, and backups with proper permissions"

**Your pseudocode:**



**Solution pseudocode:**
```bash
LIST directories = [logs, configs, backups]
FOR each directory IN directories:
CREATE directory /var/{{ directory }}
SET permissions to 755
```


**Ansible solution:**
```yaml
vars:
  directories:
    - logs
    - configs
    - backups

tasks:
  - name: Create application directories
    file:
      path: "/var/{{ item }}"
      state: directory
      mode: '0755'
    loop: "{{ directories }}"
```

## Common Patterns

### Pattern 1: Install and Start Service
```yaml
vars:
  service_name: nginx
  
tasks:
  - name: Install service
    apt:
      name: "{{ service_name }}"
      state: present
      
  - name: Start service
    service:
      name: "{{ service_name }}"
      state: started
      enabled: yes
```

### Pattern 2: Copy Configuration Files
```yaml
vars:
  config_files:
    - nginx.conf
    - php.ini
    - mysql.conf
    
tasks:
  - name: Copy configuration files
    copy:
      src: "{{ item }}"
      dest: "/etc/{{ item }}"
      backup: yes
    loop: "{{ config_files }}"
```

### Pattern 3: Conditional Installation
```yaml
vars:
  packages:
    - name: nginx
      condition: "{{ 'webserver' in group_names }}"
    - name: mysql-server
      condition: "{{ 'database' in group_names }}"
      
tasks:
  - name: Install role-specific packages
    apt:
      name: "{{ item.name }}"
      state: present
    loop: "{{ packages }}"
    when: item.condition
```

## Tips for Beginners

1. **Start simple** - Begin with basic tasks, add complexity gradually
2. **Use descriptive names** - Make variable and task names clear
3. **Test small changes** - Don't write huge playbooks at once
4. **Use pseudocode first** - Plan before coding
5. **Keep variables organized** - Group related variables together

## Quick Reference

### Variable Usage
```yaml
# Define
vars:
  my_variable: value
  
# Use  
"{{ my_variable }}"
```

### Loop Usage
```yaml
loop:
  - item1
  - item2
```

### Condition Usage
```yaml
when: condition_is_true
```

### Combining All Three
```yaml
vars:
  packages: [git, vim]
  
tasks:
  - name: Install packages on Ubuntu
    apt:
      name: "{{ item }}"
      state: present
    loop: "{{ packages }}"
    when: ansible_distribution == "Ubuntu"
```

Remember: Think in pseudocode first, then translate to Ansible. Start simple and build complexity gradually.

