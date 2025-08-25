#!/bin/bash

# Exit on error - set this early
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Define missing functions
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  ${1}${NC}"
}

success() {
    echo -e "${WHITE}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ ${1}${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  WARNING: ${1}${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ ERROR: ${1}${NC}"
}

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ${1}${NC}"
}

# Fancy banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║       EasyShop Bastion Setup             ║"
    echo "║        DevOps Tools Installation         ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to install eksctl with proper error handling
install_eksctl() {
    if ! command_exists eksctl; then
        info "Installing eksctl..."
        
        # Download and extract eksctl
        if curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp; then
            # Verify the binary was extracted
            if [ -f "/tmp/eksctl" ]; then
                sudo mv /tmp/eksctl /usr/local/bin/
                sudo chmod +x /usr/local/bin/eksctl
                success "eksctl installed successfully"
            else
                error "Failed to extract eksctl binary"
                return 1
            fi
        else
            error "Failed to download eksctl"
            return 1
        fi
    else
        info "eksctl already installed"
    fi
}



# Function to install ArgoCD CLI
install_argocd() {
    if ! command_exists argocd; then
        info "Installing ArgoCD CLI..."
        
        if curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64; then
            sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
            rm argocd-linux-amd64
            success "ArgoCD CLI installed successfully"
        else
            error "Failed to download ArgoCD CLI"
            return 1
        fi
    else
        info "ArgoCD CLI already installed"
    fi
}

# Main installation function
main() {
    print_banner
    
    log "Starting EasyShop bastion host setup..."

    # Update system and install core packages
    info "Updating system packages..."
    sudo apt update
    sudo apt install -y fontconfig openjdk-17-jre 
    success "Core packages installed"

    # Jenkins installation
    info "Installing Jenkins..."
    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
      https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
      https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get -y install jenkins

    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    success "Jenkins installed and started"

    # Docker installation
    info "Installing Docker..."
    sudo apt-get update
    sudo apt-get install docker.io -y

    # User group permission
    sudo usermod -aG docker $USER
    sudo usermod -aG docker jenkins

    sudo systemctl restart docker
    sudo systemctl restart jenkins
    success "Docker installed and configured"

    # Install dependencies and Trivy
    info "Installing Trivy and dependencies..."
    sudo apt-get install wget apt-transport-https gnupg lsb-release snapd -y
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
    echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
    sudo apt-get update -y
    sudo apt-get install trivy -y
    success "Trivy installed"

    # AWS CLI installation
    info "Installing AWS CLI..."
    sudo snap install aws-cli --classic
    success "AWS CLI installed"

    # Helm installation
    info "Installing Helm..."
    sudo snap install helm --classic
    success "Helm installed"

    # Kubectl installation
    info "Installing kubectl..."
    sudo snap install kubectl --classic
    success "kubectl installed"

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
    install_eksctl

    # Install ArgoCD CLI
    install_argocd

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



    success "EasyShop bastion host setup completed successfully! 🚀"
    
    info "Access Information:"
    echo -e "${CYAN}Jenkins:${NC} http://$(curl -s ifconfig.me):8080"
    echo -e "${CYAN}Docker:${NC} Available for container operations"
    echo -e "${CYAN}Kubernetes Tools:${NC} kubectl, helm, eksctl, argocd CLI ready"
    echo -e "${CYAN}Security:${NC} Trivy vulnerability scanner installed"
    echo -e "${CYAN}Next Steps:${NC} Use these tools to deploy ArgoCD, NGINX, and Cert-Manager to your EKS cluster"
}

# Run main function
main
