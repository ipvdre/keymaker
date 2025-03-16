# Advanced Network Automation

A comprehensive network automation solution for multivendor environments with secure credential management and detailed device categorization.

## Features

- **Multivendor support**: 
  - Cisco (IOS, IOS-XE, IOS-XR, NX-OS, ASA)
  - Dell (OS6, OS10)
  - Aruba (AOS-Switch, AOS-CX)
  - Juniper (JunOS)
  - Fortinet (FortiOS)
  - Arista (EOS)
  - Palo Alto (PAN-OS)
  - SonicWall
- **Device categorization**:
  - By location (geographical grouping)
  - By device type (firewalls, routers, layer2_switches, layer3_switches)
  - By OS type (cisco_ios, arista_eos, etc.)
- **Secure Ansible Vault** encryption for all credentials (not stored in Git)
- **Configuration backup** capabilities
- **MAC address table** versioning with Git
- **Security hardening** for all supported platforms

## Directory Structure

```
keymaker/
├── ansible.cfg              # Ansible configuration
├── inventory/
│   ├── hosts                # Inventory file with grouped devices
│   ├── host_vars/           # Host-specific variables
│   └── group_vars/          # Group-specific variables
├── playbooks/
│   ├── backup/              # Configuration backups
│   ├── configs/             # Generated configurations
│   ├── templates/           # Jinja2 templates
│   ├── capture_mac_tables.yml
│   ├── secure_backup.yml
│   └── harden_devices.yml
├── mac_tables/              # Version-controlled MAC tables
├── logs/                    # Ansible logs
└── reports/                 # Generated reports
```

## Common Commands

- Test connectivity: `ansible all_devices -m ping`
- Backup configurations: `ansible-playbook playbooks/secure_backup.yml`
- Capture MAC tables: `ansible-playbook playbooks/capture_mac_tables.yml`
- Apply security hardening: `ansible-playbook playbooks/harden_devices.yml`

## Using Device Groups

Run tasks targeting specific device categories:

- All firewalls: `ansible firewalls -m ping`
- All layer 3 switches: `ansible layer3_switches -m ping`
- All Cisco devices: `ansible cisco_ios:cisco_nxos:cisco_iosxe -m ping`
- Specific location: `ansible newyork -m ping`

## Adding New Devices

To add new devices, run the `./add_device.sh` script and follow the prompts.
The script will:
- Add the device to the proper location group
- Categorize it by device type (firewall, router, switch)
- Categorize it by OS type
- Set up secure credential storage
- Test connectivity

## Security Notes

- All credentials are stored in individual encrypted vault files
- Vault files are excluded from Git by the .gitignore configuration
- Vault passwords are stored securely with restricted permissions
- SSH keys are used for secure GitHub integration

## Automated Tasks

- MAC table capture: Weekly on Sunday at 1:00 AM
- Configuration backup: Monthly on the 1st at 2:00 AM
