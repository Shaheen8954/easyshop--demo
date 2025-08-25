# EasyShop Frontend
[![GitHub Profile](https://img.shields.io/badge/GitHub-iemafzalhassan-g?logo=github&style=flat)](https://github.com/iemafzalhassan)
![Docker Image](https://img.shields.io/github/forks/iemafzalhassan/easyshop--demo)
[![Stars](https://img.shields.io/github/stars/iemafzalhassan/easyshop--demo)](https://github.com/iemafzalhassan/easyshop--demo)
![GitHub last commit](https://img.shields.io/github/last-commit/iemafzalhassan/easyshop--demo?color=olive)

### **EasyShop 🛍️** is a modern, full-stack e-commerce platform built with Next.js 14, TypeScript, and MongoDB. It features a beautiful UI with Tailwind CSS, secure authentication, real-time cart updates, and a seamless shopping experience.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Infrastructure Setup](#infrastructure-setup)
4. [Jenkins Setup](#jenkins-setup)
5. [Continuous Deployment Setup (CD)](#continuous-deployment-setup)
6. [NGINX Ingress + Cert-Manager](#nginx-ngres-cert-manager)
7. [HTTPS Configuration](#https-configuration)

## Architecture Overview

EasyShop uses a GitOps approach with the following components:
- **Infrastructure as Code (IaC):** **Terraform** is used to provision and manage the cloud infrastructure.
- **Containerization:** **Docker** is used to containerize the application and its dependencies.
- **Container Registry:** **Docker Hub** is used as the container registry.
- **CI Pipeline:** **Jenkins** is used for continuous integration.
- **CD Pipeline:** **ArgoCD** is used for continuous delivery.
- **Kubernetes:** **Kubernetes** is used for container orchestration and management.
- **Monitoring:** **Prometheus** and **Grafana** are used for monitoring the application and infrastructure.

> [!IMPORTANT]  
> ## Prerequisites
> Before you begin, ensure you have the following prerequisites:
> - **AWS Account:** You need an AWS account/IAM role with appropriate permissions.
> - **Terraform:** Install Terraform on your local machine.
> - **AWS CLI:** Install the AWS Command Line Interface (CLI) on your local machine.

### **EasyShop** is a **full-stack e-commerce platform** built with:

-  **Next.js 14**
-  **TypeScript**
-  **MongoDB**
-  **Tailwind CSS** for UI
-  Secure Authentication
-  Real-time Cart Updates


---
Follow the steps below to get your infrastructure up and running using Terraform:

## 💻 Project Setup & Initialization

### Install & Initialize Terraform

> ```bash
> # Add HashiCorp repo & install
> curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
> sudo apt-add-repository "deb [arch=amd64] https://apt.releases. hashicorp.com $(lsb_release -cs) main"
> sudo apt-get update && sudo apt-get install terraform
> ```

 Verify:

> ```bash
> terraform -v
> ```

 Initialize:
> ```bash
> terraform init
> ```

Install & Configure AWS CLI

> ```bash
> curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
> sudo apt install unzip
> unzip awscliv2.zip
> sudo ./aws/install
> aws configure
> ```

 Provide:
- **AWS Access Key ID**
- **AWS Secret Access Key**
- **Default region name**
- **Output format**

> [!NOTE]  
> Ensure your IAM role has programmatic access and required permissions.


---

##  Getting Started with Terraform

### Clone the Repository

> ```bash
> git clone https://github.com/iemafzalhassan/easyshop--demo.git
> cd terraform
> ```

###  Generate SSH Key

> ```bash
> ssh-keygen -f bastion_key
> chmod 400 bastion_key
> ```

###  Infrastructure Setup

> ```bash
> terraform init
> terraform plan
> terraform apply
> ```

>  Confirm with `yes`

###  SSH into EC2

> ```bash
> ssh -i bastion_key ubuntu@<public-ip>
> ```

###  Update Kubeconfig

> ```bash
> aws eks --region eu-west-1 update-kubeconfig --name easyshop-cluster
> kubectl get nodes
> ```

---

##  Jenkins Setup

```bash
cd /modules/bastion
./install-tools.sh
./deploy-applications.sh
```

###  Check Jenkins Status

> ```bash
> sudo systemctl status jenkins
> ```

###  Get Initial Admin Password

> ```bash
> sudo cat /var/lib/jenkins/secrets/initialAdminPassword
> ```

###  Start Jenkins (If not running)

> ```bash
> sudo systemctl enable jenkins
> sudo systemctl restart jenkins
> ```

###  Install Plugins
> Navigate to: **Manage Jenkins → Plugins → Available Plugins**

Install:
- `Docker Pipeline`
- `Pipeline View`

### GitHub Credentials:

> Jenkins → Manage Jenkins → Credentials → Global → Add Credentials
- **Kind:** Username with password
- **ID:** `github-credentials`

### DockerHub Credentials:
> Same path as above
- **Kind:** Username with password
- **ID:** `docker-hub-credentials`

### Add Shared Library

> Manage Jenkins → Configure System → Global Pipeline Libraries

- **Name:** `shared`
- **Version:** `main`
- **Repo URL:** `https://github.com/iemafzalhassan/EasyShop-jenkins-shared-lib`

>  Ensure repo has: `vars/` directory.

- **Name:** `EasyShop-jenkins-shared-lib`

### Triggers
- GitHub hook trigger for GITScm polling

### Pipeline Config
- Definition: `Pipeline script from SCM`
- SCM: `Git`
- Branch: `master`
- Script Path: `Jenkinsfile`

---

##  Continuous Deployment Setup (CD)

---

##  Argo CD Setup

### run script to automate setup
```bash
./easyshop-deployment.sh
```
> or:

###  Install Argo CD
> ```bash
> kubectl create namespace argocd
> kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
> ```

###  Monitor Pods
> ```bash
> watch kubectl get pods -n argocd
> ```

###  Expose Argo CD

> ```bash
> kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
> kubectl port-forward svc/argocd-server -n argocd 9090:443 --address=0.0.0.0 &
> ```

>  Get admin password:
> ```bash
> kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
> ```

---

### NGINX Ingress + Cert-Manager

####  NGINX Installation

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
kubectl create namespace ingress-nginx

helm install nginx-ingress ingress-nginx/ingress-nginx   --namespace ingress-nginx   --set controller.service.type=LoadBalancer
```

###  Cert-Manager Setup

> ```bash
> helm repo add jetstack https://charts.jetstack.io
> helm repo update
>
> helm install cert-manager jetstack/cert-manager   --namespace cert-manager   --create-namespace   --version v1.12.0   --set installCRDs=true
```

---

##  HTTPS Configuration

####  `04-configmap.yaml`

> ```yaml
> NEXT_PUBLIC_API_URL: "https://easyshop.letsdeployit.com/api"
> NEXTAUTH_URL: "https://easyshop.letsdeployit.com/"
> ```

####  `10-ingress.yaml`

> ```yaml
> annotations:
>   cert-manager.io/cluster-issuer: "letsencrypt-prod"
>   nginx.ingress.kubernetes.io/ssl-redirect: "true"
> ```

 `Apply Changes:`

> ```bash
> kubectl apply -f 00-cluster-issuer.yaml
> kubectl apply -f 04-configmap.yaml
> kubectl apply -f 10-ingress.yaml
> ```

 `Check Status:`
> ```bash
> kubectl get certificate -n easyshop
> kubectl describe certificate easyshop-tls -n easyshop
> ```

---

##  **Congratulations! Deployment Complete!**

>  Your full-stack e-commerce project is now deployed and live!
