#!/bin/bash

set -e  # Exit on error

# Update system
sudo apt-get update

# Install dependencies
sudo apt-get install -y ca-certificates curl

# Create keyrings directory if not exists
sudo install -m 0755 -d /etc/apt/keyrings

# Add Docker's official GPG key
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt-get update

# List available Docker versions
apt-cache madison docker-ce | awk '{ print $3 }'

# Install specific Docker version
VERSION_STRING=5:28.0.1-1~ubuntu.24.04~noble
sudo apt-get install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl enable docker
sudo systemctl restart docker

# Create GitLab directory
sudo mkdir -p /srv/gitlab

# Create docker-compose.yml file for GitLab
cat <<EOF | sudo tee /srv/gitlab/docker-compose.yml
version: '3.6'
services:
  gitlab:
    image: gitlab/gitlab-ee:latest
    container_name: gitlab
    restart: always
    hostname: 'gitlab.example.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.example.com:8929'
        gitlab_rails['gitlab_shell_ssh_port'] = 2424
    ports:
      - '8929:8929'
      - '443:443'
      - '2424:22'
    volumes:
      - '/srv/gitlab/config:/etc/gitlab'
      - '/srv/gitlab/logs:/var/log/gitlab'
      - '/srv/gitlab/data:/var/opt/gitlab'
    shm_size: '256m'
EOF

# Start GitLab container
cd /srv/gitlab
sudo docker compose up -d

# Allow firewall access
sudo ufw allow 8929/tcp
sudo ufw allow 443/tcp
sudo ufw allow 2424/tcp

echo "GitLab installation completed successfully!"
