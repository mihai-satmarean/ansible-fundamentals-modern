# Module 4: Raw vs Command vs Shell Modules Comparison

## Objective
Understand the key differences between Raw, Command, and Shell modules in Ansible and learn their appropriate use cases through hands-on examples.

## Prerequisites
- Ansible properly configured
- Access to target hosts
- Basic understanding of Linux commands

## Module Overview

### Raw Module
- **Purpose**: Execute raw commands directly on target hosts
- **Use Case**: Bootstrap systems, systems without Python
- **Characteristics**: No Python required, no module processing
- **Security**: Least secure, direct shell access

### Command Module
- **Purpose**: Execute commands safely without shell features
- **Use Case**: Simple command execution, secure environments
- **Characteristics**: No shell features (pipes, redirects, variables)
- **Security**: Most secure, prevents shell injection

### Shell Module
- **Purpose**: Execute commands with full shell capabilities
- **Use Case**: Complex commands requiring shell features
- **Characteristics**: Full shell access (pipes, redirects, variables)
- **Security**: Less secure, allows shell injection

## Lab Setup

### Create Inventory
Create `hosts.ini`:

```ini
[lab_hosts]
target1 ansible_host=192.168.1.101 ansible_user=ansibleuser

[lab_hosts:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### Create Test Playbook

Create `command_types_lab.yml`:

```yaml
---
- name: Explore Raw vs Command vs Shell Modules
  hosts: lab_hosts
  gather_facts: no  # Disable fact gathering to speed up the playbook
  vars:
    test_file: /tmp/ansible-test.txt
    test_dir: /tmp/ansible-test-dir
    
  tasks:
    # RAW MODULE EXAMPLES
    - name: "RAW: Execute simple echo command"
      raw: echo "Hello from Raw Module - $(date)"
      register: raw_output
      
    - name: "RAW: Create directory using raw command"
      raw: mkdir -p {{ test_dir }}
      
    - name: "RAW: Write file with shell redirection"
      raw: echo "Created by Raw module" > {{ test_file }}
      
    - name: "RAW: Complex command with pipes and variables"
      raw: |
        export TEST_VAR="Raw Module Test"
        echo "Environment variable: $TEST_VAR" | tee -a {{ test_file }}
        ls -la {{ test_dir }} | head -3
      register: raw_complex
      
    # COMMAND MODULE EXAMPLES  
    - name: "COMMAND: Execute simple echo command"
      command: echo "Hello from Command Module"
      register: command_output
      
    - name: "COMMAND: List directory contents"
      command: ls -la /tmp
      register: command_ls
      
    - name: "COMMAND: Execute with arguments"
      command: cat {{ test_file }}
      register: command_cat
      ignore_errors: yes
      
    - name: "COMMAND: Try shell features (will fail)"
      command: echo "This will fail" > /tmp/command-fail.txt
      register: command_fail
      ignore_errors: yes
      
    - name: "COMMAND: Try pipe (will fail)"
      command: ls -la /tmp | grep ansible
      register: command_pipe_fail
      ignore_errors: yes
      
    # SHELL MODULE EXAMPLES
    - name: "SHELL: Execute simple echo command"
      shell: echo "Hello from Shell Module - $(hostname)"
      register: shell_output
      
    - name: "SHELL: Use shell redirection"
      shell: echo "Created by Shell module" >> {{ test_file }}
      
    - name: "SHELL: Complex command with pipes"
      shell: |
        ls -la /tmp | grep ansible | wc -l
      register: shell_pipe
      
    - name: "SHELL: Use environment variables"
      shell: |
        export SHELL_VAR="Shell Module Test"
        echo "Current user: $(whoami), Variable: $SHELL_VAR"
      register: shell_env
      
    - name: "SHELL: Command substitution and conditional"
      shell: |
        if [ -f {{ test_file }} ]; then
          echo "File exists, content:"
          cat {{ test_file }}
        else
          echo "File does not exist"
        fi
      register: shell_conditional
      
    # COMPARISON EXAMPLES
    - name: "COMPARISON: File operations"
      block:
        - name: "RAW: Check file existence"
          raw: test -f {{ test_file }} && echo "exists" || echo "not found"
          register: raw_check
          
        - name: "COMMAND: Check file with stat"
          command: stat {{ test_file }}
          register: command_stat
          ignore_errors: yes
          
        - name: "SHELL: Check file with test"
          shell: test -f {{ test_file }} && echo "exists" || echo "not found"
          register: shell_check
          
    # DISPLAY RESULTS
    - name: "RESULTS: Raw module outputs"
      debug:
        msg: |
          Raw simple: {{ raw_output.stdout }}
          Raw complex: {{ raw_complex.stdout_lines }}
          Raw file check: {{ raw_check.stdout }}
          
    - name: "RESULTS: Command module outputs"
      debug:
        msg: |
          Command simple: {{ command_output.stdout }}
          Command ls: {{ command_ls.stdout_lines | length }} lines
          Command cat: {{ command_cat.stdout | default('Failed') }}
          Command fail: {{ command_fail.failed | default(false) }}
          Command pipe fail: {{ command_pipe_fail.failed | default(false) }}
          
    - name: "RESULTS: Shell module outputs"
      debug:
        msg: |
          Shell simple: {{ shell_output.stdout }}
          Shell pipe count: {{ shell_pipe.stdout }}
          Shell env: {{ shell_env.stdout }}
          Shell conditional: {{ shell_conditional.stdout_lines }}
```

## Advanced Examples

### Create Advanced Comparison Playbook

Create `advanced_module_comparison.yml`:

```yaml
---
- name: Advanced Module Comparison
  hosts: lab_hosts
  gather_facts: yes
  vars:
    log_file: /tmp/module-test.log
    
  tasks:
    # PERFORMANCE COMPARISON
    - name: "PERFORMANCE: Time Raw execution"
      raw: time echo "Raw performance test"
      register: raw_time
      
    - name: "PERFORMANCE: Time Command execution"
      command: echo "Command performance test"
      register: command_time
      
    - name: "PERFORMANCE: Time Shell execution"
      shell: echo "Shell performance test"
      register: shell_time
      
    # ERROR HANDLING
    - name: "ERROR: Raw with bad command"
      raw: nonexistent_command
      register: raw_error
      ignore_errors: yes
      
    - name: "ERROR: Command with bad command"
      command: nonexistent_command
      register: command_error
      ignore_errors: yes
      
    - name: "ERROR: Shell with bad command"
      shell: nonexistent_command
      register: shell_error
      ignore_errors: yes
      
    # SECURITY DEMONSTRATION
    - name: "SECURITY: Command prevents injection"
      command: echo "safe input"
      vars:
        user_input: "safe input; rm -rf /"
      register: command_safe
      
    - name: "SECURITY: Shell allows injection (be careful!)"
      shell: echo "{{ safe_input | quote }}"
      vars:
        safe_input: "safe input"
      register: shell_safe
      
    # COMPLEX OPERATIONS
    - name: "COMPLEX: Raw system information"
      raw: |
        echo "=== System Information ===" > {{ log_file }}
        echo "Hostname: $(hostname)" >> {{ log_file }}
        echo "Date: $(date)" >> {{ log_file }}
        echo "Uptime: $(uptime)" >> {{ log_file }}
        echo "Disk usage:" >> {{ log_file }}
        df -h / >> {{ log_file }}
        cat {{ log_file }}
      register: raw_sysinfo
      
    - name: "COMPLEX: Multiple commands with Shell"
      shell: |
        {
          echo "=== Process Information ==="
          ps aux | head -5
          echo "=== Memory Information ==="
          free -m
          echo "=== Network Information ==="
          ip addr show | grep -E "inet |UP"
        } | tee -a {{ log_file }}
      register: shell_sysinfo
      
    # WHEN TO USE EACH MODULE
    - name: "USE CASE: Bootstrap with Raw (no Python)"
      raw: |
        # This would be used on systems without Python
        which python3 || echo "Python not found - Raw module needed"
        
    - name: "USE CASE: Safe command execution with Command"
      command: "{{ item }}"
      loop:
        - whoami
        - pwd
        - date
        - hostname
      register: command_safe_ops
      
    - name: "USE CASE: Complex shell operations with Shell"
      shell: |
        # Complex operations requiring shell features
        for i in {1..3}; do
          echo "Iteration $i: $(date)" >> {{ log_file }}
        done
        
        # Process monitoring
        ps aux | awk '{print $1, $2, $11}' | head -10 >> {{ log_file }}
        
        # Conditional operations
        if [ $(free -m | awk 'NR==2{print $3}') -gt 1000 ]; then
          echo "High memory usage detected" >> {{ log_file }}
        fi
      
    # CLEANUP AND RESULTS
    - name: "CLEANUP: Remove test files"
      file:
        path: "{{ item }}"
        state: absent
      loop:
        - "{{ log_file }}"
        - /tmp/ansible-test.txt
        - /tmp/ansible-test-dir
        
    - name: "SUMMARY: Module comparison results"
      debug:
        msg: |
          === MODULE COMPARISON SUMMARY ===
          
          RAW MODULE:
          - Best for: System bootstrap, no Python environments
          - Security: Lowest (direct shell access)
          - Features: Full shell capabilities
          - Error output: {{ raw_error.failed | default(false) }}
          
          COMMAND MODULE:
          - Best for: Simple, secure command execution
          - Security: Highest (no shell injection)
          - Features: Limited (no pipes, redirects, variables)
          - Error output: {{ command_error.failed | default(false) }}
          
          SHELL MODULE:
          - Best for: Complex operations requiring shell features
          - Security: Medium (potential for injection)
          - Features: Full shell capabilities with safety
          - Error output: {{ shell_error.failed | default(false) }}
```

## Decision Matrix

### When to Use Each Module

| Scenario | Raw | Command | Shell | Reason |
|----------|-----|---------|-------|--------|
| Bootstrap system without Python | ✅ | ❌ | ❌ | Raw doesn't require Python |
| Simple file operations | ❌ | ✅ | ❌ | Command is safer |
| User input processing | ❌ | ✅ | ❌ | Command prevents injection |
| Complex pipes and redirects | ❌ | ❌ | ✅ | Shell provides full features |
| Environment variable usage | ✅ | ❌ | ✅ | Command doesn't support variables |
| Conditional operations | ✅ | ❌ | ✅ | Command doesn't support conditionals |
| Security-critical environments | ❌ | ✅ | ❌ | Command is most secure |
| Legacy system management | ✅ | ❌ | ❌ | Raw works on older systems |

## Running the Labs

### Execute Basic Comparison

```bash
# Run the basic comparison
ansible-playbook -i hosts.ini command_types_lab.yml

# Run with verbose output to see differences
ansible-playbook -i hosts.ini command_types_lab.yml -v
```

### Execute Advanced Comparison

```bash
# Run advanced comparison
ansible-playbook -i hosts.ini advanced_module_comparison.yml

# Focus on specific tags if created
ansible-playbook -i hosts.ini advanced_module_comparison.yml --tags security
```

## Expected Results Analysis

### Raw Module Results
- ✅ **Success**: All commands execute, including complex shell operations
- ✅ **Features**: Pipes, redirects, variables, command substitution all work
- ⚠️ **Security**: Direct shell access - potential security risk

### Command Module Results  
- ✅ **Success**: Simple commands work perfectly
- ❌ **Failure**: Shell features (pipes, redirects) fail with error messages
- ✅ **Security**: Safe from shell injection attacks

### Shell Module Results
- ✅ **Success**: All shell features work as expected
- ✅ **Features**: Full shell capabilities with Ansible safety features
- ⚠️ **Security**: Potential for injection if not careful with input

## Best Practices

### Security Guidelines

```yaml
# GOOD: Using command for user input
- name: Safe user input handling
  command: echo "{{ user_input | quote }}"
  
# BAD: Using shell with unfiltered input  
- name: Unsafe user input (vulnerable to injection)
  shell: echo {{ user_input }}
  
# GOOD: Using shell with proper quoting
- name: Safe shell usage
  shell: echo "{{ user_input | quote }}"
```

### Performance Considerations

```yaml
# GOOD: Use command for simple operations
- name: Fast and secure
  command: ls /tmp
  
# UNNECESSARY: Using shell for simple operations
- name: Slower and less secure
  shell: ls /tmp
  
# GOOD: Use shell when you need shell features
- name: Appropriate shell usage
  shell: ls /tmp | grep ansible | wc -l
```

### Error Handling

```yaml
# Handle module-specific errors
- name: Command with error handling
  command: some-command
  register: result
  failed_when: result.rc > 1  # Custom failure condition
  
- name: Shell with error handling
  shell: complex-shell-operation
  register: result
  ignore_errors: yes
  
- name: Check shell operation result
  fail:
    msg: "Shell operation failed: {{ result.stderr }}"
  when: result.failed
```

## Troubleshooting Common Issues

### Command Module Limitations

```bash
# This FAILS with command module:
ansible lab_hosts -m command -a "echo hello > /tmp/test.txt"

# Use shell instead:
ansible lab_hosts -m shell -a "echo hello > /tmp/test.txt"

# Or better, use copy module:
ansible lab_hosts -m copy -a "content='hello' dest=/tmp/test.txt"
```

### Raw Module Issues

```bash
# Raw module may fail if target system is unusual
ansible lab_hosts -m raw -a "python3 --version"

# Check what's available:
ansible lab_hosts -m raw -a "which python3 python python2"
```

### Shell Module Security

```bash
# Dangerous - don't do this:
ansible lab_hosts -m shell -a "rm -rf {{ user_provided_path }}"

# Safe approach:
ansible lab_hosts -m file -a "path={{ user_provided_path | quote }} state=absent"
```

## Key Learning Points

### Module Characteristics
1. **Raw**: Direct execution, no Python required, full shell access
2. **Command**: Secure execution, Python required, no shell features
3. **Shell**: Controlled shell access, Python required, full features

### Security Implications
1. **Command**: Safest - prevents shell injection
2. **Shell**: Moderate risk - requires careful input handling  
3. **Raw**: Highest risk - direct shell access

### Performance Considerations
1. **Command**: Fastest - minimal overhead
2. **Shell**: Slower - shell processing overhead
3. **Raw**: Variable - depends on target system

### Use Case Guidelines
1. **Bootstrap/Legacy systems**: Raw module
2. **Simple, secure operations**: Command module
3. **Complex shell operations**: Shell module
4. **User input processing**: Command module (with proper validation)

This comprehensive comparison helps you choose the right module for each situation while maintaining security and performance!
