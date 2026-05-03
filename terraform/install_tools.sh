#!/bin/bash

# Redirect output to a log file for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting install_tools.sh..."

# Update system and install core packages
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg fontconfig openjdk-21-jdk

# Jenkins installation
echo "Installing Jenkins..."
# Use curl and gpg --dearmor for better compatibility on Ubuntu 24.04
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update
if sudo apt-get -y install jenkins; then
    echo "Jenkins installed successfully"
else
    echo "Jenkins installation failed!" >&2
    exit 1
fi

sudo systemctl start jenkins
sudo systemctl enable jenkins

# Docker installation
echo "Installing Docker..."
sudo apt-get update
sudo apt-get install docker.io -y

# User group permission
# Use explicit 'ubuntu' user since $USER is 'root' in user_data
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins

sudo systemctl restart docker
sudo systemctl restart jenkins

# Install dependencies and Trivy
echo "Installing Trivy..."
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install trivy -y

# AWS CLI installation
echo "Installing AWS CLI, Helm, Kubectl..."
sudo snap install aws-cli --classic
sudo snap install helm --classic
sudo snap install kubectl --classic

echo "install_tools.sh finished successfully!"
