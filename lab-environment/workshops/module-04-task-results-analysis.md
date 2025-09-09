# Module 4: Understanding Task Results - OK vs Changed vs Failed

## Objective
Learn to interpret and work with Ansible task results, understanding the differences between OK, Changed, and Failed states, and how to use this information for better automation.

## Prerequisites
- Ansible properly configured
- Access to target hosts
- Basic understanding of Ansible modules

## Understanding Task States

### Task Result States

1. **OK (Green)** - Task executed successfully, no changes made
2. **Changed (Yellow)** - Task executed successfully, system state changed
3. **Failed (Red)** - Task execution failed, playbook stops (unless handled)
4. **Skipped (Cyan)** - Task skipped due to conditions
5. **Unreachable (Red)** - Host unreachable or connection failed

## Lab Setup

### Create Inventory
Create `hosts.ini`:

```ini
[test_hosts]
target1 ansible_host=192.168.1.101 ansible_user=ansibleuser

[test_hosts:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

## Lab 1: Basic Task Results

### Create Task Results Playbook

Create `task_results_demo.yml`:

```yaml
---
- name: Demonstrate Task Results - OK vs Changed vs Failed
  hosts: test_hosts
  become: yes
  vars:
    test_file: /tmp/ansible-results-test.txt
    test_dir: /tmp/ansible-test-results
    
  tasks:
    # CHANGED EXAMPLES
    - name: "CHANGED: Create a new file (first run will show CHANGED)"
      copy:
        content: "This is a test file created by Ansible\n"
        dest: "{{ test_file }}"
        mode: '0644'
      register: file_creation
      
    - name: "CHANGED: Create directory (first run will show CHANGED)"
      file:
        path: "{{ test_dir }}"
        state: directory
        mode: '0755'
      register: dir_creation
      
    - name: "CHANGED: Install package (will show CHANGED if not installed)"
      package:
        name: htop
        state: present
      register: package_install
      
    - name: "CHANGED: Add user (will show CHANGED if user doesn't exist)"
      user:
        name: testuser
        state: present
        create_home: yes
      register: user_creation
      
    # OK EXAMPLES (run playbook twice to see these)
    - name: "OK: File already exists with same content"
      copy:
        content: "This is a test file created by Ansible\n"
        dest: "{{ test_file }}"
        mode: '0644'
      register: file_ok
      
    - name: "OK: Directory already exists"
      file:
        path: "{{ test_dir }}"
        state: directory
        mode: '0755'
      register: dir_ok
      
    - name: "OK: Package already installed"
      package:
        name: htop
        state: present
      register: package_ok
      
    # FAILED EXAMPLES (with error handling)
    - name: "FAILED: Try to access non-existent file"
      stat:
        path: /non/existent/path/file.txt
      register: failed_stat
      ignore_errors: yes
      
    - name: "FAILED: Try to install non-existent package"
      package:
        name: non-existent-package-xyz
        state: present
      register: failed_package
      ignore_errors: yes
      
    - name: "FAILED: Try to write to protected directory"
      copy:
        content: "test"
        dest: /root/protected-file.txt
      register: failed_copy
      ignore_errors: yes
      become: no  # This will fail due to permissions
      
    # SKIPPED EXAMPLES
    - name: "SKIPPED: Conditional task that will be skipped"
      debug:
        msg: "This task will be skipped"
      when: false
      register: skipped_task
      
    - name: "SKIPPED: OS-specific task"
      debug:
        msg: "This only runs on Windows"
      when: ansible_os_family == "Windows"
      register: os_specific
      
    # DISPLAY RESULTS
    - name: "RESULTS: Show task result details"
      debug:
        msg: |
          === TASK RESULTS ANALYSIS ===
          
          File Creation - Changed: {{ file_creation.changed }}
          Directory Creation - Changed: {{ dir_creation.changed }}
          Package Install - Changed: {{ package_install.changed }}
          User Creation - Changed: {{ user_creation.changed }}
          
          File OK - Changed: {{ file_ok.changed }}
          Directory OK - Changed: {{ dir_ok.changed }}
          Package OK - Changed: {{ package_ok.changed }}
          
          Failed Stat - Failed: {{ failed_stat.failed | default(false) }}
          Failed Package - Failed: {{ failed_package.failed | default(false) }}
          Failed Copy - Failed: {{ failed_copy.failed | default(false) }}
```

## Lab 2: Advanced Result Handling

### Create Advanced Results Playbook

Create `advanced_results_handling.yml`:

```yaml
---
- name: Advanced Task Results Handling
  hosts: test_hosts
  become: yes
  vars:
    service_name: nginx
    config_file: /etc/nginx/nginx.conf
    
  tasks:
    # REGISTER VARIABLES FOR RESULT ANALYSIS
    - name: "Check if service exists"
      shell: systemctl list-units --all | grep {{ service_name }}
      register: service_check
      ignore_errors: yes
      changed_when: false  # This task never changes anything
      
    - name: "Install service if not present"
      package:
        name: "{{ service_name }}"
        state: present
      register: service_install
      when: service_check.rc != 0
      
    - name: "Start service"
      service:
        name: "{{ service_name }}"
        state: started
        enabled: yes
      register: service_start
      
    # CONDITIONAL ACTIONS BASED ON RESULTS
    - name: "Show installation result"
      debug:
        msg: |
          Service {{ service_name }} installation result:
          - Was installed: {{ service_install.changed | default(false) }}
          - Start result changed: {{ service_start.changed }}
          - Service is now running: {{ service_start.state | default('unknown') }}
      when: service_install is defined
      
    # CUSTOM CHANGED CONDITIONS
    - name: "Custom changed condition example"
      shell: |
        if [ ! -f /tmp/custom-flag ]; then
          echo "Creating flag file"
          touch /tmp/custom-flag
          exit 1  # Indicate change occurred
        else
          echo "Flag file already exists"
          exit 0  # No change needed
        fi
      register: custom_task
      changed_when: custom_task.rc == 1
      failed_when: custom_task.rc > 1
      
    # CUSTOM FAILED CONDITIONS
    - name: "Custom failed condition example"
      shell: echo "Return code 5"; exit 5
      register: custom_fail
      failed_when: custom_fail.rc == 5
      ignore_errors: yes
      
    - name: "Handle custom failure"
      debug:
        msg: "Task failed as expected with RC: {{ custom_fail.rc }}"
      when: custom_fail.failed
      
    # RESULT-BASED NOTIFICATIONS
    - name: "Configuration change that triggers handler"
      copy:
        content: |
          # Custom nginx configuration
          user nginx;
          worker_processes auto;
          events {
              worker_connections 1024;
          }
          http {
              include /etc/nginx/mime.types;
              default_type application/octet-stream;
              server {
                  listen 80;
                  server_name localhost;
                  location / {
                      root /usr/share/nginx/html;
                      index index.html;
                  }
              }
          }
        dest: "{{ config_file }}"
        backup: yes
      register: config_change
      notify: restart nginx
      
    # RESULT AGGREGATION
    - name: "Aggregate results"
      set_fact:
        deployment_summary:
          service_installed: "{{ service_install.changed | default(false) }}"
          service_started: "{{ service_start.changed }}"
          config_changed: "{{ config_change.changed }}"
          custom_task_changed: "{{ custom_task.changed }}"
          
    - name: "Display deployment summary"
      debug:
        var: deployment_summary
        
  handlers:
    - name: restart nginx
      service:
        name: nginx
        state: restarted
      listen: restart nginx
```

## Lab 3: Error Handling and Recovery

### Create Error Handling Playbook

Create `error_handling_demo.yml`:

```yaml
---
- name: Error Handling and Recovery Strategies
  hosts: test_hosts
  become: yes
  
  tasks:
    # IGNORE ERRORS STRATEGY
    - name: "Strategy 1: Ignore errors and continue"
      block:
        - name: "Task that might fail"
          shell: some-command-that-might-not-exist
          register: might_fail
          ignore_errors: yes
          
        - name: "Continue regardless of previous task"
          debug:
            msg: |
              Previous task result:
              - Failed: {{ might_fail.failed | default(false) }}
              - RC: {{ might_fail.rc | default('N/A') }}
              - Error: {{ might_fail.stderr | default('No error') }}
              
    # BLOCK/RESCUE/ALWAYS STRATEGY
    - name: "Strategy 2: Block/Rescue/Always pattern"
      block:
        - name: "Try to perform risky operation"
          shell: |
            if [ "$RANDOM" -gt 16000 ]; then
              echo "Random failure occurred"
              exit 1
            else
              echo "Operation successful"
              exit 0
            fi
          register: risky_operation
          
        - name: "This runs only if block succeeds"
          debug:
            msg: "Block completed successfully: {{ risky_operation.stdout }}"
            
      rescue:
        - name: "Handle the failure"
          debug:
            msg: "Block failed, executing rescue tasks"
            
        - name: "Attempt recovery"
          shell: echo "Performing recovery operation"
          register: recovery
          
        - name: "Log recovery attempt"
          debug:
            msg: "Recovery completed: {{ recovery.stdout }}"
            
      always:
        - name: "This always runs"
          debug:
            msg: "Cleanup or logging task - always executes"
            
    # RETRY STRATEGY
    - name: "Strategy 3: Retry with until"
      shell: |
        # Simulate flaky service that succeeds randomly
        if [ "$RANDOM" -gt 20000 ]; then
          echo "Service is ready"
          exit 0
        else
          echo "Service not ready yet"
          exit 1
        fi
      register: service_check
      until: service_check.rc == 0
      retries: 5
      delay: 2
      ignore_errors: yes
      
    - name: "Show retry results"
      debug:
        msg: |
          Retry attempt completed:
          - Final result: {{ 'Success' if service_check.rc == 0 else 'Failed' }}
          - Attempts made: {{ service_check.attempts | default(1) }}
          
    # CONDITIONAL FAILURE
    - name: "Strategy 4: Conditional failure handling"
      shell: echo "Checking disk space"; df -h / | tail -1
      register: disk_check
      
    - name: "Analyze disk space"
      set_fact:
        disk_usage: "{{ disk_check.stdout.split()[4] | regex_replace('%', '') | int }}"
        
    - name: "Fail if disk usage too high"
      fail:
        msg: "Disk usage is {{ disk_usage }}% - too high!"
      when: disk_usage | int > 90
      
    - name: "Continue if disk usage acceptable"
      debug:
        msg: "Disk usage is {{ disk_usage }}% - acceptable"
      when: disk_usage | int <= 90
      
    # ASSERT STRATEGY
    - name: "Strategy 5: Using assert for validation"
      assert:
        that:
          - ansible_memtotal_mb > 512
          - ansible_processor_vcpus >= 1
          - ansible_distribution in ['Ubuntu', 'CentOS', 'RedHat', 'Debian']
        fail_msg: "System requirements not met"
        success_msg: "System requirements validated successfully"
        
    # RESULT ANALYSIS
    - name: "Final result analysis"
      debug:
        msg: |
          === ERROR HANDLING DEMONSTRATION COMPLETE ===
          
          Key Strategies Demonstrated:
          1. ignore_errors: Continue despite failures
          2. block/rescue/always: Structured error handling
          3. until/retries: Retry failed operations
          4. Conditional failures: Custom failure conditions
          5. Assertions: System validation
          
          All strategies are useful in different scenarios.
```

## Running the Labs

### Execute Task Results Demo

```bash
# First run - will show CHANGED for new resources
ansible-playbook -i hosts.ini task_results_demo.yml

# Second run - will show OK for existing resources
ansible-playbook -i hosts.ini task_results_demo.yml
```

### Execute Advanced Results Handling

```bash
# Run advanced results handling
ansible-playbook -i hosts.ini advanced_results_handling.yml

# Run with verbose output to see detailed results
ansible-playbook -i hosts.ini advanced_results_handling.yml -v
```

### Execute Error Handling Demo

```bash
# Run error handling demonstration
ansible-playbook -i hosts.ini error_handling_demo.yml

# Run multiple times to see different random outcomes
ansible-playbook -i hosts.ini error_handling_demo.yml
```

## Understanding Output Colors

### Standard Ansible Colors
- 🟢 **Green (OK)**: Task completed, no changes made
- 🟡 **Yellow (CHANGED)**: Task completed, changes made to system
- 🔴 **Red (FAILED)**: Task failed to complete
- 🔵 **Cyan (SKIPPED)**: Task was skipped due to conditions
- 🟣 **Purple (UNREACHABLE)**: Host was unreachable

### Example Output Analysis

```
TASK [Create a new file] *******************************************************
changed: [target1]                    # Yellow - file was created

TASK [File already exists] ****************************************************
ok: [target1]                        # Green - file unchanged

TASK [Try to access non-existent file] ***************************************
failed: [target1]                    # Red - task failed

TASK [Conditional task] *******************************************************
skipping: [target1]                  # Cyan - condition was false
```

## Best Practices for Result Handling

### 1. Always Register Important Results

```yaml
- name: Critical operation
  service:
    name: nginx
    state: started
  register: service_result
  
- name: Act on result
  debug:
    msg: "Service start result: {{ service_result.changed }}"
```

### 2. Use Appropriate Error Handling

```yaml
# For optional operations
- name: Optional cleanup
  file:
    path: /tmp/optional-file
    state: absent
  ignore_errors: yes

# For critical operations  
- name: Critical service
  service:
    name: critical-service
    state: started
  # Don't ignore errors - let playbook fail
```

### 3. Custom Changed/Failed Conditions

```yaml
- name: Custom logic
  shell: my-custom-script.sh
  register: script_result
  changed_when: "'MODIFIED' in script_result.stdout"
  failed_when: script_result.rc > 2
```

### 4. Meaningful Task Names

```yaml
# Good - descriptive names
- name: "Install nginx web server"
- name: "Configure firewall for web traffic"
- name: "Verify service is running and accessible"

# Bad - generic names  
- name: "Install package"
- name: "Copy file"
- name: "Run command"
```

## Troubleshooting Task Results

### Common Issues and Solutions

#### Issue 1: Task Shows Changed When It Shouldn't
```yaml
# Problem: Command always shows changed
- name: Check service status
  shell: systemctl is-active nginx

# Solution: Use changed_when
- name: Check service status  
  shell: systemctl is-active nginx
  register: service_status
  changed_when: false
```

#### Issue 2: Task Fails Unexpectedly
```yaml
# Add error handling and debugging
- name: Potentially failing task
  shell: risky-command
  register: result
  ignore_errors: yes
  
- name: Debug failure
  debug:
    var: result
  when: result.failed
```

#### Issue 3: Inconsistent Results
```yaml
# Use idempotent modules instead of shell/command
# Bad:
- shell: echo "content" > /tmp/file

# Good:
- copy:
    content: "content"
    dest: /tmp/file
```

## Key Learning Points

### Task State Understanding
1. **OK**: System already in desired state
2. **Changed**: System modified to reach desired state
3. **Failed**: Unable to reach desired state
4. **Skipped**: Task not applicable due to conditions

### Result Attributes
- `changed`: Boolean indicating if task made changes
- `failed`: Boolean indicating if task failed
- `rc`: Return code for shell/command tasks
- `stdout`: Standard output from task
- `stderr`: Standard error from task

### Error Handling Strategies
1. **ignore_errors**: Continue despite failures
2. **block/rescue/always**: Structured error handling
3. **until/retries**: Retry mechanisms
4. **failed_when**: Custom failure conditions
5. **assert**: Validation checks

### Best Practices
1. Always register results for important tasks
2. Use appropriate error handling for each situation
3. Write descriptive task names
4. Prefer idempotent modules over shell commands
5. Use custom changed/failed conditions when needed

Understanding task results is crucial for building reliable, maintainable Ansible automation!
