# Ansible Docker Utility

This guide explains how to use the Ansible Docker Utility, which provides containerized Ansible environments for development and production use.

## Features

- **Two Variants Available**:
  - **Full Version**: Complete development environment with all tools (~1.5GB)
  - **Slim Version**: Minimal production-ready image with just Ansible (~500MB)

## Prerequisites

- Docker Engine 20.10.0 or later
- Docker Compose 2.0.0 or later (optional, for local development)
- Access to a container registry (for pushing images)

## Quick Start

### Running the Container

#### Full Version
```bash
docker run --rm -v $(pwd):/ansible ansible-utility:latest ansible --version
```

#### Slim Version
```bash
docker run --rm -v $(pwd):/ansible ansible-utility:slim ansible --version
```

### Local Development

Create a `docker-compose.override.yml` to customize your development environment:

```yaml
services:
  ansible:
    image: ansible-utility:latest
    volumes:
      - .:/ansible
    environment:
      ANSIBLE_FORCE_COLOR: "true"
      ANSIBLE_HOST_KEY_CHECKING: "false"
    command: ansible-playbook -i inventories/local/ test-playbook.yml
```

## Image Variants

### Full Version (`Dockerfile`)
- Includes container runtimes (containerd, nerdctl, Podman)
- Development tools and utilities
- Larger image size (~1.5GB)

### Slim Version (`Dockerfile.slim`)
- Minimal production-ready image
- Only essential dependencies
- No container runtimes
- Smaller image size (~500MB)

## Environment Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ANSIBLE_FORCE_COLOR` | `true` | Enable colored output |
| `ANSIBLE_HOST_KEY_CHECKING` | `false` | Disable host key checking |
| `DOCKER_BUILDKIT` | `1` | Enable BuildKit |
| `BUILDKIT_PROGRESS` | `plain` | Build output format |
| `DOCKER_CLI_EXPERIMENTAL` | `enabled` | Enable experimental features |

## Scheduled Tasks

### Using Host Crontab (Recommended)

For scheduled execution of playbooks, use the host system's crontab for better reliability and management.

1. **Start the container** (if not already running):
   ```bash
   docker-compose -f docker-compose.yml up -d
   ```

2. **Test running a playbook manually**:
   ```bash
   docker exec ansible-monitoring ansible-playbook /ansible/your-playbook.yml
   ```

3. **Add crontab entries** for scheduled execution:
   ```bash
   # Edit crontab
   crontab -e

   # Examples:
   # Daily at 3 AM
   0 3 * * * docker exec ansible-monitoring ansible-playbook /ansible/your-playbook.yml >> /var/log/ansible-monitoring.log 2>&1

   # Every 6 hours
   0 */6 * * * docker exec ansible-monitoring ansible-playbook /ansible/your-playbook.yml >> /var/log/ansible-monitoring.log 2>&1

   # Every Monday at 2 AM
   0 2 * * 1 docker exec ansible-monitoring ansible-playbook /ansible/your-playbook.yml >> /var/log/ansible-monitoring.log 2>&1
   ```

### Plesk Integration

1. **Deploy the image** to your registry:
   ```bash
   ./build-and-push.sh --registry your-plesk-registry.com/username --push
   ```

2. **In Plesk**:
   - Navigate to **Websites & Domains** > **Docker**
   - Add a new container with these settings:
     - Image: `your-plesk-registry.com/username/ansible-docker-utility:latest`
     - Command: `tail -f /dev/null` (keeps container running)
     - Volume mounts:
       - Host path: `/path/to/your/project`
       - Container path: `/ansible`

3. **Set up scheduled tasks** in Plesk:
   - Go to **Websites & Domains** > **Scheduled Tasks**
   - Add a new task with the command:
     ```
     /usr/bin/docker exec container_name ansible-playbook /ansible/your-playbook.yml
     ```
   - Configure the desired schedule

## Monitoring and Logs

- **Container logs**: `docker-compose logs -f`
- **Scheduled task logs**: `tail -f /var/log/ansible-monitoring.log`

## Multi-Customer Setup

For managing multiple customers with separate monitoring schedules, follow this directory structure and setup:

### Directory Structure

```
/customers/
  /customer1/
    inventory/       # Customer-specific inventory
    ansible.cfg      # Customer-specific config
    monitoring.log   # Customer-specific logs
  /customer2/
    inventory/
    ansible.cfg
    monitoring.log
```

### Per-Customer docker-compose.override.yml

Create a `docker-compose.override.yml` in each customer's directory:

```yaml
services:
  ansible:
    image: ansible-monitor:latest
    container_name: customer1-monitoring
    volumes:
      - .:/ansible
      - ./ansible.cfg:/etc/ansible/ansible.cfg
      - ./monitoring.log:/var/log/monitoring.log
    environment:
      - ANSIBLE_FORCE_COLOR=true
      - ANSIBLE_HOST_KEY_CHECKING=false
    command: tail -f /dev/null
    restart: unless-stopped
```

### Building and Running

1. **For each customer**:
   ```bash
   # Create customer directory
   mkdir -p /customers/customer1

   # Copy necessary files
   cp -r /path/to/ansible-docker-utility/* /customers/customer1/

   # Build with customer-specific schedule
   cd /customers/customer1/docker
   ./build-and-push.sh --schedule "0 */6 * * *" --name customer1-monitor

   # Start the container
   docker-compose -f docker-compose.yml up -d
   ```

### Updating a Single Customer

To update a specific customer's configuration or playbooks:
1. Make changes in the customer's directory
2. The changes are automatically reflected in the container (no rebuild needed)

### Viewing Logs

View logs for a specific customer:
```bash
tail -f /customers/customer1/monitoring.log
```

## Plesk Deployment

For deploying in Plesk's Docker extension, follow these steps for each customer:

### Prerequisites
1. Docker extension installed in Plesk
2. Access to a container registry (Docker Hub, GitHub Container Registry, etc.)
3. SSH access to the server (for initial setup)

### Initial Setup

1. **Build and push the base image** (do this once):
   ```bash
   ./build-and-push.sh --registry your-registry.com/digi4care --push
   ```

2. **Create customer directories** on the VPS:
   ```bash
   mkdir -p /customers/customer1/inventory
   cp -r /path/to/ansible-docker-utility/* /customers/customer1/
   # Configure customer-specific files in /customers/customer1/
   ```

### Plesk Container Setup

For each customer in Plesk:

1. Go to **Websites & Domains** > **Docker**
2. Click **Add Container**
3. Configure the container:
   - **Name**: `customer1-monitoring` (unique per customer)
   - **Image**: `your-registry.com/digi4care/ansible-docker-utility:latest`
   - **Command**: `/ansible/setup-cron.sh`

4. **Volume Mappings** (Add for each):
   | Host Path | Container Path | Read/Write |
   |------------|----------------|------------|
   | `/customers/customer1` | `/ansible` | Read/Write |
   | `/customers/customer1/ansible.cfg` | `/etc/ansible/ansible.cfg` | Read Only |
   | `/customers/customer1/monitoring.log` | `/var/log/monitoring.log` | Read/Write |

5. **Environment Variables** (Add each):
   - `ANSIBLE_FORCE_COLOR=true`
   - `ANSIBLE_HOST_KEY_CHECKING=false`
   - `TZ=Europe/Amsterdam` (set to your timezone)

6. **Advanced Settings**:
   - **Autostart**: Enabled
   - **Restart Policy**: unless-stopped
   - **Network Mode**: bridge (default)

### Verifying the Setup

1. **Check container status** in Plesk Docker interface
2. **View logs** in Plesk or via SSH:
   ```bash
   tail -f /customers/customer1/monitoring.log
   ```
3. **Test notifications** by manually triggering the playbook:
   ```bash
   docker exec -it customer1-monitoring ansible-playbook -i /ansible/inventories/ site.yml
   ```

## Troubleshooting

- **Permission issues**: Ensure your user has access to the Docker socket or is in the `docker` group
- **Cron not running**: Check container logs with `docker-compose logs`
- **Playbook failures**: Check the monitoring log file for detailed error output

## Security Considerations

- **Sensitive Data**: Never commit sensitive data to the image
  - Use Ansible Vault for secrets (see [VAULT.md](VAULT.md))
  - Store vault password files outside the container
- **Credentials**:
  - Use Docker secrets or environment variables for runtime credentials
  - Set appropriate file permissions (chmod 600 for sensitive files)
- **Updates**:
  - Regularly update the base image for security patches
  - Rebuild and redeploy containers when updating playbooks or dependencies
- **Access Control**:
  - Restrict access to customer directories
  - Use separate vault passwords per customer for enhanced security
