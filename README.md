# Infrastructure Automation Scripts

A comprehensive Ansible-based infrastructure automation tool with a Text User Interface (TUI) for managing remote servers. This tool provides server configuration management and utility functions for common infrastructure tasks.

## Features

### Server Configurations
- **Basic Server**: Python 3.11 + Latest Node.js
- **Database Server**: Python 3.11 + Node.js + PostgreSQL (with persistent storage)
- **Database + Cache**: Python 3.11 + Node.js + PostgreSQL + Redis (with persistent storage)
- **Full Stack**: Python 3.11 + Node.js + PostgreSQL + Redis + Garage (blob storage) (with persistent storage)
- **PostgreSQL Only**: Latest PostgreSQL with persistent directories
- **Redis Only**: Latest Redis
- **Garage Only**: Latest Garage (blob storage)
- **Coolify Server**: Coolify installation
- **Email Server**: Postfix + Dovecot

### Utility Functions
- **Port Management**: Block/unblock ports using UFW
- **Nginx Setup**: Configure nginx for new services or domains
- **Docker Management**: Install, status, and cleanup Docker
- **Docker Status**: View Docker networks, containers, and applications
- **Let's Encrypt**: Automated SSL certificate generation and renewal with nginx

## Architecture

This tool uses **remote execution** via Ansible over SSH:
- Control machine runs the TUI and playbooks
- Target servers execute tasks remotely via SSH
- No need to copy scripts to each server
- Centralized management from a single control point

## Prerequisites

### Control Machine (Your Laptop/Server)
- Python 3.6+
- Ansible 2.9+
- whiptail (for TUI)
- SSH access to target servers

### Target Servers
- Ubuntu/Debian-based Linux
- SSH access with sudo privileges
- Python 3 (for Ansible)

## Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd infra_scripts
```

2. Install Ansible (if not already installed):
```bash
# On macOS
brew install ansible

# On Ubuntu/Debian
sudo apt update
sudo apt install ansible

# On other systems
pip3 install ansible
```

3. Install whiptail (if not already installed):
```bash
# On macOS
brew install newt

# On Ubuntu/Debian
sudo apt install whiptail
```

4. Make scripts executable:
```bash
chmod +x tui.sh scripts/generate_inventory.py
```

## Configuration

### Host Configuration (JSON)

Edit `inventory/hosts.json` to add your servers:

```json
{
  "hosts": [
    {
      "name": "web-server-1",
      "ip": "192.168.1.10",
      "user": "ubuntu",
      "ssh_key": "~/.ssh/id_rsa",
      "groups": ["servers"],
      "ansible_python_interpreter": "/usr/bin/python3"
    },
    {
      "name": "db-server-1",
      "ip": "192.168.1.20",
      "user": "ubuntu",
      "ssh_key": "~/.ssh/id_rsa",
      "groups": ["databases"],
      "ansible_python_interpreter": "/usr/bin/python3"
    }
  ],
  "groups": {
    "servers": {},
    "databases": {}
  }
}
```

**Important**: The `hosts.json` file should be added to `.gitignore` to prevent committing sensitive IP addresses and credentials to version control.

### SSH Key Setup

Ensure you have SSH key-based authentication set up for passwordless access:

```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096

# Copy public key to target server
ssh-copy-id user@target-server-ip
```

## Usage

### Launch the TUI

```bash
./tui.sh
```

The TUI provides two main options:
1. **Server Configurations**: Set up new servers with predefined configurations
2. **Utility Functions**: Manage ports, nginx, docker, and SSL certificates

### Server Configuration Workflow

1. Select "Server Configurations" from main menu
2. Choose a server configuration type
3. Select target host from the list
4. Ansible playbook executes remotely on the selected host

### Utility Functions Workflow

1. Select "Utility Functions" from main menu
2. Choose a utility (ports, nginx, docker, etc.)
3. Select target host
4. Follow prompts for configuration options
5. Utility executes remotely on the selected host

## Project Structure

```
infra_scripts/
├── tui.sh                    # Main TUI entry point
├── README.md                 # This file
├── inventory/
│   ├── hosts.json           # JSON host configuration (gitignored)
│   ├── local.ini            # Localhost inventory for testing
│   └── .gitignore          # Ignore hosts.json
├── playbooks/
│   ├── basic.yml           # Basic server playbook
│   ├── db.yml              # Database server playbook
│   ├── db_cache.yml        # Database + cache playbook
│   ├── full_stack.yml      # Full stack playbook
│   ├── postgres.yml        # PostgreSQL only
│   ├── redis.yml           # Redis only
│   ├── garage.yml          # Garage only
│   ├── coolify.yml         # Coolify server
│   ├── email.yml           # Email server
│   └── utils/              # Utility playbooks
│       ├── ports.yml       # Port management
│       ├── nginx.yml       # Nginx setup
│       ├── docker.yml      # Docker management
│       ├── docker_status.yml  # Docker status
│       └── letsencrypt.yml    # Let's Encrypt automation
├── roles/                   # Reusable Ansible roles
│   ├── python/             # Python 3.11 installation
│   ├── nodejs/             # Node.js installation
│   ├── postgresql/         # PostgreSQL installation
│   ├── redis/              # Redis installation
│   ├── garage/             # Garage installation
│   ├── nginx/              # Nginx installation & config
│   ├── docker/              # Docker installation
│   ├── coolify/             # Coolify installation
│   └── email/               # Email server setup
├── scripts/
│   └── generate_inventory.py  # JSON to Ansible inventory converter
└── config/
    └── defaults/            # Default configuration variables
```

## Examples

### Setting up a Basic Server

```bash
./tui.sh
# Select: Server Configurations
# Select: Basic server
# Select: web-server-1
```

### Blocking a Port

```bash
./tui.sh
# Select: Utility Functions
# Select: Block/Unblock ports
# Select: web-server-1
# Enter: block
# Enter: 8080
# Enter: tcp
```

### Setting up Let's Encrypt SSL

```bash
./tui.sh
# Select: Utility Functions
# Select: Let's Encrypt automation
# Select: web-server-1
# Enter: example.com
# Enter: admin@example.com
```

### Checking Docker Status

```bash
./tui.sh
# Select: Utility Functions
# Select: Docker network and application status
# Select: web-server-1
```

## Security Best Practices

1. **Never commit `hosts.json`**: Add it to `.gitignore`
2. **Use SSH keys**: Avoid password authentication
3. **Limit SSH access**: Use firewall rules to restrict access
4. **Regular updates**: Keep Ansible and target systems updated
5. **Review playbooks**: Understand what each playbook does before running

## Troubleshooting

### Connection Issues
- Verify SSH connectivity: `ssh user@target-server`
- Check SSH key permissions: `chmod 600 ~/.ssh/id_rsa`
- Ensure target server has Python 3 installed

### Ansible Issues
- Test inventory: `ansible all -i scripts/generate_inventory.py -m ping`
- Check Ansible version: `ansible --version`
- Verify playbook syntax: `ansible-playbook --syntax-check playbooks/basic.yml`

### TUI Issues
- Ensure whiptail is installed: `which whiptail`
- Check script permissions: `chmod +x tui.sh`

## Support

For issues and questions, please open an issue in the repository.
