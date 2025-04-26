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

# Create Dockerfile file for Jenkins
cat <<EOF | sudo tee /home/ubuntu/Dockerfile
# Dockerfile
FROM jenkins/jenkins:lts-jdk17

USER root
RUN apt-get update \
 && apt-get install -y wget unzip openssh-client \
 && wget https://releases.hashicorp.com/terraform/1.7.2/terraform_1.7.2_linux_amd64.zip \
 && unzip terraform_1.7.2_linux_amd64.zip -d /usr/local/bin \
 && rm terraform_1.7.2_linux_amd64.zip \
 && curl -sL https://aka.ms/InstallAzureCLIDeb | bash

USER jenkins

EOF

# Create docker-compose.yml file for Jenkins
cat <<EOF | sudo tee /home/ubuntu/docker-compose.yml
services:
  jenkins:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: jenkins
    user: root
    ports:
      - '8080:8080'
    volumes:
      - jenkins-vol:/var/jenkins_home

volumes:
  jenkins-vol:
    driver: local
EOF

# Start Jenkins container
(cd /home/ubuntu/ && sudo docker compose up -d)

# Allow firewall access
sudo ufw allow 8080/tcp
sudo ufw allow 50000/tcp
sudo ufw allow 22/tcp

echo "Waiting for GitLab to generate initial password..."
sleep 20

echo "Jenkins installation completed successfully!"

sudo docker exec -it jenkins bash -c 'cat "${JENKINS_HOME:-/var/jenkins_home}"/secrets/initialAdminPassword'

