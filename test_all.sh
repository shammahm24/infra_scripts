#!/bin/bash
# Comprehensive test script for infrastructure automation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Infrastructure Automation Test Suite ==="
echo ""

PASSED=0
FAILED=0

# Test 1: Inventory generator
echo "1. Testing inventory generator..."
if python3 scripts/generate_inventory.py > /dev/null 2>&1; then
    echo "   ✓ PASS - Inventory generator works"
    PASSED=$((PASSED+1))
else
    echo "   ✗ FAIL - Inventory generator has errors"
    FAILED=$((FAILED+1))
fi

# Test 2: Ansible installation
echo "2. Testing Ansible installation..."
if command -v ansible > /dev/null 2>&1; then
    ANSIBLE_VERSION=$(ansible --version | head -n1)
    echo "   ✓ PASS - $ANSIBLE_VERSION"
    PASSED=$((PASSED+1))
else
    echo "   ✗ FAIL - Ansible not installed"
    FAILED=$((FAILED+1))
fi

# Test 3: whiptail installation
echo "3. Testing whiptail installation..."
if command -v whiptail > /dev/null 2>&1; then
    echo "   ✓ PASS - whiptail installed"
    PASSED=$((PASSED+1))
else
    echo "   ✗ FAIL - whiptail not installed (install with: brew install newt or apt install whiptail)"
    FAILED=$((FAILED+1))
fi

# Test 4: TUI script executable
echo "4. Testing TUI script..."
if [ -x ./tui.sh ]; then
    echo "   ✓ PASS - tui.sh is executable"
    PASSED=$((PASSED+1))
else
    echo "   ✗ FAIL - tui.sh is not executable (run: chmod +x tui.sh)"
    FAILED=$((FAILED+1))
fi

# Test 5: Playbook syntax
echo "5. Testing playbook syntax..."
SYNTAX_ERRORS=0
TOTAL_PLAYBOOKS=0

for playbook in playbooks/*.yml playbooks/utils/*.yml; do
    if [ -f "$playbook" ]; then
        TOTAL_PLAYBOOKS=$((TOTAL_PLAYBOOKS+1))
        if ! ansible-playbook --syntax-check "$playbook" > /dev/null 2>&1; then
            SYNTAX_ERRORS=$((SYNTAX_ERRORS+1))
            echo "   ✗ Syntax error in: $playbook"
        fi
    fi
done

if [ $SYNTAX_ERRORS -eq 0 ] && [ $TOTAL_PLAYBOOKS -gt 0 ]; then
    echo "   ✓ PASS - All $TOTAL_PLAYBOOKS playbooks have valid syntax"
    PASSED=$((PASSED+1))
else
    echo "   ✗ FAIL - $SYNTAX_ERRORS syntax errors in $TOTAL_PLAYBOOKS playbooks"
    FAILED=$((FAILED+1))
fi

# Test 6: Ansible connectivity (localhost)
echo "6. Testing Ansible connectivity (localhost)..."
if ansible all -i inventory/local.ini -m ping > /dev/null 2>&1; then
    echo "   ✓ PASS - Can connect to localhost"
    PASSED=$((PASSED+1))
else
    echo "   ⚠ SKIP - Cannot connect to localhost (may require sudo or Python on localhost)"
fi

# Test 7: Dynamic inventory (if hosts.json exists)
echo "7. Testing dynamic inventory..."
if [ -f inventory/hosts.json ]; then
    if ansible all -i scripts/generate_inventory.py -m ping > /dev/null 2>&1; then
        echo "   ✓ PASS - Dynamic inventory works"
        PASSED=$((PASSED+1))
    else
        echo "   ⚠ SKIP - Dynamic inventory generated but hosts not reachable (expected if no remote hosts configured)"
    fi
else
    echo "   ⚠ SKIP - hosts.json not found (create it to test dynamic inventory)"
fi

# Test 8: Required directories
echo "8. Testing directory structure..."
REQUIRED_DIRS=("playbooks" "playbooks/utils" "roles" "scripts" "inventory")
MISSING_DIRS=0
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "   ✗ Missing directory: $dir"
        MISSING_DIRS=$((MISSING_DIRS+1))
    fi
done

if [ $MISSING_DIRS -eq 0 ]; then
    echo "   ✓ PASS - All required directories exist"
    PASSED=$((PASSED+1))
else
    echo "   ✗ FAIL - $MISSING_DIRS directories missing"
    FAILED=$((FAILED+1))
fi

# Test 9: Required files
echo "9. Testing required files..."
REQUIRED_FILES=("tui.sh" "ansible.cfg" "scripts/generate_inventory.py")
MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "   ✗ Missing file: $file"
        MISSING_FILES=$((MISSING_FILES+1))
    fi
done

if [ $MISSING_FILES -eq 0 ]; then
    echo "   ✓ PASS - All required files exist"
    PASSED=$((PASSED+1))
else
    echo "   ✗ FAIL - $MISSING_FILES files missing"
    FAILED=$((FAILED+1))
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✓ All critical tests passed!"
    echo ""
    echo "Next steps:"
    echo "1. Configure inventory/hosts.json with your servers"
    echo "2. Test with: ./tui.sh"
    echo "3. Review TESTING.md for detailed test procedures"
    exit 0
else
    echo "✗ Some tests failed. Please fix the issues above."
    echo ""
    echo "Common fixes:"
    echo "- Install Ansible: pip3 install ansible or brew install ansible"
    echo "- Install whiptail: brew install newt or apt install whiptail"
    echo "- Make tui.sh executable: chmod +x tui.sh"
    exit 1
fi

