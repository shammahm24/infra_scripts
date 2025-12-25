#!/usr/bin/env python3
"""
Generate Ansible inventory from JSON host configuration.
This allows dynamic host management without hardcoding IPs in version control.
"""

import json
import sys
import os
from pathlib import Path


def load_hosts_json(json_path):
    """Load hosts configuration from JSON file."""
    try:
        with open(json_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: {json_path} not found", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in {json_path}: {e}", file=sys.stderr)
        sys.exit(1)


def generate_inventory(hosts_data):
    """Generate Ansible inventory format from JSON data."""
    inventory = []
    
    # Process groups first
    groups = hosts_data.get('groups', {})
    for group_name, group_vars in groups.items():
        inventory.append(f"[{group_name}]")
        # Add hosts to this group
        for host in hosts_data.get('hosts', []):
            if group_name in host.get('groups', []):
                host_line = host['name']
                if 'ip' in host:
                    host_line += f" ansible_host={host['ip']}"
                if 'user' in host:
                    host_line += f" ansible_user={host['user']}"
                if 'ssh_key' in host:
                    host_line += f" ansible_ssh_private_key_file={host['ssh_key']}"
                if 'ansible_python_interpreter' in host:
                    host_line += f" ansible_python_interpreter={host['ansible_python_interpreter']}"
                inventory.append(host_line)
        inventory.append("")
    
    # Add ungrouped hosts
    ungrouped = [h for h in hosts_data.get('hosts', []) if not h.get('groups')]
    if ungrouped:
        inventory.append("[ungrouped]")
        for host in ungrouped:
            host_line = host['name']
            if 'ip' in host:
                host_line += f" ansible_host={host['ip']}"
            if 'user' in host:
                host_line += f" ansible_user={host['user']}"
            if 'ssh_key' in host:
                host_line += f" ansible_ssh_private_key_file={host['ssh_key']}"
            if 'ansible_python_interpreter' in host:
                host_line += f" ansible_python_interpreter={host['ansible_python_interpreter']}"
            inventory.append(host_line)
        inventory.append("")
    
    # Add all hosts group
    inventory.append("[all:vars]")
    inventory.append("ansible_ssh_common_args='-o StrictHostKeyChecking=no'")
    
    return "\n".join(inventory)


def main():
    """Main entry point for inventory generation."""
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    json_path = project_root / "inventory" / "hosts.json"
    
    # Check if JSON file exists
    if not json_path.exists():
        print(f"Warning: {json_path} not found. Using empty inventory.", file=sys.stderr)
        print("")
        return
    
    hosts_data = load_hosts_json(json_path)
    inventory = generate_inventory(hosts_data)
    print(inventory)


if __name__ == "__main__":
    main()

