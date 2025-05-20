# Ansible Docker Utility

A comprehensive Docker image containing Ansible and essential tools for infrastructure automation and testing. Available in two variants:

1. **Full Version**: Complete development environment with all tools
2. **Slim Version**: Minimal image with just Ansible and essential dependencies

## Features

### Full Version
- 🐍 **Python 3.11**-based image with latest Ansible
- 🔄 **Multi-stage build** for optimized image size
- 🔐 **Secure by default** - runs as non-root user
- 🐳 **Container Runtimes**:
  - **containerd** (lightweight, production-grade runtime)
  - **nerdctl** (Docker-compatible CLI for containerd)
  - **Podman** (daemonless container management)
- 🛠️ **Pre-installed Tools**:
  - Git & Git LFS
  - SSH client with SSH agent support
  - SSH key management
  - rsync, curl, wget, jq
  - Common editors: vim, nano
  - Molecule test framework
  - Vagrant & VirtualBox

### Slim Version
- 🚀 **Ultra-lightweight** (~50% smaller than full version)
- 🐍 **Python 3.11** with Ansible core
- 🔐 **Non-root** user by default
- 🔋 **Minimal Dependencies**:
  - OpenSSH client
  - SSH key management
  - Git for version control
  - sudo for privilege escalation
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
