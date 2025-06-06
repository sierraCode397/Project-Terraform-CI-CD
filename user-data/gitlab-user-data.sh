#!/bin/bash

echo "Script started" >> /home/ec2-user/debug.log 

whoami >> /home/ec2-user/debug.log 

# Update system
dnf update -y 

echo "2" >> /home/ec2-user/debug.log 

# Install dependencies
yum install -y yum-utils

echo "3" >> /home/ec2-user/debug.log 

# Add Docker repository
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

echo "4" >> /home/ec2-user/debug.log 

# Install containerd manually (compatible with RHEL 9)
yum install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.6.33-3.1.el7.x86_64.rpm -y

echo "5" >> /home/ec2-user/debug.log 

# Install Docker
yum install -y docker-ce docker-ce-cli

echo "6" >> /home/ec2-user/debug.log 

# Start and enable Docker
systemctl enable docker
systemctl restart docker

echo "7" >> /home/ec2-user/debug.log 

# Create GitLab directory
mkdir -p /srv/gitlab/config /srv/gitlab/logs /srv/gitlab/data
chown -R $USER:$USER /srv/gitlab

echo "8" >> /home/ec2-user/debug.log 

# Create docker-compose.yml file for GitLab
cat <<EOF | tee /srv/gitlab/docker-compose.yml
services:
  gitlab:
    image: gitlab/gitlab-ce
    container_name: gitlab
    restart: always
    hostname: 'gitlab.isaac.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://localhost:80'
        gitlab_rails['gitlab_shell_ssh_port'] = 2424
        letsencrypt['enable'] = false

        puma['worker_processes']  = 0

        prometheus['enable']                     = false
        alertmanager['enable']                   = false
        node_exporter['enable']                  = false
        redis_exporter['enable']                 = false
        postgres_exporter['enable']              = false
        gitlab_exporter['enable']                = false                                                                                                                                          
                                                                                                                                        
        gitlab_rails['performance_bar_enabled']  = false
        gitlab_rails['enable_influxdb']          = false
    ports:
      - '80:80'    # HTTP port
      - '443:443'      # HTTPS port
      - '2424:22'      # SSH port
    volumes:
      - '/srv/gitlab/config:/etc/gitlab:z'
      - '/srv/gitlab/logs:/var/log/gitlab:z'
      - '/srv/gitlab/data:/var/opt/gitlab:z'
EOF

echo "9" >> /home/ec2-user/debug.log 

# Start GitLab container
(cd /srv/gitlab && docker compose up -d)

echo "10" >> /home/ec2-user/debug.log 

# Allow firewall access
dnf install firewalld -y

echo "11" >> /home/ec2-user/debug.log 

systemctl enable firewalld
systemctl start firewalld

echo "12" >> /home/ec2-user/debug.log 

firewall-cmd --add-port=80/tcp --permanent
firewall-cmd --add-port=22/tcp --permanent
firewall-cmd --add-port=443/tcp --permanent
firewall-cmd --add-port=2424/tcp --permanent
firewall-cmd --reload

echo "13" >> /home/ec2-user/debug.log 

echo "GitLab installation completed successfully!" >> /home/ec2-user/debug.log 
