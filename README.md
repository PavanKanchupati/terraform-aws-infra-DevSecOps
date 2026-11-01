# AWS EKS Infrastructure with Terraform & Jenkins

> A modular Terraform project for provisioning a development AWS environment for Amazon EKS, with remote state management and a Jenkins pipeline for infrastructure delivery.

## Overview

This project defines the AWS infrastructure needed to run an Amazon EKS cluster in `ap-south-1`. It separates reusable infrastructure concerns into Terraform modules and composes them in the `dev` environment.

The goal is to make the EKS foundation repeatable: provision the network, IAM permissions, security groups, managed node group, EBS CSI integration, and Terraform remote state using version-controlled infrastructure-as-code.

## What it provisions

- A VPC with a `10.0.0.0/16` CIDR block
- Two public subnets in `ap-south-1a` and `ap-south-1b`, an internet gateway, and public routing
- An Amazon EKS cluster named `aws-jenkins-infra-cluster-dev`
- A managed EKS node group using `t3.medium` instances, scaled from 1 to 3 nodes (2 desired)
- IAM roles and AWS-managed policy attachments for the EKS control plane and worker nodes
- Cluster and node security groups
- An OIDC provider and IAM role for service-account-based access (IRSA) by the Amazon EBS CSI driver
- The AWS-managed `aws-ebs-csi-driver` EKS add-on
- An S3-backed Terraform state backend with DynamoDB locking, versioning, and AES-256 server-side encryption

## Architecture

```text
Jenkins pipeline
      |
      v
Terraform configuration (envs/dev)
      |
      +-- VPC module ──> VPC, public subnets, internet gateway, route table
      +-- IAM module ──> EKS cluster role and node role
      +-- Security groups module
      +-- EKS module ──> EKS cluster
      |                    |
      |                    +-- IAM-IRSA module ──> OIDC provider + EBS CSI role
      |                    +-- EKS add-ons module ─> Amazon EBS CSI driver
      +-- Node group module ─> managed worker nodes

Remote state: S3 bucket + DynamoDB lock table (backend-init)
```

## Repository layout

```text
.
├── backend-init/             # Bootstraps the S3 state bucket and DynamoDB lock table
├── envs/dev/                 # Development environment composition and backend config
├── modules/
│   ├── vpc/                  # VPC, public subnets, internet gateway, route table
│   ├── security-groups/      # Cluster and node security groups
│   ├── iam/                  # EKS control-plane and worker-node IAM roles
│   ├── eks/                  # EKS cluster
│   ├── iam-irsa/             # OIDC provider and EBS CSI service-account role
│   ├── eks-addons/           # AWS-managed EBS CSI add-on
│   ├── nodegroup/            # Managed EKS node group
│   └── ebs-storage/          # Optional Kubernetes gp3 StorageClass module
└── pipelines/jenkins/        # Jenkins pipeline definition
```

## Technologies

| Area | Tools and services |
| --- | --- |
| Infrastructure as code | Terraform |
| Cloud platform | AWS |
| Container orchestration | Amazon EKS / Kubernetes |
| Networking | Amazon VPC, subnets, internet gateway, route tables, security groups |
| Access management | AWS IAM and EKS OIDC/IRSA |
| Persistent storage integration | Amazon EBS CSI Driver and an optional gp3 StorageClass |
| State management | Amazon S3 and DynamoDB |
| Automation | Jenkins Declarative Pipeline |

## How it works

1. `backend-init/main.tf` creates the S3 bucket `kanchupati-pawan-terraform-state` and the DynamoDB table `terraform-lock-table` used by Terraform state.
2. `envs/dev/backend.tf` configures the development state path as `dev/terraform.tfstate` in that bucket.
3. `envs/dev/main.tf` connects the reusable modules and passes outputs between them: the VPC supplies subnets, IAM supplies role ARNs, EKS exposes its OIDC issuer, and that issuer is used to configure the EBS CSI IRSA role.
4. `pipelines/jenkins/Jenkinsfile` checks out the repository, writes the selected environment's `backend.tf`, initializes Terraform, generates and archives a plan, then applies that plan.

## Prerequisites

- An AWS account with permissions to create the resources in this repository
- Terraform installed (the project was inspected with Terraform `v1.14.3`)
- AWS credentials available to Terraform, for example through the AWS CLI credential chain
- An existing EC2 key pair named `DevSecOps`, or a different value supplied for `ssh_key_name`

> Creating EKS, EC2, VPC, S3, and DynamoDB resources can incur AWS charges. Review the Terraform plan before applying it.

## Deploy locally

### 1. Bootstrap remote state

Run this once before initializing the environment:

```bash
cd backend-init
terraform init
terraform plan
terraform apply
```

This configuration sets `force_destroy = true` on the state bucket. Treat any later destroy operation in this directory with particular care because it can delete bucket contents.

### 2. Initialize and deploy the development environment

```bash
cd ../envs/dev
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

To use a different EC2 key pair without editing source files:

```bash
terraform plan -var='ssh_key_name=your-key-pair-name'
```

## Jenkins pipeline

The pipeline at [`pipelines/jenkins/Jenkinsfile`](pipelines/jenkins/Jenkinsfile) expects a Jenkins credential with the ID `aws-creds`. It uses that credential as AWS access and secret keys and sets `AWS_DEFAULT_REGION` to `ap-south-1`.

Its stages are:

1. Checkout
2. Backend creation for `dev`
3. Dynamic `backend.tf` generation
4. Terraform initialization with state migration options
5. Format and validation commands
6. Terraform plan creation and `plan.txt` artifact archival
7. Manual approval stage
8. Terraform apply
9. Placeholder security-scan stage

## Configuration

The development configuration is intentionally small and currently exposes one input:

| Variable | Default | Purpose |
| --- | --- | --- |
| `ssh_key_name` | `DevSecOps` | Existing EC2 key pair attached to the EKS managed node group for remote access |

Key environment values, such as region, VPC CIDR, availability zones, cluster name, and node-group scale settings, are currently declared directly in [`envs/dev/main.tf`](envs/dev/main.tf).

## Verification and scripts

There are no automated test files or package-manager scripts in this repository. Terraform's built-in checks are the available local verification commands:

```bash
terraform fmt -check
terraform validate
terraform plan
```

The Jenkins pipeline performs the format and validation commands, produces a saved plan, and archives a readable `plan.txt`. Note that the pipeline currently continues even if formatting or validation fails because those commands use `|| true`.

## My contributions

Based on the repository history, I authored the infrastructure work on the development branch, including:

- Building the modular Terraform layout for VPC, EKS, IAM, IAM/IRSA, EKS add-ons, node groups, security groups, and EBS storage.
- Wiring module outputs together in the development environment to provision the cluster and its dependencies.
- Adding remote Terraform state support with an encrypted, versioned S3 bucket and DynamoDB state locking.
- Configuring IRSA for the Amazon EBS CSI controller service account and attaching the AWS-managed EBS CSI policy.
- Creating a parameterized Jenkins pipeline for Terraform initialization, planning, plan-artifact archival, approval, and apply operations.
- Refining the EKS add-on conflict configuration and security-group ingress configuration in subsequent commits.

## Current scope and limitations

- The checked-in environment directory is `envs/dev` only. Although Jenkins offers `dev`, `test`, `preprod`, `prod`, and `dr` choices, the other environment directories are not present in this branch; selecting them will not work without corresponding configurations.
- The pipeline approval condition runs when `ENV == 'dev'`, while its prompt says “APPLY to PRODUCTION.” This should be corrected before using it as an environment-protection control.
- The optional `ebs-storage` module and the Kubernetes provider block are currently commented out in `envs/dev/main.tf`, so this repository does not currently apply the custom gp3 StorageClass.
- The pipeline's security-scanning stage is a placeholder; it names Trivy, Gitleaks, and tfsec but does not execute them.
- Terraform/provider version constraints are not committed, so pinning them would improve reproducibility.

## License

No license file is included in this repository.
