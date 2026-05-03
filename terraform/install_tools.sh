#!/bin/bash

# Redirect output to a log file for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting install_tools.sh..."

# Update system and install core packages
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y fontconfig openjdk-21-jre 

# Verify Java version
java -version

# Jenkins installation
echo "Installing Jenkins..."
sudo mkdir -p /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update
sudo apt-get install -y jenkins

sudo systemctl start jenkins
sudo systemctl enable jenkins

# Docker installation
echo "Installing Docker..."
sudo apt-get install docker.io -y
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins

# Install Trivy
echo "Installing Trivy..."
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor --yes -o /usr/share/keyrings/trivy.gpg
sudo chmod 644 /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y

# Snap-based tools
echo "Installing AWS CLI, Helm, Kubectl..."
sudo snap install aws-cli --classic
sudo snap install helm --classic
sudo snap install kubectl --classic

echo "install_tools.sh finished successfully!"