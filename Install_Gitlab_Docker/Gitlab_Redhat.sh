#!/bin/bash

set -e  # Exit on error

# Update system
sudo dnf update -y

# Install dependencies
sudo yum install -y yum-utils

# Add Docker repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install containerd manually (compatible with RHEL 9)
sudo yum install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.6.33-3.1.el7.x86_64.rpm -y

# Install Docker
sudo yum install -y docker-ce docker-ce-cli

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl restart docker

# Create GitLab directory
sudo mkdir -p /srv/gitlab/config /srv/gitlab/logs /srv/gitlab/data
sudo chown -R $USER:$USER /srv/gitlab

# Create docker-compose.yml file for GitLab
cat <<EOF | sudo tee /srv/gitlab/docker-compose.yml
services:
  gitlab:
    image: gitlab/gitlab-ce
    container_name: gitlab
    restart: always
    hostname: 'gitlab.isaac.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://3.230.127.31/'
        gitlab_rails['gitlab_shell_ssh_port'] = 2424
    ports:
      - '80:80'    # HTTP port
      - '443:443'  # HTTPS port
      - '2424:22'  # SSH port
    volumes:
      - '/srv/gitlab/config:/etc/gitlab'
      - '/srv/gitlab/logs:/var/log/gitlab'
      - '/srv/gitlab/data:/var/opt/gitlab'
EOF

# Start GitLab container
(cd /srv/gitlab && sudo docker compose up -d)


# Allow firewall access
sudo dnf install firewalld -y
sudo systemctl enable firewalld
sudo systemctl start firewalld

sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --add-port=22/tcp --permanent
sudo firewall-cmd --add-port=443/tcp --permanent
sudo firewall-cmd --add-port=2424/tcp --permanent
sudo firewall-cmd --reload

echo "GitLab installation completed successfully!"

