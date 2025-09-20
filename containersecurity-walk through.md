> NOTE: This walkthrough has been restructured into modular guides under `docs/`. Start here: `README.md`.

Welcome to the walkthrough guide for Trend Vision One - Container Security! We will walk you
through the necessary steps to get started with the platform and deploy a demo environment in
your AWS account. Whether you are new to container security or have prior experience, this guide
will help you navigate through the process smoothly.

Pre-requisite for the walkthrough

- **AWS account** – Deploying and testing Trend Vision One Container Security in an AWS
    environment using Amazon Elastic Kubernetes Services, allowing you to test and explore the
    platform’s capabilities in a controlled environment. A Terraform Script is provided within
    GitHub to ease the deployment of the process of the AWS environment.
- **Trend Vision One account** – This will allow us to administer and manage configurations
    related to Trend Vision One Container Security.
- **GitHub Account** – This will allow us to simulate a real-life world CI/CD pipeline leveraging
    Trend Vision One Container security rulesets and Trend Micro Artifact Scanner (TMAS) for
    image scanning.

**Note** :

The resources are provisioned on the North Virginia (us-east-1) region ensure this region is
maintained across all activities in AWS

Ensure to Git clone and fork this Repo has it has required scripts to automate the deployment of
Trend Vision One Container Security to the demo EKS cluster, simulate an attack scenario on
vulnerable containers and Github actions for TMAS demonstration – GitHub repo

## Deploy an AWS EKS environment with Terraform (IaC)

There are various ways, you can go about the deployment of your EKS environment within AWS
either using EKSCTL, Terraform template or manual provisioning via the AWS Console.

For this guide, we will be using Terraform, as it has its benefits.

For us to proceed with using Terraform, the following is required to be installed on your local
machine

- Terraform
- AWS CLI


Using this script below

```bash
# Install Terraform
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
*Figure 1: Terraform and AWS CLI installation script*
Note: These scripts apply to Linux endpoints – Ubuntu Distributions. For other OS versions (Windows
and Mac) kindly refer to the link below

- Install Terraform – [Link](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- Install AWS CLI – [Link](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

Once configured, ensure to set up AWS CLI by adding your access keys which is required by
Terraform to know where to deploy the infrastructure specified in the IaC.

For reference, kindly refer to the link below

Configure AWS CLI – [Link](https://docs.aws.amazon.com/cli/latest/reference/configure/)


Once set we can proceed with the Provisioning!


Before proceeding to the next steps, we need to create a backend Terraform state configuration
within our AWS account to ensure centralized state management, collaboration, security, and state
locking for reliable infrastructure changes.

**Note** : The resources are provisioned on the North Virginia (us-east-1) region ensure this region is
maintained across all activities in AWS

This process involves creating the following

- A DynamoDB table
- An S3 bucket

Since you have configured the AWS CLI you can directly create it from your CLI using the commands
below

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket --bucket terraform-state-bucket --region us-east-1

# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name terraform-state-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region us-east-1
```
*Figure 2: AWS CLI command - Provision S3 bucket and DynamoDB*
Note:

- terraform-state-bucket: Replace this with a unique S3 bucket name.
- terraform-state-locks: Replace this with your desired name for the DynamoDB table.

Login to AWS Console > Navigate to S3 > Check the S3 bucket.

Login to AWS Console > Navigate to DynamoDB > Verify the DynamoDB table.


These values are necessary to configure the _backend.tf_ file, which plays a crucial role in setting
up AWS EKS environment.

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```
*Figure 3: Sample of Backend.tf*
For more information on [Terraform Backend Block.](https://docs.aws.amazon.com/cli/latest/reference/configure/)

Note: The terraform files needed for the provisioning can be found in the Github repo within the
terraform folder.

In addition to the backend.tf file, other files like variables.tf must be modified to define
values such as the AWS region, project name, and other parameters. Terraform AWS modules is
utilized to simplify provisioning VPC and EKS by reducing configuration complexity, adhering to best
practices, and managing networking, dependencies, and scaling, so you can focus on project-specific
customizations.


Once the configuration is complete, you can provision your EKS cluster for the demo by following
these steps:

Ensure these steps are executed in the folder with the terraform files

```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Figure 4: Terraform Infra Provision*

![Terraform Init](images/Screenshot%202025-09-20%20at%2012.22.51.png)
![Terraform Plan Output](images/Screenshot%202025-09-20%20at%2012.23.01.png)
*Figure 5: Terraform plan output*

Sit back and let's wait for the resources to be created – it takes approximately 15 minutes

![Terraform Apply Output](images/Screenshot%202025-09-20%20at%2012.23.32.png)
*Figure 6: Terraform apply output*
- Login into your AWS console, to check that the EKS resources have been provisioned
    successfully
       - Navigate to EKS > Verify the EKS cluster.
       - Navigate to EC2 > Check the worker nodes.
       - Navigate to VPC > Confirm the networking setup.

![EKS Cluster Provisioned](images/Screenshot%202025-09-20%20at%2012.23.41.png)
*Figure 7: EKS Cluster provisioned*
Note: eksctl command link utility can also be used to provision an EKS cluster in minutes, refer to the
official documentation for more [information](https://eksctl.io/).

The reason for using Terraform over eksctl is its greater flexibility and modularity, allowing
comprehensive management of EKS and its dependencies, such as VPC and IAM, in a unified
workflow. While eksctl is ideal for quick setups in a demo environment, Terraform’ s reusability,


consistency, and scalability make it a better choice for long-term infrastructure management and
future enhancements.

## Deploy Trend Vision One Container Security on the Provisioned AWS

## EKS Infrastructure

Now we can proceed with deploying Trend Vision One Container Security on the AWS EKS

Login into your [Trend Vision One console](https://portal.xdr.trendmicro.com/) 

- **Create a Runtime Security Ruleset:**
    Create a Runtime Security ruleset based on the default template (LogOnlyRuleset). This
    ruleset will be applied to the Container Protection policy associated with the cluster where
    Trend Vision One Container Security is deployed.

```
Note: If Container Security hasn’t been provisioned, you will see the option to do it. Click on
“ Start Now” to provision the instance
```
- **Navigate** to Cloud Security > Container Security > Container Protection > Rulesets.
- **Duplicate** the LogOnlyRuleset and rename it according to your preference. The
    default rules are set to the "Log" action. You can add additional rules to the ruleset
    as needed.
- **For the demo** , all rules will be added to the ruleset for demonstration purposes. Feel
    free to pause and review the existing rules available to be added to a ruleset

![Runtime Security Ruleset](images/Screenshot%202025-09-20%20at%2012.23.52.png)
*Figure 8: Runtime Security Ruleset*
- **Create a Container Protection policy:**
    Container Protection policies include deployment, continuous, and runtime rules that can be
    applied to entire clusters or specific namespaces within clusters. In this process, you'll apply


```
the newly created rulesets and implement policy changes across all stages: Deployment,
Continuous, and Runtime.
```
- **Navigate** to Cloud Security > Container Security > Container Protection > Policies.
- **Duplicate** the LogOnlyPolicy and rename it based on your preference. The
    default policy is set to the "Log" action for Pod and Container properties in the
    **Deployment** and **Continuous** tabs.
- Duplicate the LogOnlyPolicy and rename it according to your preference. The default
    policy is set to the "Log" action for Pod and Container properties within the
    Deployment and Continuous tab.
- **Go to the Runtime Tab** , click **Add Ruleset** , and select the newly created ruleset to
    apply it.

Context About the Different Lifecycle Stages:

- Deployment Stage:
    This stage provides options enforced by the EKS Admission Controller. It ensures that images
    being deployed during build time are analysed for vulnerabilities and comply with configured
    policies before deployment.
- Continuous Stage:
    Like the Deployment stage, but these options apply to containers that are already running. It
    monitors and enforces policies when container properties are modified during runtime.
- Runtime Stage:
    This stage includes rulesets designed to protect containers from malicious or unauthorized
    activities inside each pod, ensuring security during active operations.


For more more [information](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-container-security).


![Container Protection Policy](images/Screenshot%202025-09-20%20at%2012.23.59.png)
*Figure 9: Container Protection Policy*
- Add Kubernetes cluster to Trend Vision One Container Security
    - **Navigate** to **Cloud Security > Container Security > Container Inventory**.
    - **For this demo** , we'll connect/add an AWS EKS cluster, but you can explore other
       options like Amazon ECS, Microsoft AKS, Google Kubernetes Engine (GKE), and self-
       managed clusters.
    - **Select** what environment you want to protect. Click on **Continue with Kubernetes**
    - **Choose Orchestration Platform** : Click **Amazon EKS** , then select **Deploy Protection to**
       **Kubernetes Cluster**.


- **Cluster Identification** : Enter a name to identify the cluster.
- **Policy Selection** : Choose the previously created Container Protection policy.
- **Enable Features** : Turn on **Runtime Security** , **Runtime Vulnerability Scanning** , and
    **Runtime Malware Scanning** , then click **Next**.
- **Important Instructions** : A pop-up will appear with instructions—note these details
    carefully as they are crucial for adding the Kubernetes cluster to Trend Vision One
    Container Security.
- **Download Configuration File** : Click the download button to save the
    overrides.yaml file to your system. Ensure you download it as it cannot be
    retrieved again. Click **Close** once downloaded.
- **Unassociated Cluster** : You will notice that the created cluster is not yet associated
    with the Amazon EKS orchestration platform.



- **Navigate** to the AWS Management Console and log in
- You’ll be using AWS Cloudshell for running deployment commands and uploading
    the necessary files required for the remaining activities.
- Click the CloudShell icon on the top right of the AWS console, then upload the
    following files:
    1. The overrides.yaml file downloaded earlier
    2. The cloned GitHub repository files (either download locally and upload to
       CloudShell or directly clone the repository using git clone in CloudShell).

```
Note : Ensure the file names remain unchanged, as the scripts used in this demo will
validate the required files for successful deployment.
```
- Review and move the overrides.yaml file into the cloned V1CS folder, ensuring
    all files are in the same directory, use the following command:

```bash
mv overrides.yaml V1CS/
cd V1CS/
ls -la
```
*Figure 10: Move files into V1CS directory*

![CloudShell File Organization](images/Screenshot%202025-09-20%20at%2012.24.07.png)
- Scripts and Use Cases
    - deploy_v1cs.sh – Deployment Script:
       This script automates the deployment process for Trend Vision One
       Container Security and performs the following key functions:
- Checks for required tools and files necessary for deploying Trend Vision One
Container Security (e.g., Helm, jq).
- Installs missing tools such as Helm (for Kubernetes package management)
and jq (for JSON parsing).
- Deploys Trend Vision One Container Security to the EKS demo cluster.
- Deploys sample vulnerable containers for demonstration purposes.


- Provides an option to clean up and remove all deployed resources after
    completing the demo, ensuring a clean environment.
- attack_v1cs.sh – Attack Script:
This script simulates attacks on the vulnerable containers deployed in the demo
EKS cluster and performs the following:
- Simulates an attack on the vulnerable containers which triggers Runtime
rulesets attached to the Container Protection policy used by our demo EKS
cluster Simulates attacks on vulnerable containers, triggering the runtime
rulesets configured in the Container Protection policy for the EKS cluster.
- Allows you to choose specific attack scenarios to execute, enabling focused
demonstrations.
- Generates logs each time the script is executed, providing detailed insights
into the triggered attack scenarios and their outcomes.
- To change the permissions of the scripts and make them executable in AWS
CloudShell, run the following commands:

```bash
chmod +x deploy_v1cs.sh
chmod +x attack_v1cs.sh
```
*Figure 11: Make scripts executable*
- Before executing the deployment script, run the following command to update your
    kubeconfig and authenticate with the EKS cluster:

```
Enables the deployment script to interact with the cluster using kubectl.
```
```bash
aws eks update-kubeconfig --region us-east-1 --name clustermake
```
*Figure 12: For authentication and management of EKS cluster*
- Before running the deploy_v1cs.sh script, use the -h argument to view its full
    functionality and available options:


![Deploy Script Help](images/Screenshot%202025-09-20%20at%2012.24.28.png)
*Figure 13: Deploy Script*
- Upon successful deployment, the script will display the deployed resources and end
    with a message: **"Deployment completed successfully."**

```
Error handling: If any issues occur during deployment, the process will halt, and the
script will display an error message with details for debugging and troubleshooting.
```
- After a few minutes, navigate to the Trend Vision One dashboard to verify the
    deployment status. Check for green icons in the **Runtime Security** , **Runtime**
    **Vulnerability** , and **Runtime Malware Scanning** sections to confirm successful
    deployment and proper reporting.

```
You have successfully completed the Container Security deployment. Next, proceed
to execute the attack scenarios to trigger the rulesets and review the generated
events.
```
![AWS CloudShell](images/Screenshot%202025-09-20%20at%2012.24.51.png)
*Figure 14: AWS CloudShell*
![AWS CloudShell Files Upload](images/Screenshot%202025-09-20%20at%2012.25.16.png)
*Figure 15: AWS CloudShell Files Upload*



![Deployment Successful](images/Screenshot%202025-09-20%20at%2012.25.25.png)
*Figure 16: Deployment successful*

![Deployment Successful - Vision One](images/Screenshot%202025-09-20%20at%2012.25.33.png)
*Figure 17: Deployment successful - Vision One*


## Trigger Runtime Events in Trend Vision One - Container Security

This section guides you through generating runtime events in Trend Vision One Container Security
within the demo environment, simulating attack scenarios, reviewing detections, and understanding
the importance of monitoring and analyzing runtime events to secure containerized environments.

1. Simulating Attack Scenarios to Trigger Runtime Protection Events

```
Recall that you previously created a Runtime ruleset and assigned it to the Container
Protection Policy, which is now enforced on the demo EKS cluster.
```
- **Navigate back to AWS CloudShell** and ensure you are in the same V1CS folder.
- Before running the attack_v1cs.sh script, use the -h argument to view its full
    functionality and available options:

![Attack Script Help](images/Screenshot%202025-09-20%20at%2012.25.52.png)
*Figure 18: Attack Script*
```
The -h option displays the available commands, security tests, and examples of how to
execute the script. In this demo environment, there are two vulnerable containers, and you
can choose which container to target for the attack.
```
- Let’s test the script on app-server- 1 using the --verbose and --target
    options to view detailed execution and run all tests for an evaluation. Using the
    command:

```bash
./attack_v1cs.sh --verbose --target app-server-1
```
*Figure 19: Attack Script command syntax*
```
Note: app-server- 2 can only tests for Security Tests Commands section while
app-server- 1 tests for all.
```
```
Once all tests are done a message which highlights “Full system test completed” is
displayed.
```


![Attack Scenario Completed](images/Screenshot%202025-09-20%20at%2012.26.07.png)
*Figure 20: Attack Scenario completed*
2. Runtime Detection Event Analysis
    - **Navigate** to the **Trend Vision One Console > Cloud Security > Container Security >**
       **Container Protection** to review detections in the **Events** tab.
    - Check for events generated in both the **Deployment/Continuous** and **Runtime** tabs.
    - You’ll notice events are categorized by policy, cluster, namespace, operation, and
       resource type (Kind).
    - Each event details specific policy violations, such as containers running with privilege
       escalation rights or those permitted to run as root.
    - Navigate to the **Runtime** tab to review the events generated during the runtime
       stage of the container's lifecycle.
    - Several runtime detection events were generated, including one based on the rule
       **"(T1613)Peirates tool detected in container."** To Provide context Peirates is a
       Kubernetes penetration testing tool used by attackers to escalate privileges and
       pivot within a Kubernetes cluster. And another rule **"(T1552)Search Private Keys or**
       **Passwords”**
       You’ll observe information such as the exact command ran in the container, parent
       process, rule name mapped to the MITRE ATT&CK TTP, namespace, image digest,
       and container ID—all of which can be utilized for forensic analysis.



![Investigate Container Events](images/Screenshot%202025-09-20%20at%2012.26.22.png)
*Figure 21: Investigate Container Events*


You have successfully triggered runtime events and reviewed the generated detections. Next,
proceed to leverage Trend Vision One XDR to investigate container events further.

## Investigate Container Events Using Trend Vision One - XDR

Now you'll learn how to investigate container events in Trend Vision One - XDR by navigating the
platform, adjusting filters, searching for container telemetry, and reviewing attack techniques,
Workbench alerts, and Attack Surface Discovery details. This provides valuable insights for improving
container security and effectively analysing container-related events.

- Using Search App – Container Telemetry
    Use the Trend Vision One Search app to analyze container telemetry and gain context about
    the simulated attack, including its impact and related activities.
       - **Navigate** to the **Trend Vision One Console** > **XDR Threat Investigation** > **Search**.
       - Set the search method data source to **"Container Activity Data"** and use the search
          query clusterName with the value clustermake to view search results.
       - Examine one of the results, such as an attack involving the command rm -rf
          /var/log which deletes system and application log files—a tactic often tagged as
          **Defense Evasion**.
       - Try additional [container activity data](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-container-activity-data) search queries to discover more about the
          capabilities of the search application.


![Search App - Telemetry](images/Screenshot%202025-09-20%20at%2012.26.55.png)
*Figure 22: Search App - Telemetry*
- Using Observed Attack Techniques App – Container Telemetry
    Use the **Observed Attack Techniques** app in Trend Vision One Container Security to analyze
    detected events. While not all events escalate into Workbench insights or alerts, the
    granular data provided by predefined or custom detection filters can help you investigate
    Workbench insights and evaluate individual detections for a deeper understanding of
    security threats.
       - **Navigate** to the **Trend Vision One Console** > **XDR Threat Investigation** > **Observed**
          **Attack Techniques**.
       - Set the event severity to **Critical** , **High** , **Medium** and **Detection time** within the time
          when the attack script was executed and click **Apply**.
       - You’ll see a couple of Observed Attack Techniques, expand one of the high-severity
          entries to explore detailed information.
       - Review details like processcmd, cluster name, container ID, and other data
          to gather context.



- Using Workbench – Container Telemetry
    Use the **Workbench** to analyze high-priority alerts and correlated events for containerized
    environments. Focus on **Workbench Insights** for critical investigations or explore **All Alerts**
    for root cause and impact analysis.
       - **Navigate** to the **Trend Vision One Console** > **XDR Threat Investigation** >
          **Workbench**.
       - Click the **Workbench Insights** tab to view high-priority container security events with
          actionable insights.
       - Switch to the **Workbench Alerts** tab to review container security alerts and select an
          alert to investigate its details and impact.
       - For the alert **"Privilege Escalation in Container"** , review the summary, highlights,
          observable graph, and available response actions.
       - Take time to explore and review other alerts for additional insights, if desired.



![Workbench Alert](images/Screenshot%202025-09-20%20at%2012.27.03.png)
*Figure 23: Workbench Alert*

![Attack Surface Discovery - Cloud Assets](images/Screenshot%202025-09-20%20at%2012.27.16.png)
*Figure 24: Attack Surface Discovery - Cloud Assets*

![K8s Cluster Risk Assessment](images/Screenshot%202025-09-20%20at%2012.27.27.png)
*Figure 25: K8s Cluster Risk Assessment*
You have successfully reviewed the XDR alerts and explored how Trend Vision One XDR enhances
context for container security. Next, let’s proceed to a real-life CI/CD pipeline scenario using **Trend
Micro Artifact Scanner (TMAS)** to scan container images before they are pushed to production.

## Integrate Container Image Scanning into CI/CD Pipelines with Trend

## Micro Artifact Scanner (TMAS)

Now, you’ll be exploring the use of the Trend Micro Artifact Scanner (TMAS) to perform pre-runtime
scans on container images. This will enable you to identify and resolve issues before they reach the
production environment as part of your CI/CD pipeline.

For the next steps you’ll need to fork the repo with the [Github Workflow](https://github.com/ToluGIT/V1CS.git)

- Understanding of the continuous integration (CI) or continuous delivery (CD) pipeline

```
GitHub Actions is a continuous integration and continuous delivery (CI/CD) platform that
automates build, test, and deployment pipelines on GitHub. It enables workflows to be
triggered by repository events, such as a pull request, issue creation, or push and supports
tasks like adding labels to issues or automating complex DevOps pipelines.
```

```
Workflows, defined as YAML files in the.github/workflows directory, consist of one or
more jobs that can run sequentially or in parallel within virtual machine runners or
containers. For this demo, you’ll be using GitHub Actions as the pipeline, involving two
workflows to automate the process effectively.
```
- imgcreate-push.yaml – Uses **Trend Micro Artifact Scanner (TMAS)** to perform
    security scans on a container image during the CI/CD pipeline. It builds and scans the
    container image for vulnerabilities, malware, secrets, generates SBOMs (Software
    Bill of Materials) and provides detailed results via Slack and email notifications,
    ensuring proactive risk mitigation before production deployment.

```
Note: The install_tmas.cli.sh—is responsible for installing the latest version
of TMAS within the GitHub action runner environment and checking for its OS
architecture dependencies.
The container image is built using a Dockerfile with intentionally known
vulnerabilities and EICAR test malware, commonly used for testing security tools and
detection capabilities.
```
- prod-deploy.yaml - Automates the deployment of a validated container image
    by TMAS to an Amazon EKS cluster after a successful security scan by the
    imgcreate-push.yaml workflow. It dynamically generates Kubernetes manifests,
    applies them to the cluster, configures secure image pulls, and verifies the
    deployment for successful operation to production
- For the pipelines to work effectively some secrets and variables are required

**Type Name Description
Secret** TMAS_API_KEY^ API key for Trend Micro Artifact Scanner (TMAS).^
**Secret** AWS_ACCESS_KEY_ID^ AWS access key ID for authenticating with AWS services.^
**Secret** AWS_SECRET_ACCESS_KEY^ AWS secret access key for authenticating with AWS
services.
**Secret** REGION^ AWS region for deploying resources.^
**Secret** GH_TOKEN^ GitHub token for authenticating with GitHub Container
Registry (GHCR).
**Secret** EMAIL_USERNAME^ Email address used for sending notifications.^
**Secret** EMAIL_PASSWORD^ Password or app-specific key (recommended) for the
email address.
**Secret** SLACK_BOT_TOKEN^ Token for authenticating and posting messages to a Slack
channel.
**Secret** VALUES^ Name of the Amazon EKS cluster being used
(clustermake).
**Value** IMAGE_NAME^ Name of the container image being built and deployed
(vulnerable-test-image).
**Value** NAMESPACE^ Kubernetes namespace for deploying the container
(default).
**Value** THRESHOLD^ Security threshold level for the scan (medium). The
threshold can be modified based on the required values.
For more details on the [threshold levels](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-override-vulnerability-findings).
**Value** MALWARE_SCAN^ Flag to enable malware scanning (true).^
**Value** SECRETS_SCAN^ Flag to enable secrets scanning (true).^
**Value** FAIL_ACTION^ Determines if the pipeline fails on detection issues
(false).
**Value** REGION^ Vision One Region (Default = us-east-^1 ).^
_Table 1 : Secrets and Values Used in GitHub Workflows_


![GitHub Actions](images/Screenshot%202025-09-20%20at%2012.27.36.png)
*Figure 26: GitHub Actions*
Now that you understand how the CI/CD pipeline functions, let’s move on to integrating Trend Micro
Artifact Scanner (TMAS) into the pipeline and executing it.

- Integrating Trend Micro Artifact Scanner with Github actions (CI/CD) pipeline
    - **Navigate** to the **Trend Vision One Console** > **Cloud Security** > **Container Security** >
       **Container Protection**.
    - Click on the **Container Image Scanning** tab and follow the steps to generate the
       Trend Micro Artifact Scanner API key. Refer to the documentation for more details
       on [obtaining an API key](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-obtaining-api-key).
    - Add the generated API key as a **secret** TMAS_API_KEY in your GitHub Actions
       workflow.
    - To do this, navigate to the forked repository, click on the **Settings** tab > **Secrets and**
       **Variables** > **Actions** , and add or modify the secrets as needed.
    - Define the other required **secrets and values** and customize the workflow stages
       according to your needs.


![Artifact Scanner Setup Guide](images/Screenshot%202025-09-20%20at%2012.28.02.png)
*Figure 27: Artifact Scanner Setup Guide*

![GitHub Secrets](images/Screenshot%202025-09-20%20at%2012.28.08.png)
*Figure 28: GitHub Secrets*

- Run Github Workflow (CI pipeline)
    It’s time to trigger the workflow imgcreate-push.yaml to build the container image and
    scan using TMAS
       - Navigate to **Actions** in the GitHub repository, where you’ll see two workflows:
          **docker-image-security-scan-tmas** and **Deploy to K8S**.
       - Run the **docker-image-security-scan-tmas** workflow manually by clicking on the
          workflow, selecting **Run workflow** , choosing **Branch: main** , and clicking **Run**
          **workflow**.
       - Monitor the workflow as it progresses by clicking on the running workflow.
       - Once completed, review the action's output. You’ll notice it fails with an error code
          **exit 1** and a message indicating the failure is due to the vulnerability threshold being
          exceeded on the built container image.
       - Artifacts such as **results.json** (vulnerabilities and malware) and **sbom.json** (SBOM)
          are generated and sent via the configured notification channels, such as Slack and
          Gmail.

![CI Pipeline fails on TMAS scan](images/Screenshot%202025-09-20%20at%2012.28.32.png)
*Figure 29: CI Pipeline fails on TMAS scan*

![Email Notification - Scan results](images/Screenshot%202025-09-20%20at%2012.28.59.png)
*Figure 30: Email Notification - Scan results*

![Slack Notification - Scan results](images/Screenshot%202025-09-20%20at%2012.29.30.png)
*Figure 31: Slack Notification - Scan results*

- Bypassing Github Workflow (CI Pipeline) to Publish Vulnerable Image (CI/CD Pipeline)
    Now you can observe the Trend Micro Artifact Scanner blocking the vulnerable image from
    being published to the GitHub registry. Let’s bypass this restriction to allow the image to be
    used in production while leveraging the TMAS results within the Trend Vision One Container
    Protection Policy to block it from being deployed in the production environment (CD
    pipeline).
       - Navigate to the **GitHub repository** , go to the **.github/workflows** directory, and
          locate the imgcreate-push.yaml file.
       - Modify the FAIL_ACTION environment variable in the env section as shown below:

```yaml
env:
  FAIL_ACTION: "false"  # Changed from "true" to "false" to bypass failure
```
*Figure 32: Bypass Fail action*
- Navigate to the **Trend Vision One Console** > **Cloud Security** > **Container Security** >
    **Container Protection**.
- Click on **Policies** and select the policy currently assigned to the cluster (e.g.,
    **Demo_Policy** ).
- Go to the **Deployment** tab and update the **Artifact Scanner Results** section with the
    required changes.


![Artifact Scanner Result change](images/Screenshot%202025-09-20%20at%2012.29.37.png)
*Figure 33: Artifact Scanner Result change*
- Re-run the **docker-image-security-scan-tmas** workflow.
- Notice that the **docker-image-security-scan-tmas** workflow completes successfully,
    and the image is published, triggering the **Deploy to K8S** workflow automatically.
- Navigate to the **GitHub Actions** tab, select the **Deploy to K8S** workflow, and observe
    that it failed due to the Trend Micro Admission Controller webhook blocking the
    deployment of the vulnerable image based on the enforced policy.
- Go to the **Trend Vision One Console > Cloud Security > Container Security >**
    **Container Protection**.
- In the **Events tab > Deployment/Continuous tab** , verify that the deployment was
    blocked.
- Check the **Container Image Scanning** tab to review TMAS scan results, including
    vulnerabilities, malware, and secrets (note: the vulnerable image built contains no
    embedded secrets).


![docker-image-security-scan-tmas workflow successful](images/Screenshot%202025-09-20%20at%2012.30.03.png)
*Figure 34: docker-image-security-scan-tmas workflow successful*

![Deploy to K8S workflow failed](images/Screenshot%202025-09-20%20at%2012.30.28.png)
*Figure 35: Deploy to K8S workflow failed*

![Deployment blocked event](images/Screenshot%202025-09-20%20at%2012.30.41.png)
*Figure 36: Deployment blocked event*

![TMAS Result - Image](images/Screenshot%202025-09-20%20at%2012.30.50.png)
*Figure 37: TMAS Result - Image*

![TMAS Result - Artifact Vulnerabilities](images/Screenshot%202025-09-20%20at%2012.30.57.png)
*Figure 38: TMAS Result - Artifact Vulnerabilities*

![TMAS Result - Artifact Malware](images/Screenshot%202025-09-20%20at%2012.31.19.png)
*Figure 39: TMAS Result - Artifact Malware*
You’ve successfully simulated a real-world CI/CD pipeline scenario with Trend Micro Artifact
Scanner, scanning images before they are pushed to production. The scanner halted deployment
when the set criteria were not met and sent notifications to alert stakeholders, demonstrating
effective security enforcement.

## The Cleanup

You will now proceed to clean up the demo environment by following these steps:

1. Cleanup using deploy_v1cs.sh
    - Navigate back to the **AWS CloudShell** by clicking the CloudShell icon in the top-right
       corner of the AWS Console.
    - The session should be stateful, and the files uploaded in previous steps will still be
       available.


- Navigate to the V1CS directory and execute the following command to clean up the
    environment:

```bash
./deploy_v1cs.sh --cleanup
```
*Figure 40: The cleanup – deploy_v1cs.sh*
- A list of resources being cleaned up along with checkout messages will be displayed
    during the cleanup process.
- Once the process is complete, an output message will appear stating: **"Clean**
    **completed successfully."**


![deploy_v1cs.sh cleanup successful](images/Screenshot%202025-09-20%20at%2012.31.27.png)
*Figure 41: deploy_v1cs.sh cleanup successful*
2. Cleanup using terraform destroy
    - Navigate back to your IDE where terraform apply was previously executed to
       provision the AWS EKS environment.
    - Run the following command to clean up all resources provisioned in AWS:

```bash
terraform destroy -auto-approve
```
*Figure 42: The cleanup - terraform destroy*
```
Ensure this command is executed within the same folder containing the Terraform
configuration files and where terraform apply was originally run.
```
- When the command is run, a list of resources scheduled for destruction will be
    displayed. Since the -auto-approve argument is used, the resources listed in the
    Terraform state file will be automatically deleted without requiring further
    confirmation.


- Once the process is complete, an output message such as **"Destroy complete"** will
    be displayed to confirm the successful cleanup of resources.


![Terraform cleanup successful](images/Screenshot%202025-09-20%20at%2012.31.36.png)
*Figure 43: Terraform cleanup successful*
### Conclusion

Congratulations on completing the Trend Vision One Container Security implementation! You've
successfully navigated through deploying an EKS environment, configuring container security
protections, simulating attacks, and implementing secure CI/CD practices - equipping you with the
hands-on experience to secure your containerized environments.


