# Ansible Debugging and Diagnostics

## Learning Ansible Error Detection Tools

This workshop teaches you how to find and fix common Ansible errors using built-in diagnostic tools.

## Diagnostic Tools Overview

### 1. Syntax Check
```bash
ansible-playbook playbook.yml --syntax-check
```
Checks YAML syntax and basic Ansible structure.

### 2. Dry Run (Check Mode)
```bash
ansible-playbook playbook.yml --check
```
Shows what would change without actually making changes.

### 3. Diff Mode
```bash
ansible-playbook playbook.yml --diff
```
Shows exactly what content will change in files.

### 4. Ansible Lint
```bash
ansible-lint playbook.yml
```
Checks for best practices and common mistakes.

### 5. Verbose Mode
```bash
ansible-playbook playbook.yml -v    # Basic verbose
ansible-playbook playbook.yml -vv   # More verbose
ansible-playbook playbook.yml -vvv  # Debug level
```

## Common Error Examples

### Example 1: YAML Syntax Errors

**Broken playbook (syntax-error.yml):**
```yaml
---
- name: Broken YAML syntax
  hosts: all
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state present    # Missing colon
    - name: Start service
      service
        name: nginx      # Wrong indentation
        state: started
```

**How to detect:**
```bash
ansible-playbook syntax-error.yml --syntax-check
```

**Expected error:**
```
ERROR! Syntax Error while loading YAML.
mapping values are not allowed here
```

**Fixed version:**
```yaml
---
- name: Fixed YAML syntax
  hosts: all
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present   # Added colon
    - name: Start service
      service:           # Added colon
        name: nginx      # Fixed indentation
        state: started
```

### Example 2: Variable Errors

**Broken playbook (variable-error.yml):**
```yaml
---
- name: Variable errors
  hosts: all
  vars:
    web_package: nginx
    web_port: 80
  tasks:
    - name: Install web server
      apt:
        name: "{{ webpackage }}"    # Typo in variable name
        state: present
        
    - name: Configure port
      lineinfile:
        path: /etc/nginx/nginx.conf
        line: "listen {{ web_port"   # Missing closing brace
```

**How to detect:**
```bash
ansible-playbook variable-error.yml --check
```

**Expected error:**
```
TASK [Install web server] *****
fatal: [host]: FAILED! => {"msg": "The task includes an option with an undefined variable. The error was: 'webpackage' is undefined"}
```

**Fixed version:**
```yaml
---
- name: Fixed variables
  hosts: all
  vars:
    web_package: nginx
    web_port: 80
  tasks:
    - name: Install web server
      apt:
        name: "{{ web_package }}"   # Fixed variable name
        state: present
        
    - name: Configure port
      lineinfile:
        path: /etc/nginx/nginx.conf
        line: "listen {{ web_port }}"  # Added closing brace
```

### Example 3: Module Parameter Errors

**Broken playbook (module-error.yml):**
```yaml
---
- name: Module parameter errors
  hosts: all
  tasks:
    - name: Create user with wrong parameters
      user:
        username: john        # Should be 'name'
        state: present
        create_home: true     # Should be 'yes' or boolean true
        
    - name: Copy file with missing source
      copy:
        dest: /tmp/test.txt   # Missing 'src' or 'content'
        owner: root
        
    - name: Service with typo
      service:
        name: nginx
        state: restarted
        enable: yes           # Should be 'enabled'
```

**How to detect:**
```bash
ansible-playbook module-error.yml --check
ansible-lint module-error.yml
```

**Expected errors:**
```
[208] File permissions unset or incorrect
[502] All tasks should be named
[601] Don't compare to literal True/False
```

**Fixed version:**
```yaml
---
- name: Fixed module parameters
  hosts: all
  tasks:
    - name: Create user with correct parameters
      user:
        name: john           # Correct parameter name
        state: present
        create_home: yes     # Correct boolean value
        
    - name: Copy file with content
      copy:
        content: "Hello World"  # Added content
        dest: /tmp/test.txt
        owner: root
        mode: '0644'         # Added file permissions
        
    - name: Service with correct parameter
      service:
        name: nginx
        state: restarted
        enabled: yes         # Correct parameter name
```

### Example 4: Logic Errors

**Broken playbook (logic-error.yml):**
```yaml
---
- name: Logic errors
  hosts: all
  tasks:
    - name: Install package on wrong OS
      apt:
        name: nginx
        state: present
      when: ansible_os_family == "RedHat"  # Wrong condition
      
    - name: Create directory after using it
      copy:
        src: myfile.txt
        dest: /opt/myapp/myfile.txt
        
    - name: Create the directory (too late)
      file:
        path: /opt/myapp
        state: directory
        
    - name: Loop with wrong variable
      user:
        name: "{{ item }}"
        state: present
      loop: "{{ user_list }}"    # Variable not defined
```

**How to detect:**
```bash
ansible-playbook logic-error.yml --check -v
```

**Expected issues:**
- Task will be skipped on Ubuntu (apt on RedHat condition)
- Directory creation will fail (directory doesn't exist)
- Undefined variable error

**Fixed version:**
```yaml
---
- name: Fixed logic
  hosts: all
  vars:
    user_list:
      - alice
      - bob
  tasks:
    - name: Install package on correct OS
      apt:
        name: nginx
        state: present
      when: ansible_os_family == "Debian"  # Correct condition
      
    - name: Create directory first
      file:
        path: /opt/myapp
        state: directory
        mode: '0755'
        
    - name: Then copy file to directory
      copy:
        src: myfile.txt
        dest: /opt/myapp/myfile.txt
        
    - name: Loop with defined variable
      user:
        name: "{{ item }}"
        state: present
      loop: "{{ user_list }}"    # Variable now defined
```

### Example 5: File and Permission Errors

**Broken playbook (file-error.yml):**
```yaml
---
- name: File permission errors
  hosts: all
  tasks:
    - name: Copy file without permissions
      copy:
        content: "secret data"
        dest: /etc/secret.conf
        # Missing owner, group, mode
        
    - name: Create directory with wrong permissions
      file:
        path: /var/log/myapp
        state: directory
        mode: 777              # Should be string '0777'
        owner: wrong_user      # User doesn't exist
        
    - name: Edit file that doesn't exist
      lineinfile:
        path: /etc/nonexistent.conf
        line: "some config"
        # File doesn't exist, should use 'create: yes'
```

**How to detect:**
```bash
ansible-playbook file-error.yml --check --diff
ansible-lint file-error.yml
```

**Expected errors:**
```
[208] File permissions unset or incorrect
[502] All tasks should be named
[risky-file-permissions] File permissions unset or incorrect
```

**Fixed version:**
```yaml
---
- name: Fixed file operations
  hosts: all
  tasks:
    - name: Copy file with proper permissions
      copy:
        content: "secret data"
        dest: /etc/secret.conf
        owner: root
        group: root
        mode: '0600'           # Secure permissions for secrets
        
    - name: Create directory with correct permissions
      file:
        path: /var/log/myapp
        state: directory
        mode: '0755'           # String format
        owner: root            # Valid user
        group: root
        
    - name: Edit file with create option
      lineinfile:
        path: /etc/myapp.conf
        line: "some config"
        create: yes            # Create if doesn't exist
        owner: root
        group: root
        mode: '0644'
```

## Practical Debugging Session

### Step 1: Create a broken playbook

```bash
cat > broken-playbook.yml << 'EOF'
---
- name: Debugging practice
  hosts: aws
  vars:
    packages
      - nginx
      - mysql-server
  tasks:
    - name: Install packages
      apt:
        name: "{{ item }}"
        state: present
      loop: "{{ package_list }}"
      when: ansible_distribution = "Ubuntu"
    
    - name: Start services
      service:
        name: "{{ item }}"
        state: started
        enabled: true
      loop:
        - nginx
        - mysql
EOF
```

### Step 2: Run diagnostic tools

```bash
# Check syntax
ansible-playbook broken-playbook.yml --syntax-check

# Check for logic errors
ansible-playbook broken-playbook.yml --check -i hosts.yml

# Run ansible-lint
ansible-lint broken-playbook.yml
```

### Step 3: Fix the errors

**Errors found:**
1. Missing colon after `packages`
2. Wrong variable name in loop (`package_list` vs `packages`)
3. Wrong comparison operator (`=` should be `==`)

**Fixed version:**
```yaml
---
- name: Debugging practice - fixed
  hosts: aws
  vars:
    packages:              # Added colon
      - nginx
      - mysql-server
  tasks:
    - name: Install packages
      apt:
        name: "{{ item }}"
        state: present
      loop: "{{ packages }}"  # Fixed variable name
      when: ansible_distribution == "Ubuntu"  # Fixed operator
    
    - name: Start services
      service:
        name: "{{ item }}"
        state: started
        enabled: true        # Boolean values can be true/false or yes/no
      loop:
        - nginx
        - mysql
```

## Debugging Workflow

### 1. Always start with syntax check
```bash
ansible-playbook playbook.yml --syntax-check
```

### 2. Use check mode to test logic
```bash
ansible-playbook playbook.yml --check -i inventory
```

### 3. Add diff to see file changes
```bash
ansible-playbook playbook.yml --check --diff -i inventory
```

### 4. Run ansible-lint for best practices
```bash
ansible-lint playbook.yml
```

### 5. Use verbose mode for detailed info
```bash
ansible-playbook playbook.yml --check -v -i inventory
```

### 6. Test on single host first
```bash
ansible-playbook playbook.yml --limit hostname -i inventory
```

## Common Error Patterns

### YAML Syntax Issues
- Missing colons after keys
- Wrong indentation
- Missing quotes around strings with special characters
- Mixing tabs and spaces

### Variable Problems
- Typos in variable names
- Missing variable definitions
- Wrong variable syntax (missing `{{ }}`)
- Undefined variables in loops

### Module Issues
- Wrong parameter names
- Missing required parameters
- Wrong parameter values
- Deprecated modules

### Logic Errors
- Wrong conditions
- Tasks in wrong order
- Missing dependencies
- Incorrect file paths

## Best Practices for Error Prevention

1. **Always use syntax check** before running playbooks
2. **Test with --check mode** first
3. **Use ansible-lint** regularly
4. **Start with simple tasks** and build complexity
5. **Use descriptive task names** for easier debugging
6. **Test on single hosts** before running on all hosts
7. **Use version control** to track changes
8. **Document your variables** and their expected values

## Exercise: Debug This Playbook

Try to find and fix all errors in this playbook:

```yaml
---
- name: Exercise debugging
  hosts: all
  vars:
    app_name: myapp
    app_user myapp
    config_files:
      - app.conf
      - db.conf
  tasks:
    - name: Create application user
      user:
        username: "{{ app_user }}"
        home: /opt/{{ app_name }}"
        create_home: true
        
    - name Install application
      apt:
        name: "{{ app_name }}"
        state: present
      when: ansible_os_family = "Debian"
      
    - name: Copy configuration files
      copy:
        src: "{{ item }}"
        dest: "/etc/{{ app_name }}/{{ item }}"
      loop: "{{ config_file }}"
      
    - name: Set permissions
      file:
        path: "/etc/{{ app_name }}"
        owner: "{{ app_user }}"
        mode: 755
        recurse: yes
```

**Hint:** There are at least 8 errors in this playbook. Use the diagnostic tools to find them all!

Remember: Good debugging skills make you a better Ansible developer. Always test your playbooks before running them in production!
