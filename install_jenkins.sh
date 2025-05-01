#!/bin/bash

# ==============================================================================
# DevOps Environment Setup Script
# ==============================================================================
# Description: Automates the installation and configuration of a standard
#              DevOps toolset on a Red Hat-based Linux system (like Amazon Linux 2, CentOS, Fedora).
# Includes: Java, Jenkins, Maven, Git, Node.js, AWS CLI, Docker, kubectl, eksctl, OWASP ZAP.
# Usage: Run this script with sudo privileges or as root.
# ==============================================================================


set -euo pipefail  # Exit on error, undefined vars, and pipeline failures

# Versions as variables for easier maintenance
JAVA_VERSION="17"
ZAP_VERSION="2.14.0"
KUBECTL_VERSION="1.23.7"
JENKINS_PORT="8081"

# Function to log installation steps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        log "✓ $1 successful"
    else
        log "✗ $1 failed"
        exit 1
    fi
}

# Update system packages
log "Updating system packages..."
sudo yum update -y
sudo yum upgrade -y
check_status "System update"

# Install Java
log "Installing Java ${JAVA_VERSION}..."
sudo dnf install java-${JAVA_VERSION}-amazon-corretto-devel -y
sudo update-alternatives --set java /usr/lib/jvm/java-${JAVA_VERSION}-amazon-corretto.x86_64/bin/java
check_status "Java installation"

# Install Jenkins
log "Installing Jenkins..."
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install jenkins -y
sudo sed -i -e "s/Environment=\"JENKINS_PORT=[0-9]\+\"/Environment=\"JENKINS_PORT=${JENKINS_PORT}\"/" /usr/lib/systemd/system/jenkins.service
check_status "Jenkins installation"

# Install development tools
log "Installing development tools..."
sudo yum install -y git nodejs npm unzip jq
check_status "Development tools installation"

# Install and configure Docker
log "Installing Docker..."
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
sudo usermod -aG docker jenkins
sudo systemctl restart docker
check_status "Docker installation and configuration"

# Create a Docker test container to verify proper setup (optional)
log "Creating Docker test container..."
sudo docker run --name docker-test-container -d --restart always hello-world
check_status "Docker test container"

# Install Maven
log "Installing Maven..."
sudo wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
sudo sed -i s/\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo
sudo yum install -y apache-maven
check_status "Maven installation"

# Install AWS CLI
log "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip
check_status "AWS CLI installation"

# Install ZAP
log "Installing OWASP ZAP..."
sudo wget https://github.com/zaproxy/zaproxy/releases/download/v${ZAP_VERSION}/ZAP_${ZAP_VERSION//./_}_unix.sh
sudo chmod +x ZAP_${ZAP_VERSION//./_}_unix.sh
sudo ./ZAP_${ZAP_VERSION//./_}_unix.sh -q
rm ZAP_${ZAP_VERSION//./_}_unix.sh
check_status "ZAP installation"

# Install kubectl
log "Installing kubectl..."
curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/${KUBECTL_VERSION}/2022-06-29/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
sudo cp kubectl /usr/local/bin/
check_status "kubectl installation"

# Install eksctl
log "Installing eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
check_status "eksctl installation"

# Start and enable services
log "Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable --now docker
sudo systemctl enable --now jenkins

# Final status check
log "Checking service status..."
sudo systemctl status docker --no-pager
sudo systemctl status jenkins --no-pager

log "Installation script completed successfully!"
echo "NOTE: You may need to log out and log back in for Docker group changes to take effect for user '$USER'."