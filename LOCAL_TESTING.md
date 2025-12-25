# Local Testing Guide

This guide provides commands to test the infrastructure automation scripts on your local machine (localhost).

## Prerequisites

1. **Install Ansible:**
   ```bash
   # macOS
   brew install ansible
   
   # Linux
   sudo apt install ansible
   
   # Or via pip
   pip3 install ansible
   ```

2. **Install whiptail:**
   ```bash
   # macOS
   brew install newt
   
   # Linux
   sudo apt install whiptail
   ```

3. **Verify sudo access:**
   ```bash
   sudo -v
   ```

## Step 1: Test Ansible Connectivity

Test that Ansible can connect to localhost:

```bash
# Test ping to localhost (no sudo required)
ansible all -i inventory/local.ini -m ping

# Expected output:
# localhost | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

**Note:** The `inventory/local.ini` is configured with `ansible_become=no` so ping works without sudo. For playbooks that need sudo, they will still use `become: yes` explicitly.

If this fails with sudo errors, you can also test without become:
```bash
ansible all -i inventory/local.ini -m ping --become=no
```

If this fails, ensure Python 3 is installed:
```bash
python3 --version
```

## Step 2: Test Inventory

Verify the local inventory works:

```bash
# View local inventory
cat inventory/local.ini

# Test with local inventory
ansible all -i inventory/local.ini -m command -a "whoami"
```

## Step 3: Test Playbook Syntax

Check all playbooks for syntax errors (safe, no changes):

```bash
# Test individual playbook
ansible-playbook --syntax-check playbooks/basic.yml

# Test all server playbooks
for playbook in playbooks/*.yml; do
    echo "Checking $playbook..."
    ansible-playbook --syntax-check "$playbook"
done

# Test all utility playbooks
for playbook in playbooks/utils/*.yml; do
    echo "Checking $playbook..."
    ansible-playbook --syntax-check "$playbook"
done
```

## Step 4: Dry-Run Testing (Check Mode)

Test playbooks in check mode (shows what would change without making changes):

```bash
# Test basic server setup (dry-run)
ansible-playbook -i inventory/local.ini playbooks/basic.yml --check

# Test with verbose output
ansible-playbook -i inventory/local.ini playbooks/basic.yml --check -v

# Test database setup (dry-run)
ansible-playbook -i inventory/local.ini playbooks/db.yml --check

# Test utility - docker status (read-only, safe)
ansible-playbook -i inventory/local.ini playbooks/utils/docker_status.yml
```

## Step 5: Test Individual Roles

Test roles in isolation:

```bash
# Create a minimal test playbook
cat > /tmp/test_python.yml << 'EOF'
---
- hosts: localhost
  become: yes
  roles:
    - python
EOF

# Test Python role (dry-run)
ansible-playbook -i inventory/local.ini /tmp/test_python.yml --check

# Test Node.js role
cat > /tmp/test_nodejs.yml << 'EOF'
---
- hosts: localhost
  become: yes
  roles:
    - nodejs
EOF
ansible-playbook -i inventory/local.ini /tmp/test_nodejs.yml --check
```

## Step 6: Test TUI with Localhost

Test the TUI interface targeting localhost:

```bash
# Run TUI
./tui.sh

# In the TUI:
# 1. Select "Server Configurations"
# 2. Select "Basic server" (or any config)
# 3. Select "localhost" when prompted
# 4. Review the execution plan
```

**Note:** The TUI will use `inventory/local.ini` when localhost is selected.

## Step 7: Actual Execution (WARNING: Installs Software)

** WARNING: These commands will actually install software on your local machine!**

Only run these if you want to test the actual installation:

```bash
# Install basic server (Python + Node.js)
ansible-playbook -i inventory/local.ini playbooks/basic.yml

# Install Docker only
ansible-playbook -i inventory/local.ini playbooks/utils/docker.yml -e "action=install"

# Check Docker status (safe, read-only)
ansible-playbook -i inventory/local.ini playbooks/utils/docker_status.yml
```

## Step 8: Test Utility Functions

### Test Port Management (Dry-Run)

```bash
# Test blocking a port (dry-run)
ansible-playbook -i inventory/local.ini playbooks/utils/ports.yml \
  -e "action=block port=8080 protocol=tcp" --check

# Test unblocking a port (dry-run)
ansible-playbook -i inventory/local.ini playbooks/utils/ports.yml \
  -e "action=unblock port=8080 protocol=tcp" --check
```

### Test Docker Status (Safe, Read-Only)

```bash
# Check Docker status (no changes, safe)
ansible-playbook -i inventory/local.ini playbooks/utils/docker_status.yml
```

### Test Nginx Setup (Dry-Run)

```bash
# Test nginx setup (dry-run)
ansible-playbook -i inventory/local.ini playbooks/utils/nginx.yml \
  -e "domain=test.local server_port=3000 enable_ssl=no" --check
```

## Step 9: Test with Verbose Output

Get detailed output to see what Ansible is doing:

```bash
# Verbose output (level 1)
ansible-playbook -i inventory/local.ini playbooks/basic.yml --check -v

# More verbose (level 2)
ansible-playbook -i inventory/local.ini playbooks/basic.yml --check -vv

# Maximum verbosity (level 3)
ansible-playbook -i inventory/local.ini playbooks/basic.yml --check -vvv
```

## Step 10: Test Specific Tasks

Run only specific tasks from a playbook:

```bash
# List all tasks in a playbook
ansible-playbook -i inventory/local.ini playbooks/basic.yml --list-tasks

# Run only specific tasks (use tags if available)
ansible-playbook -i inventory/local.ini playbooks/basic.yml --check --tags "python"
```

## Complete Local Test Sequence

Here's a complete sequence to test everything locally:

```bash
#!/bin/bash
# Complete local testing sequence

echo "=== Local Testing Sequence ==="
echo ""

# 1. Test connectivity
echo "1. Testing Ansible connectivity..."
ansible all -i inventory/local.ini -m ping
echo ""

# 2. Test syntax
echo "2. Testing playbook syntax..."
ansible-playbook --syntax-check playbooks/basic.yml
echo ""

# 3. Test dry-run
echo "3. Testing basic playbook (dry-run)..."
ansible-playbook -i inventory/local.ini playbooks/basic.yml --check
echo ""

# 4. Test utility (read-only)
echo "4. Testing Docker status utility..."
ansible-playbook -i inventory/local.ini playbooks/utils/docker_status.yml 2>/dev/null || echo "Docker not installed (expected)"
echo ""

# 5. Test TUI
echo "5. Testing TUI..."
echo "Run: ./tui.sh"
echo "   Select: Server Configurations"
echo "   Select: Basic server"
echo "   Select: localhost"
echo ""

echo "=== Testing Complete ==="
```

## Quick Reference Commands

### Safe Commands (No Changes)
```bash
# Syntax check
ansible-playbook --syntax-check playbooks/basic.yml

# Dry-run (check mode)
ansible-playbook -i inventory/local.ini playbooks/basic.yml --check

# List tasks
ansible-playbook -i inventory/local.ini playbooks/basic.yml --list-tasks

# Test connectivity
ansible all -i inventory/local.ini -m ping

# Docker status (read-only)
ansible-playbook -i inventory/local.ini playbooks/utils/docker_status.yml
```

### Commands That Make Changes
```bash
# ⚠️ WARNING: These install software!

# Install basic server
ansible-playbook -i inventory/local.ini playbooks/basic.yml

# Install Docker
ansible-playbook -i inventory/local.ini playbooks/utils/docker.yml -e "action=install"

# Block a port
ansible-playbook -i inventory/local.ini playbooks/utils/ports.yml \
  -e "action=block port=8080 protocol=tcp"
```

## Troubleshooting Local Testing

### Issue: "Permission denied"
```bash
# Ensure you have sudo access
sudo -v

# Test sudo with Ansible
ansible all -i inventory/local.ini -m command -a "whoami" --become
```

### Issue: "Python not found"
```bash
# Check Python version
python3 --version

# Install Python if needed (macOS)
brew install python3

# Install Python if needed (Linux)
sudo apt install python3
```

### Issue: "Module not found"
```bash
# Install required Python modules
pip3 install ansible

# Or install system packages
sudo apt install python3-apt python3-pip  # Linux
```

### Issue: Playbook fails
```bash
# Run with verbose output to see errors
ansible-playbook -i inventory/local.ini playbooks/basic.yml -vvv

# Check Ansible version
ansible --version

# Verify playbook syntax
ansible-playbook --syntax-check playbooks/basic.yml
```

## Testing Checklist

- [ ] Ansible installed and working
- [ ] Can ping localhost with Ansible
- [ ] Playbook syntax checks pass
- [ ] Dry-run tests complete successfully
- [ ] TUI works and shows localhost option
- [ ] Utility functions work (docker_status, etc.)
- [ ] Ready to test on remote servers

## Next Steps After Local Testing

Once local testing passes:
1. Configure `inventory/hosts.json` with remote servers
2. Test SSH connectivity to remote servers
3. Test with one remote server using `./tui.sh`
4. Gradually roll out to other servers

