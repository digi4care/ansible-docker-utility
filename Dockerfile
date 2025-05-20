# Builder stage
FROM python:3.11-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install Python dependencies
COPY requirements.txt .
COPY entrypoint.sh .
RUN pip install --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
# Container runtime
containerd \
# SSH and Git
openssh-client \
sshpass \
git \
git-lfs \
# System utilities
gnupg \
rsync \
curl \
wget \
jq \
vim \
nano \
less \
unzip \
sudo \
# Podman
podman \
slirp4netns \
fuse-overlayfs \
# Clean up
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* \
/var/cache/apt/archives/* \
/tmp/*

# Install nerdctl from GitHub releases
RUN mkdir -p /tmp/nerdctl \
    && cd /tmp/nerdctl \
    && NERDCTL_VERSION=1.7.2 \
    && wget -q "https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz" \
    && tar Cxzvvf /usr/local nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz \
    && rm -rf /tmp/nerdctl

# Configure containerd for rootless mode
RUN mkdir -p /etc/containerd \
    && containerd config default > /etc/containerd/config.toml \
    && sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Configure non-root user
ARG USER=ansible
ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} ${USER} \
    && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USER} \
    && usermod -aG sudo ${USER} \
    && echo "${USER} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
    && chmod 0440 /etc/sudoers.d/${USER}

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set working directory and switch to non-root user
WORKDIR /ansible
USER ${USER}

# Copy entrypoint script
COPY --chown=${USER}:${USER} entrypoint.sh /usr/local/bin/entrypoint.sh

# Set environment variables
ENV CONTAINERD_NAMESPACE=default \
    CONTAINERD_SOCKET=/run/containerd/containerd.sock \
    CONTAINERD_ADDRESS=unix:///run/containerd/containerd.sock \
    # Ansible settings
    ANSIBLE_FORCE_COLOR=1 \
    ANSIBLE_HOST_KEY_CHECKING=False \
    ANSIBLE_SSH_RETRIES=3 \
    ANSIBLE_SSH_RETRY_DELAY=5 \
    # Python settings
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Set default command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
