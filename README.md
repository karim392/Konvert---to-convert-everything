# Konvert (to convert every thing)


This project demonstrates a complete **end-to-end DevOps workflow**

---

## 🧩 Project Architecture

- **Node.js Web Application**
- **Docker** for containerization
- **Docker Hub** to store application images
- **Terraform** for AWS infrastructure provisioning
- **Ansible** for EC2 configuration
- **GitHub Actions** for CI/CD
- **AWS** For infrastructure
- **Git** for versioning control

## 📂 Repository Structure





---

🐳 **Docker**

- The Node.js application is packaged into a Docker image.
- The image is automatically built and pushed to Docker Hub.

**Docker Image**

karimrushdy/konvert_to_convert

---

☁️ **Infrastructure (Terraform)**

Terraform provisions the full AWS infrastructure including:

- VPC and 4 Subnets (2 public subnets for application and 2 private subnets for DB and Replica)
- Internet Gateway and Route Tables
- Security Groups
- EC2 instances
- Application Load Balancer
- WAF
- Route 53
- RDS and Replica

note: Enbed a Bash script to extract the EC2 public IP in temp inventory and use it to run the ansbil playbook



                     ┌───────────────────────────┐
                     │         End Users          │
                     └──────────────┬────────────┘
                                    │
                           Internet │
                                    ▼
                     ┌───────────────────────────┐
                     │   AWS Route 53 (DNS)       │
                     └──────────────┬────────────┘
                                    │
                                    ▼
                     ┌───────────────────────────┐
                     │  AWS WAF (Web Firewall)    │
                     └──────────────┬────────────┘
                                    │
                                    ▼
                     ┌───────────────────────────┐
                     │ Application Load Balancer  │
                     │        (Public)            │
                     └──────────────┬────────────┘
                                    │
                           HTTP/HTTPS│
                                    ▼
                     ┌───────────────────────────┐
                     │   EC2 Application Tier     │
                     │      (Public Subnets)      │
                     └──────────────┬────────────┘
                                    │
                           MySQL 3306│
                                    ▼
                     ┌───────────────────────────┐
                     │     RDS MySQL Database     │
                     │     (Private Subnets)      │
                     └──────────────┬────────────┘
                                    │
                           Replication│
                                    ▼
                     ┌───────────────────────────┐
                     │   RDS Read Replica         │
                     │   (Private Subnets)        │
                     └───────────────────────────┘



# Terraform Commands

- terraform init
- terraform plan
- terraform apply

---

⚙️ **Configuration Management (Ansible)**

Ansible is used to configure the EC2 instances after creation:

- Install Docker

- Start Docker service

- Pull the Docker image from Docker Hub

- Run the Node.js container


Run Ansible

ansible-playbook -i temp_inventory playbook.yml

---

🔄 **CI/CD Pipeline (GitHub Actions)**

The CI/CD pipeline runs automatically on every push to the main branch.

Pipeline Stages

1- Code Checkout

2- Install Dependencies

3- Run Tests

4- Build Docker Image

5- Push Image to Docker Hub

6- Provision Infrastructure using Terraform

7- Configure EC2 using Ansible

8- Deploy Application

**Trigger**
on:
  push:
    branches:
      - main

---


🔐 **Secrets Management**

The following secrets are stored securely in GitHub Actions Secrets:

DOCKERHUB_USERNAME

DOCKERHUB_PASSWORD

SSH_PRIVATE_KEY

---

📌 **How to Access the App**

After deployment, access the application via:

http://**Load balancer DNS**




