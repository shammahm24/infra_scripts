# Testing Guide

This guide provides step-by-step instructions for testing the infrastructure automation system.

## Prerequisites Check

Before testing, verify all required tools are installed:

```bash
# Check Python
python3 --version

# Check Ansible
ansible --version

# Check whiptail
which whiptail || echo "whiptail not found - install with: brew install newt (macOS) or apt install whiptail (Linux)"

# Check SSH (for remote testing)
ssh -V
```

### Install Missing Dependencies

**macOS:**
```bash
# Install Ansible
brew install ansible

# Install whiptail
brew install newt
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y ansible whiptail python3-pip
```

## Test 1: Inventory Generator

Test the JSON to Ansible inventory conversion:

```bash
# Test with existing hosts.json
python3 scripts/generate_inventory.py

# Expected output: Ansible inventory format with hosts from hosts.json
```

**Test with empty/missing hosts.json:**
```bash
# Backup existing hosts.json
mv inventory/hosts.json inventory/hosts.json.bak

# Test (should output empty inventory)
python3 scripts/generate_inventory.py

# Restore
mv inventory/hosts.json.bak inventory/hosts.json
```

## Test 2: Ansible Configuration

Verify Ansible can read the configuration:

```bash
# Test local inventory
ansible all -i inventory/local.ini -m ping

# Test dynamic inventory (if hosts.json exists)
ansible all -i scripts/generate_inventory.py -m ping
```

## Test 3: Playbook Syntax Check

Validate all playbooks for syntax errors:

```bash
# Test server configuration playbooks
ansible-playbook --syntax-check playbooks/basic.yml
ansible-playbook --syntax-check playbooks/db.yml
ansible-playbook --syntax-check playbooks/db_cache.yml
ansible-playbook --syntax-check playbooks/full_stack.yml
ansible-playbook --syntax-check playbooks/postgres.yml
ansible-playbook --syntax-check playbooks/redis.yml
ansible-playbook --syntax-check playbooks/garage.yml
ansible-playbook --syntax-check playbooks/coolify.yml
ansible-playbook --syntax-check playbooks/email.yml

# Test utility playbooks
ansible-playbook --syntax-check playbooks/utils/ports.yml
ansible-playbook --syntax-check playbooks/utils/nginx.yml
ansible-playbook --syntax-check playbooks/utils/docker.yml
ansible-playbook --syntax-check playbooks/utils/docker_status.yml
ansible-playbook --syntax-check playbooks/utils/letsencrypt.yml
```

**Quick syntax check script:**
```bash
# Run all syntax checks
for playbook in playbooks/*.yml playbooks/utils/*.yml; do
    echo "Checking $playbook..."
    ansible-playbook --syntax-check "$playbook" || echo "ERROR in $playbook"
done
```

## Test 4: TUI Interface (Dry Run)

Test the TUI without executing playbooks:

```bash
# Test TUI script execution (will show menus)
./tui.sh
```

**Expected behavior:**
1. Main menu appears with "Server Configurations" and "Utility Functions"
2. Selecting an option shows submenu
3. Selecting a host shows host selection menu
4. Canceling at any point exits gracefully

## Test 5: Localhost Testing (Safe)

Test playbooks on localhost (requires sudo):

```bash
# Test basic server setup (dry-run first)
ansible-playbook -i inventory/local.ini playbooks/basic.yml --check

# If check passes, run for real (WARNING: Installs software)
# ansible-playbook -i inventory/local.ini playbooks/basic.yml

# Test utility - Docker status (read-only)
ansible-playbook -i inventory/local.ini playbooks/utils/docker_status.yml
```

## Test 6: Remote Host Testing

### Setup Remote Host

1. **Configure hosts.json:**
```bash
# Edit hosts.json with your test server
cat > inventory/hosts.json << 'EOF'
{
  "hosts": [
    {
      "name": "test-server",
      "ip": "YOUR_SERVER_IP",
      "user": "ubuntu",
      "ssh_key": "~/.ssh/id_rsa",
      "groups": ["test"],
      "ansible_python_interpreter": "/usr/bin/python3"
    }
  ],
  "groups": {
    "test": {}
  }
}
EOF
```

2. **Test SSH connectivity:**
```bash
# Replace with your server details
ssh -i ~/.ssh/id_rsa ubuntu@YOUR_SERVER_IP "echo 'SSH connection successful'"
```

3. **Test Ansible connectivity:**
```bash
# Ping test
ansible all -i scripts/generate_inventory.py -m ping

# Expected output:
# test-server | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

4. **Test a simple playbook (dry-run):**
```bash
# Syntax check with remote inventory
ansible-playbook -i scripts/generate_inventory.py --limit test-server --check playbooks/basic.yml
```

5. **Test TUI with remote host:**
```bash
./tui.sh
# Select: Server Configurations
# Select: Basic server
# Select: test-server
# Review the execution plan before confirming
```

## Test 7: Role Testing

Test individual roles in isolation:

```bash
# Create a test playbook
cat > /tmp/test_role.yml << 'EOF'
---
- hosts: localhost
  become: yes
  roles:
    - python
EOF

# Test role
ansible-playbook -i inventory/local.ini /tmp/test_role.yml --check
```

## Test 8: Utility Functions Testing

### Port Management
```bash
# Test port blocking (dry-run)
ansible-playbook -i inventory/local.ini playbooks/utils/ports.yml \
  -e "action=block port=8080 protocol=tcp" --check
```

### Docker Status
```bash
# Test docker status (read-only, safe)
ansible-playbook -i inventory/local.ini playbooks/utils/docker_status.yml
```

### Nginx Setup
```bash
# Test nginx setup (dry-run)
ansible-playbook -i inventory/local.ini playbooks/utils/nginx.yml \
  -e "domain=test.example.com server_port=3000 enable_ssl=no" --check
```

## Test 9: Error Handling

Test error scenarios:

```bash
# Test with invalid host
ansible all -i scripts/generate_inventory.py --limit nonexistent -m ping
# Expected: Error about host not found

# Test with invalid playbook
ansible-playbook --syntax-check playbooks/nonexistent.yml
# Expected: File not found error

# Test TUI with missing hosts.json
mv inventory/hosts.json inventory/hosts.json.bak
./tui.sh
# Should fallback to localhost
mv inventory/hosts.json.bak inventory/hosts.json
```

## Test 10: Full Integration Test

Complete workflow test:

```bash
# 1. Verify inventory
python3 scripts/generate_inventory.py | grep -q "test-server" && echo "✓ Inventory OK"

# 2. Verify connectivity
ansible all -i scripts/generate_inventory.py -m ping && echo "✓ Connectivity OK"

# 3. Verify playbook syntax
ansible-playbook --syntax-check playbooks/basic.yml && echo "✓ Playbook syntax OK"

# 4. Test TUI (manual - verify menus work)
echo "✓ TUI test - run manually: ./tui.sh"
```

## Troubleshooting Tests

### Issue: "ansible: command not found"
```bash
# Install Ansible
pip3 install ansible
# or
brew install ansible  # macOS
```

### Issue: "whiptail: command not found"
```bash
# Install whiptail
brew install newt  # macOS
sudo apt install whiptail  # Linux
```

### Issue: "Permission denied" on SSH
```bash
# Fix SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Test SSH manually
ssh -i ~/.ssh/id_rsa user@host
```

### Issue: "Python not found" on remote host
```bash
# Install Python 3 on remote host
ssh user@host "sudo apt update && sudo apt install -y python3"
```

### Issue: Playbook fails with "become" errors
```bash
# Test sudo access
ansible all -i scripts/generate_inventory.py -m command -a "whoami" --become
```

## Quick Test Script

Create a comprehensive test script:

```bash
#!/bin/bash
# save as test_all.sh

echo "=== Infrastructure Automation Test Suite ==="
echo ""

echo "1. Testing inventory generator..."
python3 scripts/generate_inventory.py > /dev/null && echo "✓ PASS" || echo "✗ FAIL"

echo "2. Testing Ansible connectivity..."
ansible all -i inventory/local.ini -m ping > /dev/null 2>&1 && echo "✓ PASS" || echo "✗ FAIL (expected if not running as root)"

echo "3. Testing playbook syntax..."
ERRORS=0
for playbook in playbooks/*.yml playbooks/utils/*.yml; do
    ansible-playbook --syntax-check "$playbook" > /dev/null 2>&1 || ERRORS=$((ERRORS+1))
done
[ $ERRORS -eq 0 ] && echo "✓ PASS" || echo "✗ FAIL ($ERRORS errors)"

echo "4. Testing TUI script..."
[ -x ./tui.sh ] && echo "✓ PASS" || echo "✗ FAIL (not executable)"

echo ""
echo "=== Test Complete ==="
```

Make it executable and run:
```bash
chmod +x test_all.sh
./test_all.sh
```

## Safety Recommendations

1. **Always use `--check` first**: Test playbooks in check mode before actual execution
2. **Test on non-production**: Use a test server or VM first
3. **Backup before changes**: Backup important configurations before running playbooks
4. **Review playbooks**: Understand what each playbook does before running
5. **Start small**: Test basic.yml before full_stack.yml

## Next Steps After Testing

Once all tests pass:
1. Configure `inventory/hosts.json` with your production servers
2. Test with one non-critical server first
3. Gradually roll out to other servers
4. Monitor execution logs for any issues

