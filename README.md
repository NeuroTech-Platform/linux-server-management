# linux-server-management

**Ansible playbooks for comprehensive server management on Debian/Ubuntu based Linux systems.**

This repository provides a collection of Ansible playbooks and roles designed to automate common server management tasks, user administration, and system configuration. Whether you're managing a single server or a fleet of machines, these playbooks help ensure consistent, repeatable deployments. It is directly based on https://github.com/konstruktoid 's work. Please check out the upstream repos and, if you can, support their work.

## Features

- **User Management**: Automated user account creation with SSH key management and sudo configuration
- **Two-Factor Authentication**: TOTP-based 2FA (Aegis, Google Authenticator, Authy, Bitwarden, etc...) for SSH login
- **Docker Installation**: Rootless Docker setup for enhanced security
- **Multi-Environment Support**: Organized inventory structure for different environments
- **Testing Framework**: Vagrant-based testing for playbook validation
- **Security-First Approach**: Best practices for secure server management

## Supported Systems

- **Debian**: Trixie (13) and newer
- **Ubuntu**: Resolute Raccoon (26.04 LTS) and newer
- **Architecture**: x86_64 and aarch64 (arm64 - only Ubuntu 26.04 tested)

## Prerequisites

You run these playbooks from a **control machine** (your laptop) against remote
servers over SSH. The only hard requirements are `git`, Python 3, and Ansible
(installed in the next section). VirtualBox + Vagrant are **only** needed if you
want to run the local VM test suite — skip them if you're provisioning real hosts.

### To provision servers (required)

#### Debian-based Linux
```bash
sudo apt update
sudo apt install git python3 python3-venv
```

#### macOS
```bash
brew install git python
```

> Note: On modern macOS (Homebrew Python) and Debian 12+/13, Python is
> "externally managed" (PEP 668), so a global `pip install` is blocked. The
> Installation section below uses a virtual environment, which is the supported
> path on every platform. Ansible itself is installed there — not via the OS
> package manager.

### To run local VM tests (optional)

Only needed for the [Testing](#testing) section.

#### Debian-based Linux
```bash
sudo apt install virtualbox vagrant
```

#### macOS
```bash
brew install --cask virtualbox
brew install hashicorp/tap/hashicorp-vagrant
```

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd linux-server-management
   ```

2. **Create a virtual environment and install Python dependencies**
   (installs Ansible, ansible-lint, passlib, jmespath):
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate        # run this in every new shell before using ansible
   pip install -r requirements.txt
   ```

3. **Install Ansible dependencies** (collections; the playbook also pulls the
   hardening role automatically at runtime):
   ```bash
   ansible-galaxy install -r requirements.yml
   ```

> The `.venv` must be active (`source .venv/bin/activate`) whenever you run
> `ansible`, `ansible-playbook`, or `ansible-galaxy`. On macOS use `pip` /
> `python3` from inside the venv (a bare `pip` may not exist system-wide).

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
- **Two-Factor Authentication (2FA)**: Optional TOTP-based 2FA enforcement

**Required Variables**:
- `SSH_USERLIST`: List of users to create (used by users_add role)
- `GENERALINITIALPASSWORD`: Default initial password (use Ansible Vault)
- `ENABLE_2FA`: Enable/disable 2FA globally (true/false)
- `AUDITD_ACTION_MAIL_ACCT`: Email address for audit system alerts
- `MANAGE_UFW`: Enable/disable UFW firewall management (true/false)  
- `UFW_OUTGOING_TRAFFIC`: List of allowed outbound traffic rules
- `AUTO_UPDATES_OPTIONS`: Automatic-updates policy; its `reboot` key (bool) is required by pre-flight
- `SSHD_ADMIN_NET`: List of networks allowed for SSH admin access

**Example Configuration**:
```yaml
# inventories/your-environment/group_vars/all/vars.yml
SSH_USERLIST:
  - username: "admin_user"
    admin: true
    public_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."

ENABLE_2FA: true  # Enforce TOTP-based 2FA for SSH login
AUDITD_ACTION_MAIL_ACCT: "security@example.com"
MANAGE_UFW: true
UFW_OUTGOING_TRAFFIC:
  - "80/tcp"    # HTTP
  - "443/tcp"   # HTTPS
  - "53"        # DNS
AUTO_UPDATES_OPTIONS:
  enabled: true
  only_security: true
  reboot: false              # required by pre-flight (must be a boolean)
  reboot_from_time: "02:00"
  reboot_time_margin_mins: 20
SSHD_ADMIN_NET:
  - "192.168.1.0/24"
  - "10.0.0.0/8"

# Disable client-side DNSSEC if your network breaks resolution after hardening
# (see Troubleshooting). Validation still happens at the upstream resolvers.
# DNSSEC: false

# Optional security overrides (defaults shown)
# SSHD_MAX_AUTH_TRIES: 3        # CIS compliant (default)
# SSHD_LOGIN_GRACE_TIME: 60     # Extended for password complexity
# SESSION_TIMEOUT: 900          # 15 min for operational efficiency
```

## Quick Start

### 1. Set up your inventory
Create your own inventory under `inventories/<your-env>/` — an `inventory` file
plus `host_vars/` (and optionally `group_vars/`).

> **Inventories are gitignored by design** (see the top of `.gitignore`): they
> contain environment-specific IPs, usernames and secrets, so the repository
> ships **no** inventories — a fresh clone has none. Maintain yours locally or in
> a private repo. Use `docs/inventory.md` and the example configuration above
> (the `users_add` variables block) as your template.

### 2. Configure variables
Define your host/group variables under `inventories/<your-env>/host_vars/` and
`inventories/<your-env>/group_vars/`. See `docs/inventory.md` for a full walkthrough.

`setup-playbook.yml` runs a pre-flight check and **fails immediately** unless all
of these are defined for the target host: `SSH_USERLIST`,
`AUDITD_ACTION_MAIL_ACCT`, `MANAGE_UFW`, `UFW_OUTGOING_TRAFFIC`,
`AUTO_UPDATES_OPTIONS.reboot`, `SSHD_ADMIN_NET`, and `ENABLE_2FA` (required even
when `false`). Define every one of them for each host you target.

### 3. Provision a brand-new server (first run, as `root`)

A freshly created server usually only has the `root` account — and this playbook
is what *creates* your unprivileged users. So the **first** run must connect as
`root`. The same run also hardens the box and, when `DISABLE_ROOT_ACCOUNT: true`,
**disables root SSH and password authentication at the end** — so this is a
one-time bootstrap. Order matters.

```bash
source .venv/bin/activate                 # if not already active

# 1. Accept the new host's SSH fingerprint (host key checking is enforced).
#    A brand-new host has never been seen, so connect once manually first:
ssh -o StrictHostKeyChecking=accept-new root@<server-ip> true

# 2. (Optional) Smoke-test connectivity through Ansible:
ansible -i inventories/<your-env>/inventory <your-host> -u root -m ping

# 3. First run — connect as root. No -K needed: root has no sudo password.
ansible-playbook -i inventories/<your-env>/inventory \
                 -l <your-host> \
                 -u root \
                 setup-playbook.yml
```

This creates the users in `SSH_USERLIST`, applies CIS hardening, and locks down
SSH. New users are forced to change their password on first login.

> If `root` only accepts a password (not your key), copy your key up first with
> `ssh-copy-id root@<server-ip>`, or add `--ask-pass` (requires `sshpass`).

### 4. Subsequent runs (as your admin user)

After the bootstrap, `root` login is gone. Connect as one of the admin users you
just created, and add `-K` so Ansible can prompt for the sudo password:

```bash
ANSIBLE_USER="your_admin_user"

# ssh-add your key first to avoid repeated passphrase prompts.
ansible-playbook -i inventories/<your-env>/inventory \
                 -l <your-host> \
                 -u "$ANSIBLE_USER" \
                 -K \
                 setup-playbook.yml
```

## Testing

### Local Testing with Vagrant
Test playbooks on virtual machines before deploying to production:

```bash
# Ensure `ansible-playbook` is on your PATH (Vagrant's Ansible provisioner uses the host install).
# One reliable option is a local venv:
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt

# Install Ansible dependencies used by the test playbooks
ansible-galaxy install -r requirements.yml
ansible-galaxy install --no-deps -r testing/requirements.yml

# Pick the playbook to run via the Vagrant Ansible provisioner.
# If not set, Vagrant defaults to: testing/test-new-version-hardening.yml
export TEST_PLAYBOOK=testing/e2e-hardened-then-install-docker-rootless.yml
# Other useful options:
# export TEST_PLAYBOOK=testing/test-new-version-hardening.yml
# export TEST_PLAYBOOK=testing/test-new-version-docker-rootless.yml

# Start and provision test VMs (Debian 13, Ubuntu 26.04)
PATH="$PWD/.venv/bin:$PATH" vagrant up
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

## CI / Testing Pipeline

GitHub Actions runs a few gates:

- **Lint**: ansible-lint/syntax checks against repository playbooks.
- **Integration (Vagrant)**: provisions one or more VMs and runs the playbooks end-to-end (VirtualBox-based).
- **Integration (Vagrant, ARM64)**: same as above, but runs on a self-hosted `macOS` `ARM64` runner (VirtualBox on Apple Silicon).
- **Deps: new role version testing**: for dependency update PRs, runs Vagrant with a role-focused test playbook before auto-updating the pinned SHA in the top-level playbook.

The Docker rootless integration test is intentionally end-to-end: it assumes the baseline hardening was applied first.

## Known Limitations

- **Rootless Docker cgroups**: if Docker reports `Cgroup Driver: none` in rootless mode, resource limits (`--memory`, `--cpus`, `--pids-limit`) are not enforced.
  This repo currently writes `/home/dockeruser/.config/docker/daemon.json` to force `native.cgroupdriver=cgroupfs` as a workaround in some environments, which can cause cgroups to be effectively disabled in others.
  To verify: run `docker info | grep -i cgroup` as the rootless Docker user.
  If you need cgroup enforcement in rootless mode and your system supports it, remove that override and restart the user service (`systemctl --user restart docker`). For example arm64 Ubuntu 26.04.

- **systemd-resolved DNSSEC**: the hardening role defaults to `DNSSEC=allow-downgrade`.
  On networks where upstream answers fail validation (`no-signature`, common with
  CDN/CNAME-backed mirrors such as `deb.debian.org`), this breaks DNS and `apt`
  partway through a run. Override per host/group with `DNSSEC: false` — see the
  Troubleshooting entry above.

### Using Ansible Vault
```bash
# Create encrypted variable file
ansible-vault create inventories/your-environment/group_vars/all/vault.yml

# Edit encrypted file
ansible-vault edit inventories/your-environment/group_vars/all/vault.yml

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

**`root@host: Permission denied (publickey)` after a successful run**
- Expected. With `DISABLE_ROOT_ACCOUNT: true`, the first run disables root SSH.
  Reconnect as one of the admin users from `SSH_USERLIST` (see Quick Start step 4).

**Pre-flight fails: `Missing required variables` / `ENABLE_2FA is defined` evaluated to false**
- The target host is missing one of the mandatory variables. Define all of them
  (see Quick Start step 2); `ENABLE_2FA` is required even when set to `false`.

**`externally-managed-environment` when running `pip install`**
- You're installing into the system Python (PEP 668). Use the virtual environment
  from the Installation section: `python3 -m venv .venv && source .venv/bin/activate`.

**DNS / `apt` breaks midway through hardening (`Temporary failure resolving ...`)**
- The hardening role configures `systemd-resolved` with `DNSSEC=allow-downgrade`,
  which on some networks rejects valid answers (`DNSSEC validation failed:
  no-signature`) and breaks all name resolution — failing later `apt` tasks.
- Diagnose on the host: `resolvectl query deb.debian.org` (look for a DNSSEC error)
  and `resolvectl status | grep -i dnssec`.
- Fix: set `DNSSEC: false` in your host/group vars.
  `setup-playbook.yml` exposes `DNSSEC` and `DNS_OVER_TLS` as overridable variables.
  Validation is still performed by the upstream resolvers (`1.1.1.2`/`9.9.9.9`) and
  the channel is protected by DNS-over-TLS, so this is a safe, common posture.

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

## Acknowledgements

This project and part of its upstream contributions have received funding from the IMI 2 Joint Undertaking (JU) under grant agreement No. 101034344 and the Horizon Europe R&I program through the EBRAINS2.0 project specifically supported by the Swiss State Secretariat for Education, Research and Innovation (SERI) under contract number 23.00638.

## Support

For issues and questions:
- Check existing GitHub issues
- Create a new issue with detailed description
- Include Ansible version, target OS, and error messages
