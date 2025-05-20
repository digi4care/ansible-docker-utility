# Build and Push Script Documentation

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
  - [Basic Commands](#basic-commands)
  - [Advanced Options](#advanced-options)
  - [Examples](#examples)
- [Environment Variables](#environment-variables)
- [Exit Codes](#exit-codes)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Version History](#version-history)

## Overview

The `build-and-push.sh` script is a powerful utility designed to simplify the process of building, tagging, and pushing Docker images. It provides a consistent and repeatable way to manage Docker images across different environments.

## Features

- **Image Building**: Build Docker images with customizable options
- **Prune Management**: Clean up Docker system and builder cache
- **Registry Support**: Tag and push images to container registries
- **Container Management**: Start and manage containers with ease
- **Automation**: Designed for CI/CD pipelines and automated workflows
- **Configuration**: Customize behavior through command-line options

## Prerequisites

- Docker Engine 20.10.0 or later
- Bash shell (for script execution)
- Sufficient disk space for Docker images
- Network access to container registries (if pushing images)

## Installation

1. Make the script executable:
   ```bash
   chmod +x bin/build-and-push.sh
   ```

2. (Optional) Add to PATH for easier access:
   ```bash
   ln -s $(pwd)/bin/build-and-push.sh /usr/local/bin/build-and-push
   ```

## Usage

### Basic Commands

```bash
# Show help
./bin/build-and-push.sh --help

# Build an image
./bin/build-and-push.sh --build

# Build and tag an image
./bin/build-and-push.sh --build --name myapp --tag v1.0

# Build and push to registry
./bin/build-and-push.sh --build --push --registry myregistry.com/username

# Start a container
./bin/build-and-push.sh --start
```

### Advanced Options

| Option | Description |
|--------|-------------|
| `-n, --name <name>` | Image name (default: ansible-docker-utility) |
| `-t, --tag <tag>` | Image tag (default: latest) |
| `-r, --registry <url>` | Registry URL (e.g., registry.example.com/username) |
| `-p, --push` | Push to registry after build |
| `-b, --build` | Build the Docker image |
| `-s, --start` | Start the container |
| `-pr, --prune` | Run both system and builder prune |
| `-sp, --system-prune` | Run docker system prune |
| `-bp, --builder-prune` | Run docker builder prune |
| `-h, --help` | Show help message |

### Examples

**Build and Push to Private Registry**
```bash
./bin/build-and-push.sh -b -p -r myregistry.com/username -t v1.0.0
```

**Clean Build with Prune**
```bash
./bin/build-and-push.sh -b -pr
```

**Start Development Container**
```bash
./bin/build-and-push.sh -s -t dev
```

**Multi-stage Build**
```bash
# Build base image
./bin/build-and-push.sh -b -t base

# Build final image using base
./bin/build-and-push.sh -b -t final --build-arg BASE_IMAGE=base
```

## Environment Variables

The script respects the following environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_BUILDKIT` | `1` | Enable BuildKit features |
| `BUILDKIT_PROGRESS` | `plain` | Build output format |
| `TZ` | System timezone | Container timezone |
| `HTTP_PROXY` | - | HTTP proxy for builds |
| `HTTPS_PROXY` | - | HTTPS proxy for builds |

## Exit Codes

| Code | Description |
|------|-------------|
| 0 | Success |
| 1 | General error |
| 2 | Build failed |
| 3 | Push failed |
| 4 | Container start failed |
| 5 | Invalid arguments |

## Troubleshooting

**Build Fails with Permission Denied**
```bash
# Check Docker permissions
sudo usermod -aG docker $USER
newgrp docker
```

**Push Fails with Unauthorized**
```bash
# Log in to registry
docker login myregistry.com
```

**Container Fails to Start**
```bash
# Check logs
docker logs container_name

# Check running containers
docker ps -a
```

## Best Practices

1. **Tagging**
   - Use semantic versioning for tags
   - Always tag production images explicitly
   - Avoid using `latest` in production

2. **Building**
   - Use `--no-cache` for clean builds
   - Leverage Docker layer caching
   - Keep build context minimal with `.dockerignore`

3. **Security**
   - Scan images for vulnerabilities
   - Use multi-stage builds to reduce attack surface
   - Never store credentials in the image

4. **CI/CD Integration**
   - Set up automated builds on push
   - Run tests before pushing
   - Use environment-specific registries

## Version History

### v1.2.0 (2025-05-20)
- Added support for container management
- Improved build options
- Added system pruning capabilities

### v1.1.0 (2025-04-15)
- Added registry push support
- Improved error handling
- Added help documentation

### v1.0.0 (2025-03-01)
- Initial release
- Basic build and tag functionality