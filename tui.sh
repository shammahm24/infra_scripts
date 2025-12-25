#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY_SCRIPT="$SCRIPT_DIR/scripts/generate_inventory.py"
HOSTS_JSON="$SCRIPT_DIR/inventory/hosts.json"

# Function to get hosts from JSON
get_hosts() {
    if [[ -f "$HOSTS_JSON" ]]; then
        python3 -c "import json; data=json.load(open('$HOSTS_JSON')); print('\n'.join([h['name'] for h in data.get('hosts', [])]))" 2>/dev/null || echo "localhost"
    else
        echo "localhost"
    fi
}

# Function to select host
select_host() {
    local hosts=($(get_hosts))
    local host_menu=()
    
    for host in "${hosts[@]}"; do
        host_menu+=("$host" "$host")
    done
    
    if [[ ${#host_menu[@]} -eq 0 ]]; then
        echo "localhost"
        return
    fi
    
    local selected=$(whiptail --title "Select Host" \
        --menu "Choose target host (Cancel to go back)" 15 50 5 \
        "${host_menu[@]}" \
        "back" "← Back to menu" \
        3>&1 1>&2 2>&3)
    
    if [[ -z "$selected" ]] || [[ "$selected" == "back" ]]; then
        echo ""
        return 1
    fi
    
    echo "$selected"
}

# Main menu loop
while true; do
    MAIN_CHOICE=$(whiptail --title "Infrastructure Management" \
        --menu "Choose an option" 20 70 10 \
        "server"     "Server Configurations" \
        "utils"      "Utility Functions" \
        "exit"       "Exit" \
        3>&1 1>&2 2>&3)
    
    [[ -z "$MAIN_CHOICE" ]] && exit 0
    
    if [[ "$MAIN_CHOICE" == "exit" ]]; then
        exit 0
    fi
    
    if [[ "$MAIN_CHOICE" == "server" ]]; then
        # Server configurations menu
        while true; do
            PLAYBOOK=$(whiptail --title "Server Setup" \
                --menu "Choose a configuration (Cancel to go back)" 20 70 12 \
                "basic"       "Basic server (Python 3.11 + Node.js)" \
                "db"          "Server with PostgreSQL" \
                "db_cache"    "DB + Redis" \
                "full_stack"  "DB + Redis + Blob storage (Garage)" \
                "postgres"    "PostgreSQL only" \
                "redis"       "Redis only" \
                "garage"      "Blob storage (Garage) only" \
                "coolify"     "Coolify server" \
                "email"       "Email server" \
                "back"        "← Back to main menu" \
                3>&1 1>&2 2>&3)
            
            [[ -z "$PLAYBOOK" ]] && break
            [[ "$PLAYBOOK" == "back" ]] && break
            
            # Select host
            TARGET_HOST=$(select_host)
            if [[ $? -ne 0 ]] || [[ -z "$TARGET_HOST" ]]; then
                continue  # Go back to server menu
            fi
            
            # Determine inventory source
            if [[ -f "$HOSTS_JSON" ]] && [[ "$TARGET_HOST" != "localhost" ]]; then
                INVENTORY="$INVENTORY_SCRIPT"
            else
                INVENTORY="$SCRIPT_DIR/inventory/local.ini"
            fi
            
            # Confirm execution
            if whiptail --title "Confirm Execution" \
                --yesno "Execute playbook: $PLAYBOOK.yml\nTarget: $TARGET_HOST\n\nProceed?" 10 60; then
                
                # Run playbook
                if [[ "$TARGET_HOST" != "localhost" ]]; then
                    ansible-playbook \
                        -i "$INVENTORY" \
                        --limit "$TARGET_HOST" \
                        "$SCRIPT_DIR/playbooks/$PLAYBOOK.yml"
                else
                    ansible-playbook \
                        -i "$INVENTORY" \
                        "$SCRIPT_DIR/playbooks/$PLAYBOOK.yml"
                fi
                
                # Show completion message
                whiptail --title "Complete" \
                    --msgbox "Playbook execution completed.\n\nPress OK to continue." 10 60
            fi
        done
    
    elif [[ "$MAIN_CHOICE" == "utils" ]]; then
        # Utilities menu
        while true; do
            UTILITY=$(whiptail --title "Utility Functions" \
                --menu "Choose a utility (Cancel to go back)" 20 70 10 \
                "ports"       "Block/Unblock ports" \
                "nginx"       "Setup nginx for services/domains" \
                "docker"      "Docker setup and management" \
                "docker_status" "Docker network and application status" \
                "letsencrypt" "Let's Encrypt automation + nginx" \
                "back"        "← Back to main menu" \
                3>&1 1>&2 2>&3)
            
            [[ -z "$UTILITY" ]] && break
            [[ "$UTILITY" == "back" ]] && break
            
            # Select host
            TARGET_HOST=$(select_host)
            if [[ $? -ne 0 ]] || [[ -z "$TARGET_HOST" ]]; then
                continue  # Go back to utils menu
            fi
            
            # Determine inventory source
            if [[ -f "$HOSTS_JSON" ]] && [[ "$TARGET_HOST" != "localhost" ]]; then
                INVENTORY="$INVENTORY_SCRIPT"
            else
                INVENTORY="$SCRIPT_DIR/inventory/local.ini"
            fi
            
            # Confirm execution
            if whiptail --title "Confirm Execution" \
                --yesno "Execute utility: $UTILITY.yml\nTarget: $TARGET_HOST\n\nProceed?" 10 60; then
                
                # Run utility playbook
                if [[ "$TARGET_HOST" != "localhost" ]]; then
                    ansible-playbook \
                        -i "$INVENTORY" \
                        --limit "$TARGET_HOST" \
                        "$SCRIPT_DIR/playbooks/utils/$UTILITY.yml"
                else
                    ansible-playbook \
                        -i "$INVENTORY" \
                        "$SCRIPT_DIR/playbooks/utils/$UTILITY.yml"
                fi
                
                # Show completion message
                whiptail --title "Complete" \
                    --msgbox "Utility execution completed.\n\nPress OK to continue." 10 60
            fi
        done
    fi
done
