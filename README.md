# linux-server-management

**Ansible playbooks for comprehensive server management on Debian/Ubuntu based Linux systems.**

This repository provides a collection of Ansible playbooks and roles designed to automate common server management tasks, user administration, and system configuration. Whether you're managing a single server or a fleet of machines, these playbooks help ensure consistent, repeatable deployments. It is directly based on https://github.com/konstruktoid 's work. Please check out the upstream repos and, if you can, support their work.

## Features

- **User Management**: Automated user account creation with SSH key management and sudo configuration
- **Docker Installation**: Rootless Docker setup for enhanced security
- **Multi-Environment Support**: Organized inventory structure for different environments
- **Testing Framework**: Vagrant-based testing for playbook validation
- **Security-First Approach**: Best practices for secure server management

## Supported Systems

- **Debian**: Bookworm (12) and newer
- **Ubuntu**: Jammy (22.04 LTS) and newer
- **Architecture**: x86_64

## Prerequisites

### Debian-based Linux
```bash
sudo apt update
sudo apt install virtualbox vagrant python3-pip
```

### macOS
```bash
brew install python
python3 -m ensurepip --upgrade
brew install --cask virtualbox
brew install vagrant
```

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd linux-server-management
   ```

2. **Install Python dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Install Ansible dependencies**:
   ```bash
   ansible-galaxy install -r requirements.yml
   ```

## Available Playbooks

### setup-playbook.yml
Main system setup playbook that includes:
- User management and SSH key configuration
- CIS-based system hardening via https://github.com/konstruktoid/ansible-role-hardening and cusomizable
- Essential package installation

### install-docker-rootless.yml
Installs Docker in rootless mode for enhanced security via https://github.com/konstruktoid/ansible-role-docker-rootless:
- Configures rootless Docker daemon
- Sets up user namespaces
- Enables Docker service for non-root users

## Available Roles

### users_add
Manages user accounts with the following features:
- Creates user accounts with individual groups
- Configures SSH public key authentication
- Sets up sudo permissions for admin users
- Allows limited sudo commands for non-admin users
- Forces password change on first login

**Required Variables**: #TODO: Add all the others needed
- `users_add_userlist`: List of users to create
- `GENERALINITIALPASSWORD`: Default initial password (use Ansible Vault)

## Quick Start

### 1. Set up your inventory
Create or modify inventory files in the `inventories/` directory based on your environment.

### 2. Configure variables
Edit the appropriate files in `group_vars/` and `host_vars/` for your environment-specific settings.
TODO: add example file to guide newbies
### 3. Run a playbook
```bash
# Set your SSH username
BASTION_USER="your_username"

# The below assumes that you ran ssh-add so that you won't be prompted countless time for your ssh key password.

# Run the setup playbook
ansible-playbook -i inventories/your-inventory/inventory \
                 -l target_group_or_host \
                 -u $BASTION_USER \
                 setup-playbook.yml

# Add -K flag if sudo password is required
ansible-playbook -i inventories/your-inventory/inventory \
                 -l target_group_or_host \
                 -u $BASTION_USER \
                 -K \
                 setup-playbook.yml
```

## Testing

### Local Testing with Vagrant
Test playbooks on virtual machines before deploying to production:

```bash
# Install testing dependencies
ansible-galaxy install -r testing/requirements.yml

# Start test VMs (Debian Bookworm and Ubuntu Jammy)
vagrant up

# Run tests against VMs
ansible-playbook -i testing/inventory test-playbook.yml
```

### Testing Individual Roles
```bash
# Test specific roles
ansible-playbook -i testing/inventory \
                 --tags "users" \
                 setup-playbook.yml
```

## Security Considerations

- **SSH Key Authentication**: Password authentication is discouraged; use SSH keys
- **Ansible Vault**: Store sensitive variables (passwords, keys) using `ansible-vault`
- **Least Privilege**: Non-admin users receive minimal sudo permissions
- **Initial Password Policy**: Users must change passwords on first login

### Using Ansible Vault
```bash
# Create encrypted variable file
ansible-vault create group_vars/all/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/all/vault.yml

# Run playbook with vault
ansible-playbook -i inventory playbook.yml --ask-vault-pass
```

## Troubleshooting

### Common Issues

**SSH Connection Failed**
- Ensure you've connected to target hosts at least once to accept SSH fingerprints
- Verify SSH key is loaded: `ssh-add -l`
- Test manual SSH connection: `ssh user@target-host`

**Permission Denied (sudo)**
- Add `-K` flag to prompt for sudo password
- Verify user has sudo permissions on target system
- Check `/etc/sudoers.d/` for user-specific rules

**Ansible Galaxy Dependencies**
Run `ansible-galaxy install -r requirements.yml --force` to update roles


### Getting Help
1. Check the troubleshooting section above
2. Review Ansible logs for detailed error messages
3. Test connectivity: `ansible all -i inventory -m ping`
4. Validate playbook syntax: `ansible-playbook --syntax-check playbook.yml`
5. If you are still stuck, open an issue.

## Contributing

1. **Fork the repository** and create a feature branch
2. **Follow Ansible best practices**: Use `ansible-lint` to validate changes
3. **Test thoroughly**: Ensure playbooks work on supported systems
4. **Document changes**: Update README and role documentation
5. **Submit a pull request** with clear description of changes

### Development Guidelines
- Use 2-space indentation for YAML files
- Add comments for complex logic
- Use descriptive variable names with role prefixes where possible
- Ensure idempotency for all tasks
- Test with `ansible-lint` and `yamllint`

## License

This project is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for details.

Testing, Automation and Vagrant script portions based on work by Thomas Sjögren (2020-2024) from https://github.com/konstruktoid/ansible-role-hardening.

## Support

For issues and questions:
- Check existing GitHub issues
- Create a new issue with detailed description
- Include Ansible version, target OS, and error messages