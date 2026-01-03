# 🏗️ Production Infrastructure with Terraform + AWS

## 📌 Overview
This repository contains Terraform code to provision a **production‑ready infrastructure** on AWS.  
It automates networking, compute, monitoring, and application deployment — ensuring scalability, security, and maintainability.

### Key Features
- **Infrastructure as Code** with Terraform
- **Auto Scaling Group (ASG)** for EC2 instances
- **Application Load Balancer (ALB)** in public subnets
- **Internet Gateway (IGW)** for internet access
- **RDS schema bootstrap** (`petclinic` database + privileges)
- **Artifact download from S3** (Spring Boot JAR)
- **CloudWatch monitoring & SNS alerts** (CPU ≥ 60%, unhealthy hosts)

---

## ⚙️ Modules

| Module        | Purpose                                      |
|---------------|----------------------------------------------|
| **vpc**       | Creates VPC, subnets, and networking         |
| **ig**        | Internet Gateway + public route tables       |
| **alb**       | Application Load Balancer + Target Groups    |
| **asg**       | Auto Scaling Group + Launch Template for EC2 |
| **monitoring**| CloudWatch alarms + SNS topic/subscription   |

---

## 🚀 Usage

### 1. Clone the repo
```bash
git clone https://github.com/your-org/your-repo.git
cd your-repo
