# Ansible Docker Utility

A comprehensive Docker image containing Ansible and essential tools for infrastructure automation and testing. This image is designed to be used as a utility container for running Ansible playbooks, testing roles with Molecule, and managing containerized environments.

## Features

- 🐍 **Python 3.11**-based image with latest Ansible
- 🔄 **Multi-stage build** for optimized image size
- 🔐 **Secure by default** - runs as non-root user
- 🐳 **Container Runtimes**:
  - **containerd** (lightweight, production-grade runtime)
  - **nerdctl** (Docker-compatible CLI for containerd)
  - **Podman** (daemonless container management)
  - Docker (via containerd, no Docker daemon required)
- 🛠️ **Pre-installed Tools**:
  - Git & Git LFS
  - SSH client with SSH agent support
  - SSH key management
  - rsync, curl, wget, jq
  - Common editors: vim, nano
  - Molecule test framework
  - Vagrant & VirtualBox
- 📦 **Package Management**:
  - pip for Python packages
  - apt for system packages
- 🔄 **Persistent SSH Agent** across container sessions
- 🎨 **Colorized output** enabled by default

## Prerequisites

- Docker 20.10.0 or higher
- Git (for version control integration)
- For Docker-in-Docker: Kernel 5.11+ recommended
- For Podman: User namespaces enabled in kernel

## Quick Start

### Pull from Docker Hub

```bash
docker pull chrisengelhard/ansible-docker-utility:latest
```

### Basic Usage

#### Run a one-off Ansible command

```bash
docker run --rm \
  -v $(pwd):/ansible \
  -w /ansible \
  chrisengelhard/ansible-docker-utility \
  ansible --version
```

#### Run a playbook

```bash
docker run --rm \
  -v $(pwd):/ansible \
  -w /ansible \
  chrisengelhard/ansible-docker-utility \
  ansible-playbook site.yml
```

### Advanced Usage

#### Using containerd (Recommended)

```bash
docker run --rm \
  -v $(pwd):/ansible \
  -v /run/containerd/containerd.sock:/run/containerd/containerd.sock \
  -w /ansible \
  ansible-docker-utility:containerd \
  nerdctl run --rm hello-world
```

#### Using Docker-in-Docker (Legacy)

```bash
docker run --rm \
  --privileged \
  -v $(pwd):/ansible \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -w /ansible \
  chrisengelhard/ansible-docker-utility \
  ansible-playbook docker-playbook.yml
```

#### Using Podman

```bash
docker run --rm \
  --security-opt label=disable \
  --device /dev/fuse \
  -v $(pwd):/ansible \
  -w /ansible \
  chrisengelhard/ansible-docker-utility \
  podman run --rm hello-world
```

#### Using Molecule

```bash
docker run --rm \
  -v $(pwd):/ansible \
  -w /ansible \
  -v /var/run/docker.sock:/var/run/docker.sock \
  chrisengelhard/ansible-docker-utility \
  molecule test
```

## Building Locally

### Standard Build (Docker)

```bash
git clone https://github.com/digi4care/ansible-docker-utility.git
cd ansible-docker-utility
docker build -t ansible-docker-utility -f _build/Dockerfile .
```

### Build with containerd (Recommended)

```bash
docker build -t ansible-docker-utility:containerd -f Dockerfile.containerd .
```

### Build with Podman

```bash
podman build -t ansible-docker-utility -f _build/Dockerfile .
```

### Build Options

The build process supports the following build arguments:

| Argument | Default | Description |
|----------|---------|-------------|
| `USER` | `ansible` | Non-root username |
| `UID` | `1000` | User ID |
| `GID` | `1000` | Group ID |

Example with custom user:
```bash
docker build \
  --build-arg USER=myuser \
  --build-arg UID=1001 \
  --build-arg GID=1001 \
  -t ansible-docker-utility \
  -f _build/Dockerfile .
```

## Publishing to Docker Hub

1. Log in to Docker Hub:
   ```bash
   docker login --username=chrisengelhard
   ```

2. Tag the image with your Docker Hub username:
   ```bash
   docker tag ansible-docker-utility chrisengelhard/ansible-docker-utility:latest
   ```

3. Push the image to Docker Hub:
   ```bash
   docker push chrisengelhard/ansible-docker-utility:latest
   ```

## Using the Build Script

A convenience script is provided to build and optionally push the image:

```bash
# Build the image
./bin/build-and-push.sh -b

# Build and push to Docker Hub
./bin/build-and-push.sh -b -p -u chrisengelhard

# Show all options
./bin/build-and-push.sh --help
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ANSIBLE_FORCE_COLOR` | `1` | Force color output in Ansible |
| `ANSIBLE_HOST_KEY_CHECKING` | `False` | Disable SSH host key checking |
| `ANSIBLE_SSH_RETRIES` | `3` | Number of SSH connection retries |
| `ANSIBLE_SSH_RETRY_DELAY` | `5` | Delay between SSH retries (seconds) |
| `PYTHONUNBUFFERED` | `1` | Unbuffered Python output |
| `PYTHONIOENCODING` | `UTF-8` | Python I/O encoding |
| `LANG` | `C.UTF-8` | System locale |
| `LC_ALL` | `C.UTF-8` | System locale (overrides LANG) |

### Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `$(pwd)` | `/ansible` | Working directory for Ansible |
| `~/.ssh` | `/home/ansible/.ssh` | SSH keys and configuration |
| `/run/containerd/containerd.sock` | `/run/containerd/containerd.sock` | containerd socket |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker socket (Legacy DinD) |

### SSH Agent Forwarding

The container automatically loads SSH keys from `/home/ansible/.ssh` and starts an SSH agent. To forward your host's SSH agent:

```bash
docker run --rm \
  -v $(pwd):/ansible \
  -v "$SSH_AUTH_SOCK:/tmp/ssh_auth_sock" \
  -e "SSH_AUTH_SOCK=/tmp/ssh_auth_sock" \
  chrisengelhard/ansible-docker-utility \
  ansible-playbook site.yml
```

## Security Considerations

### Running as Non-Root

The container runs as a non-root user by default. If you need to run privileged operations, you can use `sudo` or run the container with `--user root`.

### SSH Key Management

SSH keys are automatically loaded from `/home/ansible/.ssh`. Ensure proper permissions:
- Private keys: `600`
- Public keys: `644`
- `.ssh` directory: `700`

### Container Runtime Security

- **containerd**: Mounting the containerd socket provides container management capabilities. Use with trusted containers.
- **Docker Socket**: Mounting the Docker socket (`/var/run/docker.sock`) gives the container root access to the host system. Consider using containerd instead for better security.

## Troubleshooting

### Common Issues

1. **Permission denied when accessing containerd socket**
   ```bash
   # Ensure the containerd socket is readable
   sudo chmod 666 /run/containerd/containerd.sock
   
   # Or run with the correct user/group
   docker run --rm \
     -v /run/containerd/containerd.sock:/run/containerd/containerd.sock \
     --user $(id -u):$(getent group containerd | cut -d: -f3) \
     ansible-docker-utility:containerd \
     nerdctl ps
   ```

2. **Using Docker socket (legacy)**
   ```bash
   # Ensure the Docker socket is readable by the container user
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
     --user $(id -u):$(getent group docker | cut -d: -f3) \
     chrisengelhard/ansible-docker-utility \
     docker ps
   ```

2. **SSH key permissions**
   ```bash
   # Fix permissions for mounted .ssh directory
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_*
   chmod 644 ~/.ssh/*.pub
   ```

3. **Podman rootless issues**
   Ensure user namespaces are enabled in the kernel:
   ```bash
   echo "kernel.unprivileged_userns_clone=1" | sudo tee /etc/sysctl.d/99-userns.conf
   sudo sysctl -p
   ```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

- [Your Name] - [Your Website]
- GitHub: [@digi4care](https://github.com/digi4care)

## Acknowledgments

- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Documentation](https://docs.docker.com/)
- [Podman Documentation](https://podman.io/docs/)
- [Molecule Documentation](https://molecule.readthedocs.io/)
