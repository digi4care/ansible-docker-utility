# Ansible Vault Management

This document explains how to manage sensitive data using Ansible Vault in this project.

## Table of Contents
- [Creating a New Vault](#creating-a-new-vault)
- [Editing the Vault](#editing-the-vault)
- [Viewing Vault Contents](#viewing-vault-contents)
- [Changing the Vault Password](#changing-the-vault-password)
- [Using Vault in Playbooks](#using-vault-in-playbooks)
- [Best Practices](#best-practices)

## Creating a New Vault

### 1. First-Time Setup (Local Machine)

1. **Create a secure directory** for your vault password:
   ```bash
   mkdir -p ~/.ansible/vault
   chmod 700 ~/.ansible/vault
   ```

2. **Generate a secure password file**:
   ```bash
   # For production:
   openssl rand -base64 32 > ~/.ansible/vault/prod_vault_pass.txt
   chmod 600 ~/.ansible/vault/prod_vault_pass.txt
   
   # For development (if needed):
   # openssl rand -base64 32 > ~/.ansible/vault/dev_vault_pass.txt
   # chmod 600 ~/.ansible/vault/dev_vault_pass.txt
   ```

### 2. Create the Encrypted Vault File

1. **Create a new vault** using the password file:
   ```bash
   ansible-vault create \
     --vault-password-file ~/.ansible/vault/prod_vault_pass.txt \
     inventories/production/group_vars/vault.yml
   ```

2. **Add your sensitive variables** in the editor that opens:
   ```yaml
   # Example content - replace with your actual secrets
   vault_database_password: "db-password-here"
   vault_api_key: "your-api-key-here"
   ```

3. **Save and close** the editor. The file will be encrypted automatically.

### 3. Verify Vault Creation

Check that the file was created and is encrypted:
```bash
file inventories/production/group_vars/vault.yml
# Should show: "ASCII text, with very long lines"

# View the encrypted content:
cat inventories/production/group_vars/vault.yml
# Should show encrypted content starting with: $ANSIBLE_VAULT;1.1;AES256
```

### 4. (One-Time) Deploy Password to Production VPS

```bash
# On your local machine, copy the password file to your VPS:
scp ~/.ansible/vault/prod_vault_pass.txt root@your-vps-ip:/etc/ansible/

# On the VPS, secure the password file:
chmod 600 /etc/ansible/prod_vault_pass.txt
chown root:root /etc/ansible/prod_vault_pass.txt
```

## Editing the Vault

To edit an existing vault:

```bash
ansible-vault edit inventories/<environment>/group_vars/vault.yml
# or with password file
ansible-vault edit --vault-password-file ~/.ansible/vault_pass_<environment> inventories/<environment>/group_vars/vault.yml
```

## Viewing Vault Contents

To view vault contents without editing:

```bash
ansible-vault view inventories/<environment>/group_vars/vault.yml
```

## Changing the Vault Password

### Method 1: Interactive (prompt for passwords)

```bash
ansible-vault rekey inventories/<environment>/group_vars/vault.yml
# You'll be prompted for:
# 1. Current vault password
# 2. New vault password
# 3. New vault password (confirmation)
```

### Method 2: Using Password Files

1. Create a new password file:
   ```bash
   # Generate a strong password
   openssl rand -base64 32 > ~/.ansible/vault_pass_<environment>_new
   chmod 600 ~/.ansible/vault_pass_<environment>_new
   ```

2. Rekey the vault:
   ```bash
   ansible-vault rekey \
     --new-vault-password-file ~/.ansible/vault_pass_<environment>_new \
     --vault-password-file ~/.ansible/vault_pass_<environment>_old \
     inventories/<environment>/group_vars/vault.yml
   ```

3. Verify the new password works:
   ```bash
   ansible-vault view --vault-password-file ~/.ansible/vault_pass_<environment>_new \
     inventories/<environment>/group_vars/vault.yml
   ```

4. Replace the old password file:
   ```bash
   mv ~/.ansible/vault_pass_<environment>_new ~/.ansible/vault_pass_<environment>
   ```

## Deployment Scenarios

### 1. Local Development Setup

1. **Create a secure directory** for your vault password:
   ```bash
   mkdir -p ~/.ansible/vault
   chmod 700 ~/.ansible/vault
   ```

2. **Generate a secure password file**:
   ```bash
   openssl rand -base64 32 > ~/.ansible/vault/prod_vault_pass.txt
   chmod 600 ~/.ansible/vault/prod_vault_pass.txt
   ```

3. **Create/edit your vault**:
   ```bash
   ansible-vault edit --vault-password-file ~/.ansible/vault/prod_vault_pass.txt \
     inventories/production/group_vars/vault.yml
   ```

### 2. Plesk with Admin Access

1. **On your VPS**, create a secure directory:
   ```bash
   sudo mkdir -p /etc/ansible
   sudo chmod 700 /etc/ansible
   ```

2. **Copy the password file** from your local machine:
   ```bash
   scp ~/.ansible/vault/prod_vault_pass.txt root@your-vps-ip:/etc/ansible/
   ```

3. **In Plesk UI**:
   - Go to **Container** settings
   - Under **Volumes**, add:
     - Host path: `/etc/ansible/prod_vault_pass.txt`
     - Container path: `/etc/ansible/vault_pass.txt`
     - Check **Read Only**
   - Set container command:
     ```bash
     ansible-playbook -i /ansible/inventories/ site.yml --vault-password-file /etc/ansible/vault_pass.txt
     ```

### 3. Plesk without Admin Access (Method 1 - Environment Variable)

1. **In Plesk UI**:
   - Go to **Websites & Domains** > **Your Domain** > **Environment Variables**
   - Add variable:
     - Name: `ANSIBLE_VAULT_PASSWORD`
     - Value: `paste-contents-of-prod_vault_pass.txt`

2. **Set container command**:
   ```bash
   sh -c 'echo "$ANSIBLE_VAULT_PASSWORD" > /tmp/vault_pass.txt && \
   ansible-playbook -i /ansible/inventories/ site.yml --vault-password-file /tmp/vault_pass.txt && \
   rm /tmp/vault_pass.txt'
   ```

### 4. Plesk without Admin Access (Method 2 - Home Directory)

1. **On VPS** (via SSH):
   ```bash
   mkdir -p ~/ansible_secrets
   chmod 700 ~/ansible_secrets
   # Upload your password file here via SFTP/SCP
   ```

2. **In Plesk UI**:
   - Under **Volumes**, add:
     - Host path: `/home/your-user/ansible_secrets/prod_vault_pass.txt`
     - Container path: `/ansible/vault_pass.txt`
     - Read Only: Yes
   - Set container command:
     ```bash
     ansible-playbook -i /ansible/inventories/ site.yml --vault-password-file /ansible/vault_pass.txt
     ```

## Vault Variables Reference

The following variables should be stored in your vault file (`inventories/<environment>/group_vars/vault.yml`):

### 1. Notification Credentials

```yaml
# Email Notifications
vault_smtp_username: "your-smtp-username@example.com"
vault_smtp_password: "your-smtp-password"

# Telegram Bot
vault_telegram_bot_token: "1234567890:ABCdefGHIjklmNOPQRSTUVWXYZ"
vault_telegram_chat_id: "@your_channel_username"  # or your personal chat ID

# Discord Webhook
vault_discord_webhook_url: "https://discord.com/api/webhooks/..."

# Slack Webhook
vault_slack_webhook_url: "https://hooks.slack.com/services/..."
```

### 2. API Keys

```yaml
# Monitoring Services
vault_uptimerobot_api_key: "u1234-567890abcdef1234567890abcdef"
vault_newrelic_api_key: "NRAK-1234567890abcdef1234567890abcdef"

# Cloud Provider APIs
vault_aws_access_key: "AKIAXXXXXXXXXXXXXXXX"
vault_aws_secret_key: "your-aws-secret-key-here"
```

### 3. Database Credentials

```yaml
# MySQL/MariaDB
vault_mysql_root_password: "your-secure-db-password"
vault_mysql_monitoring_user: "monitoring_user"
vault_mysql_monitoring_password: "monitoring-password"

# PostgreSQL
vault_postgres_admin_password: "your-secure-pg-password"
vault_postgres_monitoring_password: "monitoring-pg-password"
```

### 4. Application Secrets

```yaml
# API Keys
vault_api_secret_key: "your-api-secret-key-here"
vault_jwt_secret: "your-jwt-secret-key-here"

# Encryption Keys
vault_encryption_key: "your-32-byte-encryption-key-here"
```

### 5. System Credentials

```yaml
# SSH Keys
vault_ssh_private_key: |
  -----BEGIN RSA PRIVATE KEY-----
  Your private key here...
  -----END RSA PRIVATE KEY-----

# Sudo Passwords
vault_sudo_password: "your-sudo-password"
```

### Usage in Playbooks

Reference these variables in your playbooks like this:

```yaml
- name: Configure database connection
  template:
    src: templates/db-config.j2
    dest: /etc/app/db.conf
    owner: root
    group: root
    mode: '0600'
  no_log: true  # Prevents logging sensitive data
  vars:
    db_password: "{{ vault_mysql_monitoring_password }}"
```

### Security Notes for All Methods

- Never commit the vault password file to git
- Use different passwords for different environments
- The password should only be accessible to authorized users
- Consider rotating the vault password periodically (every 90 days recommended)
- For production, consider using a dedicated secrets manager if available
- Use `no_log: true` for tasks that handle sensitive data
- Restrict file permissions on vault files (`chmod 600`)

### Local Development Setup

1. **Create a vault password file** on your local machine:
   ```bash
   # Create a directory for Ansible vault files
   mkdir -p ~/.ansible/vault
   # Generate a secure random password
   openssl rand -base64 32 > ~/.ansible/vault/vault_pass.txt

   # Secure the file
   chmod 600 ~/.ansible/vault/vault_pass.txt  # Only you can read/write
   ```

2. **Edit your vault** locally:
   ```bash
   ansible-vault edit --vault-password-file ~/.ansible/vault/vault_pass.txt \
     inventories/production/group_vars/vault.yml
   ```

### Production VPS Setup

1. **On your VPS**, create a secure directory:
   ```bash
   sudo mkdir -p /etc/ansible
   sudo chmod 700 /etc/ansible
   ```

2. **Copy the vault password file** from your local machine to the VPS:
   ```bash
   # Run this from your local machine:
   scp ~/.ansible/vault/vault_pass.txt root@your-vps-ip:/etc/ansible/vault_pass.txt
   ```

3. **Set secure permissions** on the VPS:
   ```bash
   sudo chmod 600 /etc/ansible/vault_pass.txt
   sudo chown root:root /etc/ansible/vault_pass.txt
   ```

### Plesk Container Configuration

1. **In Plesk UI**, when creating/editing the container:
   - Go to **Volumes** section
   - Add a new volume:
     - Host path: `/etc/ansible/vault_pass.txt`
     - Container path: `/etc/ansible/vault_pass.txt`
     - Check **Read Only**

2. **Update your playbook command** in the container's setup:
   ```yaml
   command: >
     ansible-playbook -i /ansible/inventories/ site.yml
     --vault-password-file /etc/ansible/vault_pass.txt
   ```

### Security Notes
- Never commit the vault password file to git
- The password file should only exist in two places:
  1. Your local machine (for development)
  2. The production VPS (for running playbooks)
- Use different passwords for different environments (dev/staging/prod)

## Using Vault in Playbooks

### Running Playbooks

```bash
# Method 1: Prompt for password
ansible-playbook -i inventories/<environment> site.yml --ask-vault-pass

# Method 2: Use password file
ansible-playbook -i inventories/<environment> site.yml \
  --vault-password-file ~/.ansible/vault_pass_<environment>

# Method 3: Set environment variable
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible/vault_pass_<environment>
ansible-playbook -i inventories/<environment> site.yml
```

### In Playbooks

Reference vault variables like this:

```yaml
- name: Example task using vault variables
  debug:
    msg: "Database password is {{ vault_database_password }}"
  no_log: true  # Prevents logging sensitive data
```

## Best Practices

1. **Never commit unencrypted secrets** to version control
2. **Use different vaults** for different environments (dev/staging/prod)
3. **Rotate vault passwords** periodically (every 90 days recommended)
4. **Limit access** to the vault password to authorized personnel only
5. **Use `no_log: true`** in tasks that might expose sensitive data
6. **Audit access** to the vault file
7. **Store password files** in a secure location (e.g., `~/.ansible/` with restricted permissions)
8. **Use a password manager** to store and share vault passwords securely
9. **Document** where and how vault is used in your project
10. **Test vault operations** in a non-production environment first

## Troubleshooting

### Common Issues

1. **Incorrect Vault Password**
   - Verify you're using the correct password file
   - Check for trailing newlines in password files

2. **Permission Issues**
   - Ensure password files have correct permissions: `chmod 600 ~/.ansible/vault_pass_*`
   - Verify the vault file is readable by the Ansible user

3. **Environment Variables**
   - Check if `ANSIBLE_VAULT_PASSWORD_FILE` is set and points to the correct file
   - Ensure no conflicting vault password sources are being used

For additional help, refer to the [Ansible Vault documentation](https://docs.ansible.com/ansible/latest/cli/ansible-vault.html).
