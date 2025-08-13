#!/bin/bash

# Exit on error
set -e

# Colors for output (Hacker-style)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Fancy banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║      EasyShop Tool Installation         ║"
    echo "║        DevOps Tools Installer           ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Logging functions with timestamps
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ${1}${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  WARNING: ${1}${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ ERROR: ${1}${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  ${1}${NC}"
}

success() {
    echo -e "${WHITE}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ ${1}${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main installation function
main() {
    print_banner

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

    # Install AWS CLI
    if ! command_exists aws; then
        info "Installing AWS CLI..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
        success "AWS CLI installed"
    else
        info "AWS CLI already installed"
    fi

    # Install kubectl
    if ! command_exists kubectl; then
        info "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
        success "kubectl installed"
    else
        info "kubectl already installed"
    fi

    # Install eksctl
    if ! command_exists eksctl; then
        info "Installing eksctl..."
        curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
        sudo mv /tmp/eksctl /usr/local/bin
        success "eksctl installed"
    else
        info "eksctl already installed"
    fi

    # Install Helm
    if ! command_exists helm; then
        info "Installing Helm..."
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        ./get_helm.sh
        rm get_helm.sh
        success "Helm installed"
    else
        info "Helm already installed"
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

    # Create useful aliases
    info "Creating useful aliases..."
    cat >> ~/.bashrc << 'EOF'
# Kubernetes aliases
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kx='kubectl exec -it'
alias kl='kubectl logs'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'

# Helm aliases
alias h='helm'
alias hls='helm list'
alias hlsa='helm list -A'

# ArgoCD aliases
alias a='argocd'
alias ag='argocd app get'
alias as='argocd app sync'
EOF
    success "Aliases created"

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

    # Create welcome message
    info "Creating welcome message..."
    cat <<'EOTWELCOME' > ~/welcome.txt
=======================================================
Welcome to EasyShop DevOps Environment
=======================================================

Your environment is ready with the following tools:

1. Kubernetes Tools:
   - kubectl (for managing Kubernetes resources)
   - eksctl (for managing EKS clusters)
   - Helm (for package management)
   - ArgoCD CLI (for GitOps operations)

2. AWS Tools:
   - AWS CLI (for AWS operations)
   - aws-iam-authenticator (for EKS authentication)

Useful Aliases:
- k: kubectl
- kg: kubectl get
- kd: kubectl describe
- kl: kubectl logs
- h: helm
- a: argocd

To get started:
1. Run 'source ~/.bashrc' to load aliases
2. Use 'kubectl get nodes' to verify cluster connection
3. Run './deploy-applications.sh' to deploy applications

For more information about the deployment process,
check the documentation in the repository.

=======================================================
EOTWELCOME

    success "Tool installation completed successfully! 🚀"
    info "Please run 'source ~/.bashrc' to apply the changes to your current shell"
    info "Run './deploy-applications.sh' to deploy applications to your cluster"
}

# Run main function
main 

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