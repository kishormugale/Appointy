# Appointy: Highly Available, Fault-Tolerant Multi-Tier SaaS Infrastructure on AWS

A fully automated, production-grade cloud deployment architecture for **Appointy**, a multi-tier SaaS platform consisting of three application modules (User Frontend, Admin Panel, and a Node.js Backend API). 

The entire infrastructure is orchestrated using **AWS CloudFormation (Infrastructure as Code)** following modular, decoupled stack practices, and is continuously delivered via an automated **AWS CodePipeline CI/CD engine**.

![AWS Production Cloud Architecture](Architecture%20Diagram.jpeg)

---

## 🏗️ Architecture Highlights

The infrastructure partitions workloads cleanly across specialized layers to guarantee maximum performance, security isolation, and independent horizontal scaling:

* **Edge & Storage Layer:** Global static web hosting for the Frontend and Admin applications using **Amazon S3** buckets completely blocked from public access, exposed safely via **Amazon CloudFront** utilizing **Origin Access Control (OAC)**. Protected at the perimeter by **AWS WAF v2** with managed rulesets and rate limiting.
* **Routing & Compute Layer:** Public-facing **Application Load Balancer (ALB)** handling SSL termination via **AWS Certificate Manager (ACM)**. Traffic is forwarded securely to a dynamic **Auto Scaling Group (ASG)** of **Amazon EC2** instances running Amazon Linux 2023 inside isolated Private Application subnets.
* **Database Layer:** Highly available **Amazon DocumentDB (MongoDB-compatible)** cluster running with primary and replica instances deployed across multiple Availability Zones in segregated Private Database subnets. Data encryption is active at rest and in transit (TLS enforced).
* **CI/CD Pipeline:** A multi-stage **AWS CodePipeline** that hooks directly into GitHub via CodeStar connections, triggers multi-threaded parallel builds in **AWS CodeBuild** for all components, and manages zero-downtime, rolling (`OneAtATime`) blue-green-style deployments onto EC2 via **AWS CodeDeploy**.

---

## 🛠️ Infrastructure Stack Details (IaC Breakdown)

The infrastructure is broken into 8 modular CloudFormation nested stacks to prevent tight coupling and allow modular updates:

| Order | Stack Template | Core AWS Resources Provisioned | Purpose |
| :--- | :--- | :--- | :--- |
| **1** | `01-network.yaml` | VPC, 2x Public Subnets, 4x Private Subnets, IGW, 2x NAT Gateways, Route Tables | Establishes High-Availability Multi-AZ Base Network Topology. |
| **2** | `02-security.yaml` | IAM Roles, Instance Profiles, Security Groups (`ALB`, `App`, `DocDB`) | Enforces the Principle of Least Privilege and Network Firewalls. |
| **3** | `03-database.yaml` | DocDB Cluster, DocDB Instances, Secrets Manager Secrets | Configures secure, encrypted NoSQL storage & automated credential lifecycle management. |
| **4** | `04-storage.yaml` | S3 Buckets, CloudFront Distributions, OAC, WAFv2 WebACL | Configures edge CDN and global DDoS/Web Application filtering. |
| **5** | `05-compute.yaml` | Application Load Balancer, Target Groups, Launch Template, Auto Scaling Group | Controls dynamic request-routing and auto-scaling logic based on demand. |
| **6** | `06-monitoring.yaml` | CloudWatch Alarms, Metrics Dashboard, SNS Topic, Email Subscription | Provides real-time telemetry, failure detection, and engineer notification alerts. |
| **7** | `07-cicd.yaml` | CodePipeline, CodeBuild Projects, CodeDeploy Application & Deployment Groups | Fully automates continuous testing, compilation, and code shipment. |
| **8** | `08-dns.yaml` | Route 53 Record Sets (A-Alias Records) | Maps clean vanity subdomains (`app.*`, `admin.*`, `api.*`) to CloudFront/ALB. |

---

## 🔄 CI/CD & Deployment Lifecycle

The continuous integration pipeline automates building and rolling code packages securely:

1. **Source Hook:** CodePipeline triggers on a GitHub webhook connection whenever code is updated on the target branch.
2. **Parallel Build Environment:** CodeBuild provisions isolated micro-containers to process frontend assets and prepare backend configurations simultaneously.
3. **Deployment Lifecycle Hooks:** CodeDeploy handles in-place updates across the EC2 Auto Scaling fleet using customized automation scripts (`before-install.sh`, `after-install.sh`, `application-start.sh`, `validate-service.sh`).

### Automated Configuration Injection (`after-install.sh`)
During the deployment phase, rather than hardcoding credentials into version control, the **AWS CodeDeploy Agent** runs a specialized internal shell sequence:
1. Queries the EC2 instance metadata safely using secure **IMDSv2 tokens** to parse regional locality.
2. Communicates locally with **AWS Secrets Manager** using its assigned **IAM Instance Profile** role to extract active DocumentDB and Application keys dynamically.
3. Assembles a highly restricted local production environment file (`.env`, `chmod 600`) and pulls down AWS's trusted global X.509 bundle to establish TLS verified connections directly to DocumentDB.

---

## 🚀 How to Launch the Environment

### Prerequisites
1. An AWS Account with an active **Route 53 Hosted Zone** configured for your domain name (e.g., `appointy.com`).
2. An **ACM Certificate** provisioned in `us-east-1` (required for global CloudFront assignments).
3. A **CodeStar Connection** setup manually in your AWS console linkable to your GitHub repository profile.

### Execution Sequence
Deploy the stacks via the AWS CLI in sequential order, replacing the parameters with your verified environment configurations:

```bash
# 1. Establish Core Network Fabric
aws cloudformation create-stack \
  --stack-name appointy-network \
  --template-body file://aws-infrastructure/01-network.yaml \
  --parameters ParameterKey=EnvironmentName,ParameterValue=production

# 2. Build Security and Access Policy Infrastructure
aws cloudformation create-stack \
  --stack-name appointy-security \
  --template-body file://aws-infrastructure/02-security.yaml \
  --capabilities CAPABILITY_NAMED_IAM

# 3. Create Persistent Database Layers
aws cloudformation create-stack \
  --stack-name appointy-database \
  --template-body file://aws-infrastructure/03-database.yaml

# 4. Provision Storage & Front-end CloudFront CDN Edge Layers
aws cloudformation create-stack \
  --stack-name appointy-storage \
  --template-body file://aws-infrastructure/04-storage.yaml \
  --parameters ParameterKey=AcmCertificateArn,ParameterValue=arn:aws:acm:us-east-1:123456789012:certificate/abc-123 \
  --region us-east-1

# 5. Spin up Compute Resources, ALB and Auto-Scaling Elements
aws cloudformation create-stack \
  --stack-name appointy-compute \
  --template-body file://aws-infrastructure/05-compute.yaml \
  --parameters ParameterKey=DomainName,ParameterValue=appointy.com ParameterKey=HostedZoneId,ParameterValue=Z101234567890

# 6. Apply Monitoring & Operations Dashboards
aws cloudformation create-stack \
  --stack-name appointy-monitoring \
  --template-body file://aws-infrastructure/06-monitoring.yaml \
  --parameters ParameterKey=AlertEmail,ParameterValue=devops-alerts@appointy.com

# 7. Activate the CI/CD Pipeline Engine
aws cloudformation create-stack \
  --stack-name appointy-cicd \
  --template-body file://aws-infrastructure/07-cicd.yaml \
  --parameters ParameterKey=GitHubConnectionArn,ParameterValue=arn:aws:codestar-connections:us-east-1:123456789012:connection/xyz ParameterKey=GitHubOwner,ParameterValue=yourusername
