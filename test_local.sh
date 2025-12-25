#!/bin/bash
# Quick local testing script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Local Server Testing ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test 1: Ansible connectivity
echo "1. Testing Ansible connectivity to localhost..."
if ansible all -i inventory/local.ini -m ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC} - Ansible can connect to localhost"
else
    echo -e "${RED}✗ FAIL${NC} - Cannot connect to localhost"
    echo "   Install Python 3 if missing: python3 --version"
    exit 1
fi
echo ""

# Test 2: Playbook syntax
echo "2. Testing playbook syntax..."
SYNTAX_ERRORS=0
for playbook in playbooks/basic.yml playbooks/db.yml playbooks/utils/docker_status.yml; do
    if [ -f "$playbook" ]; then
        if ansible-playbook --syntax-check "$playbook" > /dev/null 2>&1; then
            echo -e "   ${GREEN}✓${NC} $playbook"
        else
            echo -e "   ${RED}✗${NC} $playbook"
            SYNTAX_ERRORS=$((SYNTAX_ERRORS+1))
        fi
    fi
done

if [ $SYNTAX_ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} - All playbooks have valid syntax"
else
    echo -e "${RED}✗ FAIL${NC} - $SYNTAX_ERRORS syntax errors"
    echo "   Install Ansible: brew install ansible or pip3 install ansible"
    exit 1
fi
echo ""

# Test 3: Dry-run basic playbook
echo "3. Testing basic playbook (dry-run - no changes)..."
if ansible-playbook -i inventory/local.ini playbooks/basic.yml --check > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC} - Basic playbook dry-run successful"
else
    echo -e "${YELLOW}⚠ WARNING${NC} - Dry-run had issues (may need sudo or packages)"
fi
echo ""

# Test 4: Docker status (read-only, safe)
echo "4. Testing Docker status utility (read-only)..."
if ansible-playbook -i inventory/local.ini playbooks/utils/docker_status.yml > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC} - Docker status utility works"
else
    echo -e "${YELLOW}⚠ SKIP${NC} - Docker not installed (expected if not set up)"
fi
echo ""

# Test 5: TUI script
echo "5. Testing TUI script..."
if [ -x ./tui.sh ]; then
    echo -e "${GREEN}✓ PASS${NC} - TUI script is executable"
    echo ""
    echo "   To test TUI interactively, run:"
    echo "   ${YELLOW}./tui.sh${NC}"
    echo ""
    echo "   Then:"
    echo "   1. Select 'Server Configurations'"
    echo "   2. Select 'Basic server'"
    echo "   3. Select 'localhost'"
    echo "   4. Review the execution plan"
else
    echo -e "${RED}✗ FAIL${NC} - TUI script not executable"
    echo "   Run: chmod +x tui.sh"
fi
echo ""

echo "=== Test Summary ==="
echo ""
echo "To test locally, use these commands:"
echo ""
echo "${GREEN}# 1. Test connectivity${NC}"
echo "ansible all -i inventory/local.ini -m ping"
echo ""
echo "${GREEN}# 2. Test playbook syntax${NC}"
echo "ansible-playbook --syntax-check playbooks/basic.yml"
echo ""
echo "${GREEN}# 3. Dry-run (no changes)${NC}"
echo "ansible-playbook -i inventory/local.ini playbooks/basic.yml --check"
echo ""
echo "${GREEN}# 4. Test TUI${NC}"
echo "./tui.sh"
echo "   # Select: Server Configurations"
echo "   # Select: Basic server"
echo "   # Select: localhost"
echo ""
echo "${YELLOW}# 5. Actual execution (WARNING: Installs software!)${NC}"
echo "ansible-playbook -i inventory/local.ini playbooks/basic.yml"
echo ""
echo "For detailed testing instructions, see: LOCAL_TESTING.md"

