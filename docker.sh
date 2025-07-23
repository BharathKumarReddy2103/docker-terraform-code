#!/bin/bash

# Log to file
exec > /var/log/user-data.log 2>&1
set -xe

# Install required tools
dnf -y install dnf-plugins-core curl

# Add Docker CE repo
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
dnf config-manager --set-enabled docker-ce-stable

# Install Docker
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user
echo 'newgrp docker' >> /home/ec2-user/.bashrc

growpart /dev/nvme0n1 4
lvextend -L +20G /dev/RootVG/rootVol
lvextend -L +10G /dev/RootVG/varVol

xfs_growfs /
xfs_growfs /var

ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
install -m 0755 /tmp/eksctl /usr/local/bin && rm /tmp/eksctl

curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.33.0/2025-05-01/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv kubectl /usr/local/bin/kubectl

eksctl version
kubectl version