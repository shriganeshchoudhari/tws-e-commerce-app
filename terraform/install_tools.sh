#!/bin/bash

# Redirect output to a log file for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting install_tools.sh..."

# Update system and install core packages
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg fontconfig openjdk-21-jdk[cite: 1]

# Jenkins installation - Improved GPG Key Handling
echo "Installing Jenkins..."
# Download the key and ensure it has correct permissions for the 'apt' user
sudo curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo gpg --dearmor --yes -o /usr/share/keyrings/jenkins-keyring.gpg
sudo chmod 644 /usr/share/keyrings/jenkins-keyring.gpg

# Create the source list with explicit reference to the keyring
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update[cite: 1]
if sudo apt-get -y install jenkins; then[cite: 1]
    echo "Jenkins installed successfully"
else
    echo "Jenkins installation failed!" >&2[cite: 1]
    # Do not exit yet; let's try to fix the key if it failed
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5BA31D57EF5975CA
    sudo apt-get update && sudo apt-get -y install jenkins
fi

sudo systemctl start jenkins
sudo systemctl enable jenkins

# Docker installation
echo "Installing Docker..."
sudo apt-get update[cite: 1]
sudo apt-get install docker.io -y

# User group permission
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins

# Apply changes without logout by restarting services
sudo systemctl restart docker
sudo systemctl restart jenkins

# Install Trivy - Improved for Ubuntu 24.04 (Noble)
echo "Installing Trivy..."
sudo apt-get install wget apt-transport-https gnupg lsb-release -y[cite: 1]
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor --yes -o /usr/share/keyrings/trivy.gpg
sudo chmod 644 /usr/share/keyrings/trivy.gpg

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt-get update -y[cite: 1]
sudo apt-get install trivy -y

# AWS CLI, Helm, Kubectl installation
echo "Installing AWS CLI, Helm, Kubectl..."
sudo snap install aws-cli --classic
sudo snap install helm --classic
sudo snap install kubectl --classic

echo "install_tools.sh finished successfully!"