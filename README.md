# DevOps CI/CD Infrastructure-as-Code Project for Cloud Security Automation

This solution is built on two dedicated Git repositories—**Project_Terraform_CI-CD** and **Analytics-Rules**—that together enable fully automated, end-to-end security enforcement across your cloud environments.  

## 1. Purpose & Scope

This repository implements a multi‑cloud, Infrastructure‑as‑Code solution to provision and deploy security and monitoring resources in Azure (Resource groups, Log Analytics workspaces, Sentinel solutions, Analitycs rules) via a CI/CD pipeline running on AWS. It centralizes:

- Terraform modules for AWS network, compute, Docker, and CI/CD infrastructure
- Terraform modules for Azure security and monitoring resources
- Gitlab Repository (hosted on AWS EC2) for multi colaborating environment
- Jenkins pipelines (hosted on AWS EC2) for cross‑cloud orchestration

### This project `Project_Terraform_CI-CD` created the follow:

![AWS Academy Cloud Architecting](https://imgur.com/hRLAU57.png)

**Primary users**

- DevOps Engineers (authoring/integrating IaC modules)
- SREs (on‑call support for pipeline and infra)
- Security Teams (reviewing Sentinel configurations)
- Non‑technical stakeholders (audit logs from Sentinel)

**Ecosystem context**

- **AWS account** runs Jenkins master on EC2 inside a VPC to relay code changes
- **Azure subscription** where Terraform provisions security and monitoring Analytics rules
- **Git repository** hosted on a second EC2 instance running GitLab CE inside a Docker container (source for IaC modules and pipelines)

---

## 2. Prerequisites & Setup

**Tools & versions**

- **Terraform (host)**: v1.11.4 (linux\_amd64)
- **AWS Terraform Provider**: hashicorp/aws ≥ 5.92
- **Docker CE**: 5:27.2.0~
- **docker-buildx-plugin**, **docker-compose-plugin**
- **Jenkins**: jenkins/jenkins\:lts-jdk17
- **GitLab CE**: gitlab/gitlab-ce (via docker-compose.yml)

**Environment variables & credentials**

```bash
# AWS, to join to your account
export AWS_ACCESS_KEY_ID=…
export AWS_SECRET_ACCESS_KEY=…
export AWS_DEFAULT_REGION=us-east-1

# Azure, these values in your Key vault as secrets with this names 

  - ARM-CLIENT-ID: Client_id
  - ARM-CLIENT-SECRET: Client_secret
  - ARM-SUBSCRIPTION-ID: SUBSCRIPTION_ID
  - ARM-TENANT-ID: Tenant_id
```

**Getting started with Terraform**

1. **Initialize AWS modules**
   ```bash
   cd Project_Terraform_CI-CD/
   terraform init
   ```
2. **Proceed** with AWS provisioning 
   ```bash
   cd Project_Terraform_CI-CD/
   terraform plan
   terraform apply
   ```

### Azure Prerequisites

Before running the Azure Terraform code `Analytics-Rules`, which you should upload to the gitlab repo in your instances EC2 when it are ready, ensure you have:

- A personal Azure account (tenant)
- A subscription with the following pre-configured and permissions granted:
  - **Storage account** for Terraform state backend
  - **Container** inside the storage account for state files
  - **Key Vault** for secret management
  - Ability to **create and delete** resource groups
  - **Microsoft Entra ID** (Azure AD) tenant
  - **App registration** to create a service principal
  - Give rights to the service principal to **assign and remove** role assignments
  - **Microsoft Sentinel** enabled on the Log Analytics workspace
  - Service principal credentials **stored as secrets** in Key Vault

---

## 3. Architecture & Design

**High-level diagram**

![AWS Academy Cloud Architecting](https://imgur.com/Fn3REB3.png)

**Directory & module structure**

````text
├── locals.tf
├── main.tf
├── modules
│   └── ec2
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── outputs.tf
├── README.md
├── user-data
│   ├── gitlab-user-data.sh
│   └── jenkins-user-data.sh
└── versions.tf
````

**Core components**

| Component                | Responsibility                                                | Interactions                              |
| ------------------------ | ------------------------------------------------------------- | ----------------------------------------- |
| **AWS VPC**              | Network isolation (public subnets, NACL, IGW)                 | EC2                            |
| **Security Groups**      | Allow Jenkins (port 8080), Gitlab (port 22, 2424)               | EC2 instances                             |
| **EC2 (Jenkins)**        | Runs CI/CD orchestration                                      | Terraform, GitLab CE Container            |
| **EC2 (GitLab CE)**      | Hosts the Git repository & Dockerized GitLab services         | Git clients, CI pipelines                  |
| **Terraform**      | Provisions AWS infra (network + compute)                      | AWS API                                   |
| **Azure Resource Groups** | Container for all Azure resources                             | Key Vault, Storage Account, Log Analytics workspace, storage account, service principal |
| **Azure Sentinel**       | Central threat management dashboard                           | Log Analytics, Solutions                  |       | Central threat management dashboard                           | Log Analytics, Solutions                  |

---

## 4. Usage & Examples

**Root AWS provisioning**

Use the top-level `main.tf` to bootstrap core AWS infrastructure (VPC, subnets, SGs, IGW, EC2):

```bash
terraform init
terraform plan
terraform apply 
```

**Jenkins pipeline (jenkins/Jenkinsfile)**

````groovy
pipeline {
  agent any
  environment { TF_IN_AUTOMATION = 'true' }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Debug Workspace') {
      steps {
        sh '''
          echo "Current directory:"
          pwd
          echo "Files in workspace:"
          ls -R .
        '''
      }
    }

    stage('Terraform Init → Plan → Apply') {
      steps {
        withCredentials([
          string(credentialsId: 'ARM-CLIENT-ID',       variable: 'ARM_CLIENT_ID'),
          string(credentialsId: 'ARM-CLIENT-SECRET',   variable: 'ARM_CLIENT_SECRET'),
          string(credentialsId: 'ARM-TENANT-ID',       variable: 'ARM_TENANT_ID'),
          string(credentialsId: 'ARM-SUBSCRIPTION-ID', variable: 'ARM_SUBSCRIPTION_ID')
        ]) {
          sh '''
            set -eux

            # If Terraform is in a subfolder, change to it
            if [ -d "terraform" ]; then cd terraform; fi


            # (Optional) Azure CLI login if you need 'az' elsewhere:
            # az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
            # az account set --subscription "$ARM_SUBSCRIPTION_ID"

            # Terraform will pick up the ARM_* vars automatically
            terraform init -input=false -reconfigure -backend-config="subscription_id=$ARM_SUBSCRIPTION_ID"


            terraform plan -input=false -out=tfplan.binary

            # apply after manual approval
            terraform apply -input=false -auto-approve tfplan.binary
          '''
        }
      }
    }
  }

  post {
    always {
      sh 'az logout || true'
    }
  }
}

````

---

## 5. Configuration & Customization

**Terraform variables**

| Name                   | Description                 | Default                           |
| ---------------------- | --------------------------- | --------------------------------- |
| aws\_region            | AWS region for VPC & EC2    | us-east-1                         |
| vpc\_cidr              | CIDR block for VPC          | 172.16.0.0/16                     |

**Secrets management**

- **Azure**: Store service principal secret in Azure Key Vault

---

## 6. CI/CD Integration

**Jenkins pipeline stages**

1. Checkout source code
2. Debug Workspace
3. Terraform Init 
4. Terraform Plan 
5. Terraform apply

**Credential & approvals**

- Jenkins instance profile for AWS actions
- Azure service principal stored in Key Vault
- GitHub branch protection + manual approval in Jenkins for prod

**Rollback procedures**

```bash
cd Project_Terraform_CI-CD/ && terraform destroy
```

---

## 7. Troubleshooting & FAQs

| Error message                 | Potential cause                       | Resolution                                         |
| ----------------------------- | ------------------------------------- | -------------------------------------------------- |
| AccessDenied (NACL blocked)   | Network ACL or SG denies traffic      | Adjust NACL inbound rules or SG ports              |
| Authentication failed (Azure) | Invalid service principal credentials | Verify AZURE\_CLIENT\_SECRET and Key Vault mapping |
| ResourceAlreadyExists         | Azure resource with same name exists  | Rename or remove existing resource                 |

**Logs & state files**

- Terraform state: remote backend (S3 for AWS, Azure Storage for Azure)
- Jenkins logs: Jenkins → Job → Console Output

---

## 8. Contribution & Maintenance

**Branching strategy**

- main (production)
- develop (integration)

**Issue & PR workflow**

1. Open an issue with description & labels
2. Create a feature branch
3. Submit PR against develop
4. Automated lint/tests + peer review
5. Merge to develop, then merge to main via release PR

---

## 9. Change Log & Versioning

- v1.0.0 (2025-04-01): MVP—multi‑cloud IaC + Jenkins pipeline
- v1.1.0 (2025-04-15): Added  integration
- v1.2.0 (2025-05-01): Enhanced Sentinel solutions

> We follow Semantic Versioning ([https://semver.org/](https://semver.org/)) for all releases.

---

## 10. References & Further Reading

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/index.html)
- [Azure CLI Docs](https://learn.microsoft.com/cli/azure)
- [Jenkins Documentation](https://www.jenkins.io/doc/)

