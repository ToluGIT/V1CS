# V1CS - Trend Vision One Container Security Demo

> **[Complete Walkthrough Guide](containersecurity-walk%20through.md)** - Start here for the full step-by-step experience

A comprehensive demonstration environment for Trend Vision One Container Security on AWS EKS, including infrastructure deployment, security policy configuration, runtime protection, and CI/CD integration with Trend Micro Artifact Scanner (TMAS).

## What You'll Learn

- **Infrastructure as Code** - Deploy secure EKS clusters with Terraform
- **Container Security Policies** - Configure deployment, continuous, and runtime protection
- **Threat Detection** - Simulate attacks and analyze security events with MITRE ATT&CK mapping
- **XDR Investigation** - Leverage Trend Vision One for comprehensive threat hunting
- **CI/CD Security** - Integrate TMAS for automated container image scanning
- **DevSecOps** - Implement security gates in deployment pipelines

## Prerequisites

- **AWS Account** - Administrative permissions for EKS deployment in us-east-1 region
- **Trend Vision One Account** - Container Security module enabled
- **GitHub Account** - For CI/CD pipeline demonstrations with TMAS
- **Local Tools**: Terraform, AWS CLI, Git

## Quick Start

```bash
# 1. Clone and prepare
git clone https://github.com/ToluGIT/V1CS.git
cd V1CS

# 2. Configure AWS CLI
aws configure

# 3. Set up Terraform backend (see walkthrough for details)
aws s3api create-bucket --bucket your-terraform-state-bucket --region us-east-1

# 4. Deploy infrastructure
cd terraform/
terraform init
terraform plan  
terraform apply -auto-approve

# 5. Follow the complete walkthrough for Vision One setup
```



```
V1CS/
├── terraform/                           # AWS EKS infrastructure
├── scripts/
│   ├── deploy_v1cs.sh                  # Container Security deployment automation
│   ├── attack_v1cs.sh                  # Attack simulation scenarios
│   └── install_tmas_cli.sh             # TMAS CLI installation
├── .github/workflows/
│   ├── imgcreate-push.yaml             # CI pipeline with TMAS scanning
│   └── prod-deploy.yaml               # CD pipeline to EKS
├── images/                             # Documentation screenshots
├── containersecurity-walk through.md   # Complete step-by-step guide
└── README.md                          # This file
```

## Documentation

### [Complete Walkthrough](containersecurity-walk%20through.md)
**Start here for the full experience** - Detailed step-by-step guide covering:

1. **AWS EKS Deployment** - Terraform infrastructure setup
2. **Vision One Configuration** - Security policies and rulesets  
3. **Container Security Deployment** - Automated installation on EKS
4. **Attack Simulation** - Runtime protection demonstrations
5. **XDR Investigation** - Threat analysis and forensics
6. **CI/CD Integration** - TMAS pipeline implementation
7. **Cleanup Procedures** - Complete environment teardown

### Key Demo Scenarios

| Scenario | Description | Duration |
|----------|-------------|----------|
| **Infrastructure Setup** | Deploy EKS with Terraform | ~15 mins |
| **Security Deployment** | Install and configure V1CS | ~10 mins |
| **Attack Simulation** | Runtime protection demos | ~15 mins |
| **XDR Investigation** | Threat analysis workflows | ~20 mins |
| **CI/CD Integration** | TMAS pipeline testing | ~30 mins |

## Key Components

### Security Features
- **Runtime Protection** - Behavioral monitoring with MITRE ATT&CK mapping
- **Vulnerability Scanning** - Image analysis with threshold-based policies  
- **Malware Detection** - Real-time container protection
- **CI/CD Security Gates** - Automated validation in deployment pipelines

### Automation Scripts

```bash
# Container Security deployment
./deploy_v1cs.sh                    # Deploy V1CS to EKS
./deploy_v1cs.sh --cleanup         # Remove all components

# Attack simulation  
./attack_v1cs.sh -h                # View all options
./attack_v1cs.sh --verbose --target app-server-1  # Run full test suite
```

## Important Notes

**Region**: All resources deploy to **us-east-1** - maintain consistency across activities

**Costs**: This demo provisions AWS resources that incur charges - remember to cleanup

**Security**: Uses intentionally vulnerable containers for demonstration - not for production

## Cleanup

Always cleanup resources after the demo:

```bash
# 1. Cleanup V1CS deployment
./deploy_v1cs.sh --cleanup

# 2. Destroy AWS infrastructure  
terraform destroy -auto-approve
```

## Support

For issues or questions:

1. Check the [detailed walkthrough](containersecurity-walk%20through.md) first
2. Review AWS CloudShell logs for deployment issues
3. Verify all prerequisites are properly configured

---

**Ready to start?** → [Open the Complete Walkthrough](containersecurity-walk%20through.md)