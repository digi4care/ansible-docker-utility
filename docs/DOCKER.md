# Docker Setup for Ansible

This guide explains how to build, run, and deploy the Ansible Docker Utility images. Two variants are available:

1. **Full Version**: Complete development environment with all tools
2. **Slim Version**: Minimal image with just Ansible and essential dependencies

## Prerequisites

- Docker Engine 20.10.0 or later
- Docker Compose 2.0.0 or later
- Access to a container registry (if pushing images)

## Image Variants

### Full Version (`Dockerfile`)
- Complete development environment
- Includes container runtimes (containerd, nerdctl, Podman)
- Development tools and utilities
- Larger image size (~1.5GB)

### Slim Version (`Dockerfile.slim`)
- Minimal production-ready image
- Only essential dependencies
- No container runtimes
- Smaller image size (~500MB)

## Directory Structure

```
.
└── docker/
    ├── Dockerfile          # Docker image definition
    ├── docker-compose.yml  # Docker Compose configuration
    ├── build-and-push.sh   # Build and push script
    └── requirements.txt    # Python dependencies
```

## Quick Start

### Full Version

1. **Build the Docker image**:
   ```bash
   ./build-and-push.sh --name ansible-utility --tag latest
   ```
   
2. **Run the container**:
   ```bash
   docker run --rm -v $(pwd):/ansible ansible-utility:latest ansible --version
   ```

### Slim Version

1. **Build the slim Docker image**:
   ```bash
   ./build-and-push.sh -f build/Dockerfile.slim --name ansible-utility --tag slim
   ```
   
2. **Run the container**:
   ```bash
   docker run --rm -v $(pwd):/ansible ansible-utility:slim ansible --version
   ```

2. **Run the container**:
   ```bash
   docker-compose -f docker-compose.yml up -d
   ```

### Local Development with docker-compose.override.yml

For local development, you can create a `docker-compose.override.yml` file to customize the container's behavior without modifying the main configuration:

```yaml
services:
  ansible:
    image: ansible-monitor:test
    volumes:
      - .:/ansible
    environment:
      ANSIBLE_FORCE_COLOR: "true"
      ANSIBLE_HOST_KEY_CHECKING: "false"
    command: ansible-playbook -i inventories/local/ test-playbook.yml
```

This override file is automatically used by Docker Compose and is ignored by git (if added to .gitignore). It's useful for:
- Running specific playbooks during development
- Mounting local directories for live code changes
- Setting environment variables specific to your local environment

## Building the Images

### Building a Specific Variant

```bash
# Build full version (default)
./build-and-push.sh -t latest

# Build slim version
./build-and-push.sh -f build/Dockerfile.slim -t slim
```

## Build Script Reference

The `build-and-push.sh` script simplifies image building and publishing:

### Usage

```bash
./build-and-push.sh [options]
```

### Options

| Option | Description |
|--------|-------------|
| `-f, --file` | Path to Dockerfile (default: build/Dockerfile) |
| `-n, --name` | Image name (default: ansible-docker-utility) |
| `-t, --tag` | Image tag (default: latest) |
| `-r, --registry` | Registry URL (e.g., registry.example.com/username) |
| `-p, --push` | Push to registry after build |
| `--prune` | Prune Docker system before build |
| `--no-cache` | Build without using cache |
| `-h, --help` | Show help message |

### Advanced Usage

```bash
# Build with custom Dockerfile and push to registry
./build-and-push.sh -f build/Dockerfile.slim -t v1.0.0 -r myregistry -p

# Build with no cache and system prune
./build-and-push.sh --no-cache --prune

# Multi-architecture build (experimental)
./build-and-push.sh --platform linux/amd64,linux/arm64
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_BUILDKIT` | `1` | Enable BuildKit |
| `BUILDKIT_PROGRESS` | `plain` | Build output format |
| `DOCKER_CLI_EXPERIMENTAL` | `enabled` | Enable experimental features |

### Custom Build Hooks

The script supports the following hooks if they exist in the project root:
- `pre-build.sh`: Executed before the build starts
- `post-build.sh`: Executed after successful build
- `pre-push.sh`: Executed before pushing to registry
- `post-push.sh`: Executed after successful push

Example `pre-build.sh`:
```bash
#!/bin/bash
echo "[$(date)] Starting build of $IMAGE_NAME:$TAG"
# Run tests, linting, etc.
```

Make hooks executable:
```bash
chmod +x pre-build.sh post-build.sh pre-push.sh post-push.sh
```

## Scheduled Execution with Host Crontab

For scheduled execution of playbooks, we recommend using the host system's crontab instead of running cron inside the container. This approach is more reliable and easier to manage.

### Setting Up Scheduled Execution

1. **Start the container** (if not already running):
   ```bash
   docker-compose -f docker-compose.yml up -d
   ```

2. **Test running a playbook manually**:
   ```bash
   docker exec ansible-monitoring ansible-playbook /ansible/your-playbook.yml
   ```

3. **Add a crontab entry on the host** to run the playbook on a schedule:
   ```bash
   # Edit crontab
   crontab -e

   # Add this line to run daily at 3 AM
   0 3 * * * docker exec ansible-monitoring ansible-playbook /ansible/your-playbook.yml >> /path/to/ansible-monitoring.log 2>&1
   ```

### Example Crontab Entries

- **Daily at 3 AM**:
  ```
  0 3 * * * docker exec ansible-monitoring ansible-playbook /ansible/your-playbook.yml >> /var/log/ansible-monitoring.log 2>&1
  ```

- **Every 6 hours**:
  ```
  0 */6 * * * docker exec ansible-monitoring ansible-playbook /ansible/your-playbook.yml >> /var/log/ansible-monitoring.log 2>&1
  ```

- **Every Monday at 2 AM**:
  ```
  0 2 * * 1 docker exec ansible-monitoring ansible-playbook /ansible/your-playbook.yml >> /var/log/ansible-monitoring.log 2>&1
  ```

### Viewing Logs

To monitor the scheduled executions, check the log file specified in your crontab:
```bash
tail -f /var/log/ansible-monitoring.log
```

## Plesk Integration

To use this with Plesk:

1. Build and push the image to your registry:
   ```bash
   ./build-and-push.sh --registry your-plesk-registry.com/username --push
   ```

2. In PlesK:
   - Go to **Websites & Domains** > **Docker**
   - Add a new container
   - Use the image URL: `your-plesk-registry.com/username/ansible-docker-utility:latest`
   - Set the command to: `tail -f /dev/null` (to keep container running)
   - Add volume mounts:
     - Host path: `/path/to/your/project`
     - Container path: `/ansible`
   - Add environment variables as needed

3. **Set up scheduled tasks in Plesk**:
   - Go to **Websites & Domains** > **Scheduled Tasks**
   - Add a new task
   - Set the command to:
     ```
     /usr/bin/docker exec container_name ansible-playbook /ansible/your-playbook.yml
     ```
   - Set your desired schedule

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ANSIBLE_FORCE_COLOR` | `true` | Enable colored output |
| `ANSIBLE_HOST_KEY_CHECKING` | `false` | Disable host key checking |

## Logs and Monitoring

- Container logs: `docker-compose logs -f`
- Cron job logs: `tail -f monitoring.log`

## Updating the Image

1. Make your changes to the playbooks or configuration
2. Rebuild the image:
   ```bash
   ./build-and-push.sh --tag v2.0
   ```
3. Update your deployment to use the new tag

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
