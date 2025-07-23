#!/bin/bash

# Redirect stdout and stderr to log
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
set -xe

echo "✅ Script started at $(date)"

# Install required tools
dnf -y install dnf-plugins-core curl || echo "dnf install failed"

# Add Docker CE repo
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo || echo "failed to add Docker repo"
dnf config-manager --set-enabled docker-ce-stable || echo "failed to enable Docker stable repo"

# Install Docker
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || echo "Docker installation failed"

# Start and enable Docker
systemctl start docker || echo "Docker service failed to start"
systemctl enable docker
usermod -aG docker ec2-user
echo 'newgrp docker' >> /home/ec2-user/.bashrc

# Resize root and /var volumes (LVM must exist)
growpart /dev/nvme0n1 4 || echo "growpart failed"
lvextend -L +20G /dev/RootVG/rootVol || echo "lvextend root failed"
lvextend -L +10G /dev/RootVG/varVol || echo "lvextend var failed"
xfs_growfs / || echo "xfs_growfs / failed"
xfs_growfs /var || echo "xfs_growfs /var failed"

# Install eksctl
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
install -m 0755 /tmp/eksctl /usr/local/bin && rm /tmp/eksctl

# Install kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.33.0/2025-05-01/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv kubectl /usr/local/bin/kubectl

# Verify installs
docker --version || echo "Docker not found in path"
eksctl version || echo "eksctl not installed"
kubectl version || echo "kubectl not installed"

echo "✅ Script completed at $(date)"
