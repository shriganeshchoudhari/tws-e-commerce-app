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
sudo curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo gpg --dearmor --yes -o /usr/share/keyrings/jenkins-keyring.gpg
sudo chmod 644 /usr/share/keyrings/jenkins-keyring.gpg

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
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins

sudo systemctl restart docker
sudo systemctl restart jenkins

# Install dependencies and Trivy
echo "Installing Trivy..."
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor --yes -o /usr/share/keyrings/trivy.gpg
sudo chmod 644 /usr/share/keyrings/trivy.gpg

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt-get update -y
sudo apt-get install trivy -y

# AWS CLI installation
echo "Installing AWS CLI, Helm, Kubectl..."
sudo snap install aws-cli --classic
sudo snap install helm --classic
sudo snap install kubectl --classic

echo "install_tools.sh finished successfully!"