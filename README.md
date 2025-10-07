# Terraform AWS 3-Tier Architecture

This project deploys a **secure 3-tier architecture on AWS** using **Terraform**.

It is designed as a learning and production-ready setup for modern cloud applications — built in phases for clarity and scalability.

---

## Project Overview

### Architecture Layers


```Internet
│
▼
[ Public Subnet ]
├─ EC2 (Web Server)
├─ NAT Gateway
│
▼
[ Private Subnet ]
├─ EC2 (App Server)
└─ RDS (PostgreSQL Database)
```


### Components
| Layer | AWS Resources |
|--------|----------------|
| **Networking** | VPC, Subnets, IGW, NAT, Route Tables |
| **Security** | Security Groups for Web, App, and DB |
| **Compute** | EC2 instances (Web + App) |
| **Database** | RDS (PostgreSQL) in private subnets |

---

## Current Infrastructure

This release includes:
- ✅ VPC with public & private subnets  
- ✅ Internet & NAT gateways with routing  
- ✅ Security groups for Web/App/DB layers  
- ✅ EC2 instances (Web & App)  
- ✅ RDS (PostgreSQL) database  

Upcoming:
- Validation & testing  
- Standardised code  
- CI/CD with GitHub Actions  
- Application deployment

---

## Prerequisites

- Terraform v1.5+  
- AWS CLI configured with credentials  
- An existing AWS key pair (`terraform-user-key-pair`)  

---

## Usage

### 1. Initialize Terraform
```bash
terraform init

2. Review planned resources
terraform plan

3. Apply configuration
terraform apply


Confirm with yes.

4. (Optional) Destroy resources
terraform destroy

Sensitive Info

Keep the following out of version control:

.tfstate files

terraform.tfvars

Private key (.pem) files

Example .gitignore included.