#!/bin/bash
# Quick local test - no sudo required for ping

echo "=== Quick Local Test (No Sudo Required) ==="
echo ""

echo "Testing Ansible connectivity..."
ansible all -i inventory/local.ini -m ping

echo ""
echo "✓ If you see 'SUCCESS' above, Ansible is working!"
echo ""
echo "Next steps:"
echo "1. Test playbook syntax: ansible-playbook --syntax-check playbooks/basic.yml"
echo "2. Test dry-run: ansible-playbook -i inventory/local.ini playbooks/basic.yml --check"
echo "3. Test TUI: ./tui.sh"

