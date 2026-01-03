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

git clone https://github.com/abhinandan-chougule/aws-3tier-infra-build.git

and

git clone https://github.com/abhinandan-chougule/spring-boot-petclinic-code.git

### 2. Parameters changes
```bash
I- Rename prod.tfvars.template to prod.tfvars and update parameters as mentioned in file
"If you have your own domain purchased then make sure you added it in route53 and created hosted zone to replicate real world scenario to access application from anywhere with https"

II- Create the "terraform-admin" credentials or use your own in providers.tf (refer the notes to create terraform-admin profile)

### 3. Run command in VSC to verify acccount if you are connected to AWS 
aws sts get-caller-identity --profile terraform-admin

### 4. Terraform, plan, apply and Destroy, use wisely
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
terraform destroy -var-file=prod.tfvars

### 5. # Copy JAR file to S3

Option A - Just copy/upload ready made "spring-petclinic.jar" from Infra repo to S3 

Option B - Build locally and as per README

As shown in the above clone the repo and build it using maven. Make sure AWS CLI installed in the bastion host Or you can copy from your local machine.

Build jar locally with
./mvnw -DskipTests package

If java is not installed then install it:
sudo apt install -y openjdk-25-jdk-headless ./mvnw -DskipTests package

Copy all files into one and upload into S3 as below
aws s3 cp target/spring-petclinic-*.jar s3://mypro-artifacts-prod/spring-petclinic.jar

### 6. Verify Apply completed or any error

### 7. Use Bastion to connnect RDS from AWS cosole
sudo su

mysql -h <rds-endpoint> -u <db-username> -p
Ex. mysql -h petclinic-prod-db.cj6xxxxxx0w.ap-southeast-1.rds.amazonaws.com -u appuser -p
(Password: ProdSecurePassword123!)

#Check Databse schema and existing entries, provided artifacts copied into S3 and available on EC2 instances

SHOW DATABASES;
USE petclinic;
SHOW TABLES;
SELECT * FROM owners LIMIT 50;

### 8. Try adding New Owner and again verify by using above commands in Databse


AWS will not allow duplicate S3 bucket globally
AWS will not allow same secrete names in secrete manager which are deleted within last 7 days

