#!/bin/bash
set -e

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Initialize SSH agent if not running
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)"
  trap 'eval $(ssh-agent -k)' EXIT
fi

# Add SSH keys if they exist
if [ -d "/home/ansible/.ssh" ]; then
  chmod 700 /home/ansible/.ssh
  chmod 600 /home/ansible/.ssh/* 2>/dev/null || true
  chmod 644 /home/ansible/.ssh/*.pub 2>/dev/null || true
  
  # Add all private keys
  while IFS= read -r -d '' key; do
    if ! ssh-add -l | grep -q "$(ssh-keygen -l -f "$key" | awk '{print $2}')"; then
      ssh-add "$key" 2>/dev/null || true
    fi
  done < <(find /home/ansible/.ssh -type f -name "id_*" ! -name "*.pub" -print0)
fi

# Start Docker daemon in the background if not running
if ! pgrep -f "dockerd" >/dev/null; then
  sudo -b dockerd >/var/log/docker.log 2>&1
  # Wait for Docker daemon to start
  while ! docker info >/dev/null 2>&1; do
    echo "Waiting for Docker daemon to start..."
    sleep 1
  done
fi

# Start Podman API service if podman is installed
if command_exists podman; then
  if ! pgrep -f "podman system service" >/dev/null; then
    podman system service --time=0 >/dev/null 2>&1 &
  fi
fi

# Execute the command
if [ "$1" = 'ansible-playbook' ] || [ "$1" = 'ansible' ] || [ "$1" = 'ansible-galaxy' ] || [ "$1" = 'ansible-vault' ] || [ "$1" = 'molecule' ]; then
  exec "$@"
else
  # If the command is not an Ansible command, execute it directly
  exec "$@"
fi
