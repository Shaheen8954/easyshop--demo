#!/bin/bash

# Update system and install core packages
sudo apt update
sudo apt install -y fontconfig openjdk-17-jre 

# Jenkins installation
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get -y install jenkins

sudo systemctl start jenkins
sudo systemctl enable jenkins

# Docker installation
sudo apt-get update
sudo apt-get install docker.io -y

# User group permission
sudo usermod -aG docker $USER
sudo usermod -aG docker jenkins

sudo systemctl restart docker
sudo systemctl restart jenkins

# Install dependencies and Trivy
sudo apt-get install wget apt-transport-https gnupg lsb-release snapd -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install trivy -y

# AWS CLI installation
sudo snap install aws-cli --classic

# Helm installation
sudo snap install helm --classic

# Kubectl installation
sudo snap install kubectl --classic

# Exit on error
set -e

  # Update system packages
    info "Updating system packages..."
    sudo apt-get update -y
    sudo apt-get upgrade -y
    success "System packages updated"

    # Install required dependencies
    info "Installing required dependencies..."
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        unzip \
        jq \
        python3-pip \
        software-properties-common \
        git \
        make \
        build-essential \
        libssl-dev \
        libffi-dev \
        python3-dev
    success "Dependencies installed"

  # Install eksctl
    if ! command_exists eksctl; then
        info "Installing eksctl..."
        curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
        sudo mv /tmp/eksctl /usr/local/bin
        success "eksctl installed"
    else
        info "eksctl already installed"
    fi

   
    # Install kubectl-aws-auth
    if ! command_exists aws-iam-authenticator; then
        info "Installing kubectl-aws-auth..."
        curl -o kubectl-aws-auth https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.6.12/aws-iam-authenticator_0.6.12_linux_amd64
        chmod +x kubectl-aws-auth
        sudo mv kubectl-aws-auth /usr/local/bin/aws-iam-authenticator
        success "kubectl-aws-auth installed"
    else
        info "kubectl-aws-auth already installed"
    fi

    # Install ArgoCD CLI
    if ! command_exists argocd; then
        info "Installing ArgoCD CLI..."
        curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
        rm argocd-linux-amd64
        success "ArgoCD CLI installed"
    else
        info "ArgoCD CLI already installed"
    fi

    # Create .kube directory
    info "Setting up Kubernetes configuration directory..."
    mkdir -p ~/.kube
    sudo chown -R $(whoami):$(whoami) ~/.kube
    success "Kubernetes configuration directory setup complete"

    # Configure bash completion
    info "Configuring bash completion..."
    echo 'source <(kubectl completion bash)' >> ~/.bashrc
    echo 'source <(helm completion bash)' >> ~/.bashrc
    echo 'source <(eksctl completion bash)' >> ~/.bashrc
    echo 'source <(argocd completion bash)' >> ~/.bashrc
    success "Bash completion configured"

    # Verify installations
    info "Verifying installations..."
    echo -e "\n${CYAN}Installed Tools Versions${NC}"
    echo -e "${YELLOW}===========================================${NC}"
    echo -e "${BLUE}AWS CLI:${NC} ${GREEN}$(aws --version 2>&1)${NC}"
    echo -e "${BLUE}kubectl:${NC} ${GREEN}$(kubectl version --client --short 2>&1)${NC}"
    echo -e "${BLUE}eksctl:${NC} ${GREEN}$(eksctl version 2>&1)${NC}"
    echo -e "${BLUE}Helm:${NC} ${GREEN}$(helm version --short 2>&1)${NC}"
    echo -e "${BLUE}ArgoCD:${NC} ${GREEN}$(argocd version --client --short 2>&1)${NC}"
    echo -e "${YELLOW}===========================================${NC}"

# NGINX Ingress + Cert-Manager

# NGINX Installation

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
kubectl create namespace ingress-nginx

helm install nginx-ingress ingress-nginx/ingress-nginx   --namespace ingress-nginx   --set controller.service.type=LoadBalancer


# Cert-Manager Installation

helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace cert-manager

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.12.0 \
  --set installCRDs=true