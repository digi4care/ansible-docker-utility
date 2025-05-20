# Ansible Docker Utility

A lightweight Docker image containing Ansible and essential tools for infrastructure automation. This image is designed to be used as a utility container for running Ansible playbooks and commands.

## Features

- Multi-stage build for optimized image size
- Includes Ansible and common dependencies
- Pre-installed tools: git, ssh-client, sshpass
- Working directory: `/ansible`
- Runs as non-root user by default

## Prerequisites

- Docker 20.10.0 or higher
- Git (for version control integration)

## Quick Start

### Pull from Docker Hub

```bash
docker pull chrisengelharde/ansible-docker-utility:latest
```

### Run a one-off Ansible command

```bash
docker run --rm -v $(pwd):/ansible -w /ansible chrisengelharde/ansible-docker-utility ansible --version
```

### Run a playbook

```bash
docker run --rm -v $(pwd):/ansible -w /ansible chrisengelharde/ansible-docker-utility ansible-playbook site.yml
```

## Building Locally

1. Clone the repository:
   ```bash
   git clone https://github.com/digi4care/ansible-docker-utility.git
   cd ansible-docker-utility
   ```

2. Build the image:
   ```bash
   docker build -t ansible-docker-utility -f docker/Dockerfile .
   ```

## Publishing to Docker Hub

1. Log in to Docker Hub:
   ```bash
   docker login --username=chrisengelharde
   ```

2. Tag the image with your Docker Hub username:
   ```bash
   docker tag ansible-docker-utility chrisengelharde/ansible-docker-utility:latest
   ```

3. Push the image to Docker Hub:
   ```bash
   docker push chrisengelharde/ansible-docker-utility:latest
   ```

## Using the Build Script

A convenience script is provided to build and optionally push the image:

```bash
# Build the image
./bin/build-and-push.sh -b

# Build and push to Docker Hub
./bin/build-and-push.sh -b -p -u chrisengelharde

# Show all options
./bin/build-and-push.sh --help
```

## Environment Variables

The following environment variables can be set when running the container:

- `ANSIBLE_FORCE_COLOR`: Set to `1` to force color output
- `ANSIBLE_HOST_KEY_CHECKING`: Set to `False` to disable host key checking

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

- [Your Name] - [Your Website]
- GitHub: [@yourusername](https://github.com/yourusername)

## Acknowledgments

- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Documentation](https://docs.docker.com/)
