#!/bin/bash

# Network Automation - Add New Device Script
# This script helps add new devices to an existing Network Automation setup
# It supports device categorization by location, device type, and OS type

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================================${NC}"
echo -e "${BLUE}      Network Automation - Add New Device      ${NC}"
echo -e "${BLUE}====================================================================${NC}"

# Determine the installation directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$SCRIPT_DIR"

# Check if directory exists
if [ ! -f "$ANSIBLE_DIR/ansible.cfg" ]; then
    echo -e "${RED}Error: ansible.cfg not found. Are you in the network automation directory?${NC}"
    exit 1
fi

# Device OS type mapping
declare -A OS_MAP
OS_MAP["1"]="ios"
OS_MAP["2"]="nxos"
OS_MAP["3"]="iosxe"
OS_MAP["4"]="iosxr"
OS_MAP["5"]="asa"
OS_MAP["6"]="dellemc.os6.os6"
OS_MAP["7"]="dellemc.os10.os10"
OS_MAP["8"]="arubanetworks.aos_switch.aoscl"
OS_MAP["9"]="arubanetworks.aoscx.aoscx"
OS_MAP["10"]="junipernetworks.junos.junos"
OS_MAP["11"]="fortinet.fortios.fortios"
OS_MAP["12"]="arista.eos.eos"
OS_MAP["13"]="paloaltonetworks.panos.panos"
OS_MAP["14"]="sonicwall"

declare -A OS_GROUP_MAP
OS_GROUP_MAP["1"]="cisco_ios"
OS_GROUP_MAP["2"]="cisco_nxos"
OS_GROUP_MAP["3"]="cisco_iosxe"
OS_GROUP_MAP["4"]="cisco_iosxr"
OS_GROUP_MAP["5"]="cisco_asa"
OS_GROUP_MAP["6"]="dell_os6"
OS_GROUP_MAP["7"]="dell_os10"
OS_GROUP_MAP["8"]="aruba_aosswitch"
OS_GROUP_MAP["9"]="aruba_aoscx"
OS_GROUP_MAP["10"]="juniper_junos"
OS_GROUP_MAP["11"]="fortinet_fortios"
OS_GROUP_MAP["12"]="arista_eos"
OS_GROUP_MAP["13"]="paloalto_panos"
OS_GROUP_MAP["14"]="sonicwall"

# Device type mapping
declare -A DEVICE_TYPE_MAP
DEVICE_TYPE_MAP["1"]="firewalls"
DEVICE_TYPE_MAP["2"]="routers"
DEVICE_TYPE_MAP["3"]="layer2_switches"
DEVICE_TYPE_MAP["4"]="layer3_switches"

# Prompt for location information
echo -e "\n${YELLOW}Device Location Information${NC}"
read -p "Enter location name (e.g., NewYork, Chicago): " LOCATION_NAME
LOCATION_ID=$(echo "$LOCATION_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')

# Check if location already exists in inventory
if grep -q "^\[$LOCATION_ID\]" "$ANSIBLE_DIR/inventory/hosts"; then
    echo -e "${YELLOW}Location '$LOCATION_NAME' already exists in inventory.${NC}"
else
    echo -e "${GREEN}Adding new location '$LOCATION_NAME' to inventory.${NC}"
    
    # Find proper insertion point for new location section
    sed -i "/# Locations will be added here/a \[$LOCATION_ID\]\n# devices will be added here\n" "$ANSIBLE_DIR/inventory/hosts"
    
    # Add location to all_devices group if not already there
    if ! grep -q "$LOCATION_ID" "$ANSIBLE_DIR/inventory/hosts" | grep "\[all_devices:children\]" -A 100 | grep -q "$LOCATION_ID"; then
        sed -i "/# locations will be added here/i $LOCATION_ID" "$ANSIBLE_DIR/inventory/hosts"
    fi
fi

# Prompt for device information
echo -e "\n${YELLOW}Device Information${NC}"
read -p "Device name (e.g., nyc_sw01): " DEVICE_NAME
read -p "Device IP address: " DEVICE_IP

# Prompt for device type
echo -e "\n${YELLOW}Select device type:${NC}"
echo "1. Firewall"
echo "2. Router"
echo "3. Layer 2 Switch"
echo "4. Layer 3 Switch"
read -p "Enter device type (1-4): " DEVICE_TYPE_CHOICE

if [[ ! ${DEVICE_TYPE_MAP[$DEVICE_TYPE_CHOICE]} ]]; then
    echo -e "${RED}Invalid choice. Defaulting to Router.${NC}"
    DEVICE_TYPE_CHOICE="2"
fi

DEVICE_TYPE=${DEVICE_TYPE_MAP[$DEVICE_TYPE_CHOICE]}

# Prompt for device OS
echo -e "\n${YELLOW}Select device operating system:${NC}"
echo "1. Cisco IOS"
echo "2. Cisco NX-OS"
echo "3. Cisco IOS-XE"
echo "4. Cisco IOS-XR"
echo "5. Cisco ASA"
echo "6. Dell OS6"
echo "7. Dell OS10"
echo "8. Aruba AOS-Switch"
echo "9. Aruba AOS-CX"
echo "10. Juniper JunOS"
echo "11. Fortinet FortiOS"
echo "12. Arista EOS"
echo "13. Palo Alto PAN-OS"
echo "14. SonicWall"
read -p "Enter OS type (1-14): " OS_TYPE_CHOICE

if [[ ! ${OS_MAP[$OS_TYPE_CHOICE]} ]]; then
    echo -e "${RED}Invalid choice. Defaulting to Cisco IOS.${NC}"
    OS_TYPE_CHOICE="1"
fi

DEVICE_OS=${OS_MAP[$OS_TYPE_CHOICE]}
OS_GROUP=${OS_GROUP_MAP[$OS_TYPE_CHOICE]}

# Prompt for device credentials
echo -e "\n${YELLOW}Device Credentials${NC}"
read -p "Username: " DEVICE_USERNAME
read -sp "Password: " DEVICE_PASSWORD
echo
read -sp "Enable password: " ENABLE_PASSWORD
echo

# Add device to location in inventory
echo -e "\n${GREEN}Adding device to inventory...${NC}"
sed -i "/\[$LOCATION_ID\]/a $DEVICE_NAME ansible_host=$DEVICE_IP" "$ANSIBLE_DIR/inventory/hosts"

# Add device to appropriate OS group
echo -e "${GREEN}Adding device to OS group: $OS_GROUP${NC}"
if ! grep -A 10 "\[$OS_GROUP:children\]" "$ANSIBLE_DIR/inventory/hosts" | grep -q "$LOCATION_ID"; then
    sed -i "/\[$OS_GROUP:children\]/a $LOCATION_ID" "$ANSIBLE_DIR/inventory/hosts"
fi

# Add device to appropriate device type group
echo -e "${GREEN}Adding device to device type group: $DEVICE_TYPE${NC}"
if ! grep -A 10 "\[$DEVICE_TYPE\]" "$ANSIBLE_DIR/inventory/hosts" | grep -q "$DEVICE_NAME"; then
    sed -i "/\[$DEVICE_TYPE\]/a $DEVICE_NAME" "$ANSIBLE_DIR/inventory/hosts"
fi

# Create host_vars directory and files
echo -e "${GREEN}Creating host_vars for $DEVICE_NAME...${NC}"
mkdir -p "$ANSIBLE_DIR/inventory/host_vars/$DEVICE_NAME"

# Create vault content
echo "vault_ansible_user: $DEVICE_USERNAME" > .temp_vault_content
echo "vault_ansible_password: $DEVICE_PASSWORD" >> .temp_vault_content
echo "vault_enable_password: $ENABLE_PASSWORD" >> .temp_vault_content

# Encrypt vault content
ansible-vault encrypt .temp_vault_content --output="$ANSIBLE_DIR/inventory/host_vars/$DEVICE_NAME/vault.yml"

# Create vars.yml linking to vault variables
cat > "$ANSIBLE_DIR/inventory/host_vars/$DEVICE_NAME/vars.yml" << 'EOFMARKER'
ansible_user: "{{ vault_ansible_user }}"
ansible_password: "{{ vault_ansible_password }}"
ansible_become_password: "{{ vault_enable_password }}"
ansible_connection: network_cli
ansible_network_os: DEVICE_OS_PLACEHOLDER
ansible_become: yes
ansible_become_method: enable
repo_path: "ANSIBLE_DIR_PLACEHOLDER"
device_type: "DEVICE_TYPE_PLACEHOLDER"
EOFMARKER

# Replace placeholders in vars.yml
sed -i "s|DEVICE_OS_PLACEHOLDER|$DEVICE_OS|g" "$ANSIBLE_DIR/inventory/host_vars/$DEVICE_NAME/vars.yml"
sed -i "s|ANSIBLE_DIR_PLACEHOLDER|$ANSIBLE_DIR|g" "$ANSIBLE_DIR/inventory/host_vars/$DEVICE_NAME/vars.yml"
sed -i "s|DEVICE_TYPE_PLACEHOLDER|$DEVICE_TYPE|g" "$ANSIBLE_DIR/inventory/host_vars/$DEVICE_NAME/vars.yml"

# Cleanup
rm -f .temp_vault_content

# Test connectivity
echo -e "\n${GREEN}Testing connectivity to new device...${NC}"
ansible "$DEVICE_NAME" -m ping

# Git commit changes - don't commit vault files!
echo -e "\n${GREEN}Committing changes to Git (excluding vault files)...${NC}"
cd "$ANSIBLE_DIR"
git add inventory/hosts "inventory/host_vars/$DEVICE_NAME/vars.yml"
git commit -m "Add device $DEVICE_NAME to $LOCATION_NAME location"

# Prompt for push
echo -e "\n${YELLOW}Would you like to push changes to GitHub? (y/n)${NC}"
read -p "> " PUSH_CHANGES

if [[ $PUSH_CHANGES =~ ^[Yy]$ ]]; then
    git push origin main
    echo -e "\n${GREEN}Changes pushed to GitHub successfully.${NC}"
else
    echo -e "\n${YELLOW}Changes not pushed. You can push later with:${NC}"
    echo "cd $ANSIBLE_DIR && git push origin main"
fi

echo -e "\n${GREEN}=======================================================${NC}"
echo -e "${GREEN}Device $DEVICE_NAME added successfully!${NC}"
echo -e "${GREEN}Type: $DEVICE_TYPE | OS: $DEVICE_OS${NC}"
echo -e "${GREEN}=======================================================${NC}"
