> [!NOTE]
> This repository is maintained by AWS FSI PACE team. While it has been thoroughly tested internally there might be things that we still need to polish. If you encounter any problems with the deployment process please open a GitHub Issue in this repository detailing your problems and our team will address them as soon as possible.

# Solutions Deployment Guide

## Table of Contents

- [Pre-requisites](#deployment-pre-requisite)
  - [Packages](#packages)
  - [AWS CLI setup](#aws-cli-setup)
  - [Clone the code base](#clone-the-code-base)
  - [Environment setup](#environment-setup)
- [Deployment steps](#deployment-steps)
- [Troubleshooting](#troubleshooting)

## Deployment Pre-requisite

### Packages

In order to execute this deployment, please ensure you have installed the following packages on the machine from which you're deploying the solution:

- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

_Note: Make sure that the latest AWS CLI version is installed. If not, some functionalities won't be deployed correctly._

- [Terraform >= 1.8.0](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Git CLI](https://git-scm.com/downloads)
- [Python >= 3.10](https://www.python.org/downloads/)
- [PIP >= 25.0.1](https://pypi.org/project/pip/)
- [make](https://www.gnu.org/software/make/)
- [jq](https://stedolan.github.io/jq/)

_Note: Make sure the machine you are deploying from has up to 15 GB free space to deploy the entire solution. We have included a clean up script (module 21) to clean up the cache in the local machine after deployment._

> [!CAUTION]
> We are using the latest version 5 for the AWS Terraform provider (v 5.100) in every module of this solution. Please do not update providers to the latest version 6 as it will break the deployment process.

### Clone the code base

1. Open your local terminal, go to the directory in which you wish to download the DAIVI solution using `cd`
2. Run the following command to download codebase into your local directory:

```
git clone https://github.com/aws-samples/sample-pace-data-analytics-ml-ai.git
```

3. From your terminal, go to the root directory of the DAIVI codebase using:

```
cd sample-pace-data-analytics-ml-ai
```

### Environment setup

#### Input variable names used in the prototype and their meanings

> [!CAUTION]
> Please do not use '-' sign in app or environment name in this step. This will break SQL quesry executions in the Datalake modules.

```
# 12 digit AWS account ID to deploy resources to
AWS_ACCOUNT_ID

# The application name that is used to name resources
# It is best to use a short value to avoid resource name length limits
# Example: daivi
APP_NAME

# The environment name that is used to name resources and to determine
# the value of environment-specific configurations.
# It is best to use a short value to avoid resource name length limits
# Select environment names that are unique.
# Examples: quid7, mxr9, your initials with a number
ENV_NAME

# Primary AWS region to deploy application resources to
# Example: us-east-1
AWS_PRIMARY_REGION

# Secondary AWS region to deploy application resources to
# Example: us-west-2
AWS_SECONDARY_REGION
```

<br>

Environment Setup Steps:

1. **Deployment Role**: Use AWS CLI to login to the account you wish to deploy to, using a deployment role with sufficient privileges to deploy the solution, preferably using the admin role or an equivalent role with sufficient privileges. The solution assumes that you will login to AWS Management console using this deployment role. This role is also referred to as Admin role in the deployment instructions.

To setup your aws-cli with deployment role credentials run the following command:

```
aws configure
```

Alternatively, you can manually modify the following files:

`~/.aws/config`

`~/.aws/credentials`

Alternatively, you can manually initialize the terminal with STS credentials for the role, by obtaining temporary STS credentials from your administrator.

```
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
```

2. **Initialization**: From your terminal, go to the root directory of the DAIVI codebase and execute the following command.
   This command will run a wizard that will ask you to provide a value for all of the configuration settings documented above.
   It will perform a search/replace on the project files so that they use the values you provide.

```
make init
```

3. **Set Up Terraform Backend**: Execute the following command to set up S3 buckets to store the project's Terraform state.

```
make deploy-tf-backend-cf-stack
```

## Deployment Steps

The Makefile contains a "deploy-all" target, but we strongly recommend tha you "**DO NOT**" use this make target. We do not recommend deploying the solution in one go. This is due to the time needed for some make targets to initialize, warm-up and execute correctly. For example, job schedulers need time to properly set up their triggers. Also some make targets have linear dependency on other make targets. Deploying it in one go will likely cause configuration errors since some deployed make targets may not be fully functional yet and thus, not ready to be used.

Therefore, we recommend deploying the make targets incrementally, one make target at a time, to allow each make target to execute successfully and be fully operational before the next make target is executed:

1. Deploy each make target one at a time
2. Wait for each make target to complete
3. Verify that the make target is fully operational
4. Only then proceed to the next make target

The solution consists of a number of modules. Each module consists of a number of make targets. Please deploy the modules in the order mentioned below (just skip "Billing Data Lake - CUR" module, which you will execute after 24 hours). Each module has a make target, ex: deploy-foundation. Please "**DO NOT**" invoke the make target for a module. Instead invoke individual make targets under each module in the order they are mentioned, waiting for each make target to complete successfully before moving to the next make target.

You will need to deploy the following modules in order to deploy the whole solution.

| Order | Module                                                                                                        |
| ----- | --------------------------------------------------------------------------------------------------------------|
| 1     | [Foundation](#1-foundation)                                                                                   |
| 2     | [IAM Identity Center](#2-iam-identity-center)                                                                 |
| 3     | [Sagemaker Domain](#3-sagemaker-domain)                                                                       |
| 4     | [Sagemaker Projects](#4-sagemaker-projects)                                                                   |
| 5     | [Glue Iceberg Jar File](#5-glue-iceberg-jar-file)                                                             |
| 6     | [Lake Formation](#6-lake-formation)                                                                           |
| 7     | [Athena](#7-athena)                                                                                           |
| 8     | [Data Lakes](#8-data-lakes)                                                                                   |
| 9     | [FinOps Billing S3-Glue-S3 Data Lake - Static](#9-finops-billing-s3-glue-s3-data-lake---static)               |
| 10    | [FinOps Billing S3-Glue-S3 Data Lake - Dynamic](#10-finops-billing-s3-glue-s3-data-lake---dynamic)            |   
| 11    | [FinOps Billing S3-Glue-S3 Data Lake - CUR (After 24 hours)](#11-finops-billing-s3-glue-s3-data-lake---cur)   |
| 12    | [FinOps Inventory S3-Glue-S3 Data Lake - Static](#12-finops-inventory-s3-glue-s3-data-lake---static)          |
| 13    | [FinOps Inventory S3-Glue-S3 Data Lake - Dynamic](#13-finops-inventory-s3-glue-s3-data-lake---dynamic)        |
| 14    | [FinOps Splunk S3-Glue-S3 Data Lake](#14-finops-splunk-s3-glue-s3-data-lake)                                  |
| 15    | [Equity Price S3-Glue-S3 Data Lake](#15-equity-price-s3-glue-s3-data-lake)                                    |
| 16    | [Equity Trade S3-Glue-S3 Data Lake](#16-equity-trade-s3-glue-s3-data-lake)                                    |
| 17    | [Equity Trade MSK-Glue-S3 Data Lake](#17-equity-trade-msk-glue-s3-data-lake)                                 |
| 18    | [Equity Trade MSK-Flink-MSK Data Lake](#18-equity-trade-msk-flink-msk-data-lake)                              |
| 19    | [Equity Order Dynamodb-ZeroETL-S3 Data Lake](#19-equity-order-dynamodb-zeroetl-s3-data-lake)                  |
| 20    | [Sagemaker Project Configuration](#20-sagemaker-project-configuration)                                        |
| 21    | [Datazone Domain and Projects](#21-datazone-domain-and-projects)                                              |
| 22    | [Snowflake Connection](#22-snowflake-connection)                                                              |
| 23    | [Equity Order Snowflake-ZeroETL-Federation](#23-equity-order-snowflake-zeroetl-federation)|
| 24    | [Quicksight Subscription](#24-quicksight-subscription)                                                        |
| 25    | [Quicksight Visualization](#25-quicksight-visualization)                                                      |
| 26    | [Custom Data Lineage](#26-custom-data-lineage)                                                                |
| 27    | [EMR Serverless with Jupyter Notebook](#27-emr-serverless-with-jupyter-notebook)                              |
| 28    | [Spark Code Interpreter](#28-spark-code-interpreter)                                                          |
| 29    | [Post Deployment Testing](#29-post-deployment-testing)                                                        |
| 30    | [Clean Up Cache](#30-clean-up-cache)                                                                          |
| 31    | [AgentCore](#31-agentcore)                                                                                    |

---

## Prep: Set up Admin Role in Makefile

- Open Makefile in root folder
- Line #16 of the make file has a constant called "ADMIN_ROLE"
- Please specify the name of the IAM role you will use to login to AWS management console. This role will be granted lake formation access to the Glue databases, so that you can execute queries against the Glue databases using the Athena console.

## 1. **Foundation**

The foundation module deploys the foundational resources, such as KMS Keys, IAM Roles and S3 Buckets that other modules need. We are provisioning KMS Keys and IAM Roles in a separate module and passing them as parameters to other modules, as in many customer organizations the central cloud team provisions these resources and allows the application teams to use these resources in their applications. We recommend that you review the IAM roles in foundation module with your cloud infrastructure team and cloud security team, update them as necessary, before you provision them in your environment. You **MUST** deploy the make targets for this module first before deploying make targets for other modules. Please execute the following make targets in order.

#### To deploy the module:

```
make deploy-kms-keys
make deploy-iam-roles
make deploy-buckets
make deploy-vpc
make build-msk-data-generator-lambda-layer-zip
make deploy-msk
```

| Target             | Result                                                                          | Verification                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------------------ | ------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| deploy-kms-keys    | Provisions KMS keys used by different AWS services                              | Following KMS keys and aliases are created: <br> 1. {app}-{env}-secrets-manager-secret-key <br> 2. {app}-{env}-systems-manager-secret-key <br> 3. {app}-{env}-s3-secret-key <br> 4. {app}-{env}-glue-secret-key <br> 5. {app}-{env}-athena-secret-key <br> 6. {app}-{env}-event-bridge-secret-key <br> 7. {app}-{env}-cloudwatch-secret-key <br> 8. {app}-{env}-datazone-secret-key <br> 9. {app}-{env}-ebs-secret-key <br> 10. {app}-{env}-msk-secret-key <br> 11. {app}-{env}-dynamodb-secret-key                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| deploy-iam-roles   | Provisions IAM roles used by different modules                                  | Following IAM roles are created: <br> 1. {app}-{env}-glue-role <br> 2. {app}-{env}-lakeformation-service-role <br> 3. {app}-{env}-eventbridge-role <br> 4. {app}-{env}-lambda-billing-trigger-role <br> 5. {app}-{env}-lambda-inventory-trigger-role <br> 6. {app}-{env}-splunk-role <br> 7. {app}-{env}-event-bridge-role <br> 8. {app}-{env}-sagemaker-role <br> 9. {app}-{env}-datazone-domain-execution-role <br> 10. {app}-{env}-quicksight-service-role                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| deploy-buckets     | Deploy S3 buckets needed by different modules                                   | Following S3 buckets are created: <br> 1. {account}-{app}-{env}-glue-scripts <br> 2. {account}-{app}-{env}-glue-jars <br> 3. {account}-{app}-{env}-glue-spark-logs <br> 4. {account}-{app}-{env}-glue-temp <br> 5. {account}-{app}-{env}-athena-output <br> 6. {account}-{app}-{env}-amazon-sagemaker <br> 7. {account}-{app}-{env}-smus-project-cfn-template |
| deploy-vpc         | Deploy a common vpc to be used for the project                                  | Following resource are creates: <br> 1. {app}-{env}-vpc (10.38.0.0/16) <br> 2. private subntes (3) <br> 3. public subnets (3) <br> 4. {app}-{env}-public-rt public route table with 3 public sunet associated and route to internet gateway <br> 5. {app}-{env}-private-rt private route table with 3 private route table association and route to NAT gateway <br> 6. A {app}-{env}-nat-gateway <br> 7. A {app}-{env}-igw internet gateway attached to vpc                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| build-msk-data-generator-lambda-layer-zip | builds a zip for msk data generator lambda dependencies                             | verify dependencies_layer.zip exists at iac/roots/foundation/msk-serverless/data-generator                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| deploy-msk         | Deploy MSK cluster along with kafka tool on ec2 and lambda based data generator | 1. Verify {app}-{env}-msk-cluster is in active status <br> <br> 2. verify {app}-{env}-msk-producer-lambda lambda function <br> <br> 3. EC2 instance deployed with kafka ui tool --> {app}-{env}-msk-client. To view the MSK cluster topics and messages, update the ec2 security group to allow traffic from your public ip and access the UI on EC2 public ip on port 9000                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |

## 2. **IAM Identity Center**

The IAM Identity Center module enables deployment of either:

- An account-specific instance (isolated to a single AWS account)
- An organization-wide instance (managed through AWS Organizations)

Choose the deployment type that best suits your organization's requirements.[Review AWS Documentation](https://docs.aws.amazon.com/singlesignon/latest/userguide/identity-center-instances.html) to understand the differences between Account-level versus Organization-level Identity Center

#### Before deploying this step:

**Important Note**: Only one instance can be deployed across all regions, and it must be either Account-level or Organization-level.

#### To deploy the account level identity center configuration:

```
make deploy-idc-acc
```

#### To deploy the organization level identity center configuration:

**Note**: This step is only applied to organization-level IAM Identity Center. For account-level or standalone instance, this step has been automated as part of the deployment process.
Before configuring Identity Center for organization-level using make targets:

1. Enable the Organization-level manually on the IAM Identity Center Console

- Navigate to IAM Identity Center in the console
- For organization-level: Select "Enable" > _Enable IAM Identity Center with AWS Organizations_ > "Enable"

2. Ensure no existing Identity Center instance is running

- Must delete previous instance before deploying new one
- Currently no programmatic support is available to enable Identity Center through IaC

```
make deploy-idc-org
```

| Target         | Result                                                                                 | Verification                                                                                                                                                                                                                                                                                                                                                        |
| -------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| deploy-idc-acc | Deploy IAM Identity Center groups, users (Account-level)                               | Following groups are created in Identity Center: <br> 1. Admin <br> 2. Domain Owner <br> 3. Project Owner <br> 4. Project Coordinator <br> <br> Following users are created in Identity Center: <br> 1. chris-bakony-admin@example.com <br> 2. ann-chouvey-downer@example.com <br> 3. lois-lanikini-powner@example.com <br> 4. ben-doverano-contributor@example.com |
| deploy-idc-org | Provisions IAM Identity Center groups, users, and permission sets (Organization-level) | Following groups are created in Identity Center: <br> 1. Admin <br> 2. Domain Owner <br> 3. Project Owner <br> 4. Project Coordinator <br> <br> Following users are created in Identity Center: <br> 1. chris-bakony-admin@example.com <br> 2. ann-chouvey-downer@example.com <br> 3. lois-lanikini-powner@example.com <br> 4. ben-doverano-contributor@example.com |

---

#### Two-Factor Authentication:

IAM Identity Center is configured to require two-factor authentication. We recommend you retain the two-factor authentication configured. In case, you would like **disable two-factor authentication** in your sandbox account to make it easy for you to login to Sagemaker Unified Studio, you can otherwise run the following deployment command after your IDC instance has been created:

```
make disable-mfa
```

We do not recommend disabling multi-factor authentication. However, if you used the above commands to make it easy for you to explore the DAIVI solution in a Sandbox account, we recommend that you enable multi-factor authentication once you have completed exploring DAIVI solution. We do not recommend disabling multi-factor authentication in development, test or production environment.

#### Setting Password for Users:

Execute the following steps to set up passwords for the users created in IAM Identity Center.

1. Click on "User" in left navigation panel
2. For each "User" in the list do the following
3. Click on the "Username" to go to the page for the user
4. Click on "Reset password" on top right
5. Selct the check box "Generate a one-time password and share the password with the user"
6. Click on "Reset password" button
7. It will show "One-time Password" window
8. Click on the square on left of the "one-time password" to copy the password to clipboard
9. Store the username and the one-time password in a file using your favorite editor. You will need this username and one-time password to login to Sagemaker and Datazone.

#### Useful Command to Delete a Previously Congifured Identity Center Instance (Don't Need to Execute the Following Commands):

If you need to delete a previously deployed Organization-level instance:

```
   aws organizations delete-organization
```

To delete Account-level Instance:

```
   # retrieve the instance ARN
   aws sso-admin list-instances

   # delete the account-level instance using retrieved ARN
   aws sso-admin delete-instance --instance-arn arn:aws:sso:<region>:<account-id>:instance/<instance-id>
```

### Using your Existing IAM Identity Center

If you have an existing IAM Identity Center instance (either in your current AWS account or in another accessible AWS account), you can reuse it instead of creating a new one. To integrate your existing instance with SageMaker Unified Studio and Datazone modules, you will need to store the user group mappings in AWS Systems Manager Parameter Store.

There are two methods to configure user groups for your deployment: Discovery (DYO) and Manual (BYO).

#### 1. Discovery Method (Discover-your-own IDC)

This method automatically discovers and maps existing IAM Identity Center groups to required roles.

The command expects four user groups in your IAM Identity Center:

- Admin
- Domain Owner
- Project Owner
- Project Contributor

##### Automatic User Assignment

The command handles various scenarios to ensure critical roles are always populated:

1. **For Admin, Domain Owner, and Project Owner groups:**
   - If the group doesn't exist: The deployer's email (caller identity) is automatically added
   - If the group exists but is empty: The deployer's email is automatically added
   - If the group exists and has users: The existing users are preserved
2. **For Project Contributor group:**
   - If the group doesn't exist: An empty list is created
   - If the group exists but is empty: The list remains empty
   - If the group exists and has users: The existing users are preserved

##### Why This Matters

This automatic user assignment is crucial because:

- Domain creation for SageMaker Unified Studio and Amazon Datazone requires at least one Domain Owner
- Projects creation requires at least one Project Owner
- By automatically adding the deployer to these roles when needed, the command ensures these requirements are met and prevents deployment failures

To use this method:

```
make deploy-dyo-idc
```

#### 2. Manual Method (Bring-your-own IDC)

This method allows manual configuration of user groups and their members, ideal for scenarios where:

- Your IAM Identity Center doesn't have groups matching our required group names
- You want to specify custom group memberships without modifying existing IAM Identity Center groups
- You prefer direct control over user assignments

#### Requirements

- A valid Identity Store ID
- At least one valid email for Domain Owner group
- At least one valid email for Project Owner group
- Admin and Project Contributor groups can be empty

To use this method:

```
make deploy-byo-idc
```

The command WILL:

- Prompt for your Identity Store ID
- Request email addresses for each group (Admin, Domain Owner, Project Contributor, Project Owner)
- Allow multiple emails per group (using comma or space separation)
- Validate email address formats
- Show a preview of the complete configuration
- Create/update the SSM parameter after confirmation

The command will NOT perform these critical validations:

- Verify if the provided Identity Store ID exists or is valid
- Check if the entered email addresses belong to actual users in your IAM Identity Center

⚠️ **User Responsibility:**

1. Ensure the Identity Store ID is correct
2. Verify all provided email addresses correspond to existing users in your IAM Identity Center

❗ **Warning:** Providing incorrect information (invalid Identity Store ID or non-existent users) will not cause immediate errors but will lead to failures in subsequent deployment steps when the system attempts to assign permissions to these users.

## 3. **Sagemaker Domain**

This module deploys a Sagemaker Domain for SageMaker Unified Studio, enabling relevant blueprints, and creating project profiles with relevant blueprints.

#### To deploy the module:

```
make deploy-domain-prereq
make deploy-domain
```

| Target               | Result                          | Verification                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| -------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| deploy-domain        | Deploy Domain                   | Following Sagemaker resources are created <br> 1. Sagemaker domain called _Corporate_ <br> 2. Sagemaker blueprints are enabled under _Corporate_ domain <br> 3. Three Sagemaker project profiles are configured under _Corporate_ domain <br> 4. Login to Sagemaker Unified Studio for _Corporate_ domain using various user credentials created in _IAM Identity Center_ section and confirm that you are able to open the domain. When you login to Sagemaker Unified Studio, it will be ask you to enter usename and one-time password you had created in the _IAM Identity Center_ and it will ask you change the password. Please use a password with letter, numbers and special charaters and store the password in a file using your favorite editor. |

---

## 4. **Sagemaker Projects**

This module deploys two Sagemaker projects, one for **Producer** and one for **Consumer**. When you execute the "deploy-producer-project" or "deploy-consumer-project" make target, it will launch 4 cloud formation stacks for each project one after other. After executing the "deploy-producer-project" make target, please open Cloud Formation console and monitor the 4 cloud formation stacks get created and completed. Only then, proceed to execute the "deploy-consumer-project" make target and monitor the 4 cloud formation stacks get created and completed. Only then, proceed to execute the remaining 2 make targets "extract-producer-info" and "extract-consumer-info".

#### To deploy the module:

```
make deploy-project-prereq
make deploy-producer-project (wait for 4 cloud formation stacks to complete)
make deploy-consumer-project (wait for 4 cloud formation stacks to complete)
make extract-producer-info
make extract-consumer-info
```

| Target                  | Result                                       | Verification                                                                                                                                                                                                                       |
| ----------------------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| deploy-project-prereq   | Provisions Pre-requisites for Projects       | Provisions Sagemaker foundational resources                                                                                                                                                                                        |
| deploy-producer-project | Provisions Producer Project                  | Provisions following Sagemaker projects: <br> 1. Producer <br> 2. Login to Sagemaker Unified Studio using "Project Owner" user with username containing "powner" and confirm that you see the producer project and you can open it |
| deploy-consumer-project | Provisions Consumer Project                  | Provisions following Sagemaker projects: <br> 1. Consumer <br> 2. Login to Sagemaker Unified Studio using "Project Owner" user with username containing "powner" and confirm that you see the consumer project and you can open it |
| extract-producer-info   | Extracts id and role of the project producer | Provisions following SSM Parameters: <br> 1. /{app}/{env}/sagemaker/producer/id <br> 2. /{app}/{env}/sagemaker/producer/role <br> 3. /{app}/{env}/sagemaker/producer/role-name                                                     |
| extract-consumer-info   | Extracts id and role of the project consumer | Provisions following SSM Parameters: <br> 1. /{app}/{env}/sagemaker/consumer/id <br> 2. /{app}/{env}/sagemaker/consumer/role <br> 3. /{app}/{env}/sagemaker/consumer/role-name                                                     |

---

## 5. **Glue Iceberg Jar File**

This module downloads and deploys the glue runtime jar file that is needed for glue jobs to interact with Iceberg tables.

#### To deploy the module:

```
make deploy-glue-jars
```

| Target           | Result               | Verification                                                                                                                                |
| ---------------- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| deploy-glue-jars | Deploy Glue jar file | Verify that the iceberg jar file "s3-tables-catalog-for-iceberg-runtime-0.1.5.jar" is uploaded to S3 bucket "{app}-{env}-glue-jars-primary" |

---

## 6. **Lake Formation**

This module deploys lake formation configuration to create Glue catalog for s3tables and registers s3table bucket location with lake formation using lake formation service role.

#### To deploy the module:

```
make create-glue-s3tables-catalog
make register-s3table-catalog-with-lake-formation
```

| Target                                       | Result                                          | Verification                                                                                                                                                                                                                   |
| -------------------------------------------- | ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| create-glue-s3tables-catalog                 | Create Glue catalog for S3tables                | Verify that the following Glue catalog is created in Lakeformation by opening "Data Catalog -> Catlogs": <br> 1. s3tablescatalog                                                                                               |
| register-s3table-catalog-with-lake-formation | Registers S3 table location with lake formation | Verify that the s3table location is registered with Lakeformation by opening "Administration->Data lake locations" and finding an entry for the following data lake location: <br> 1. s3://tables:{region}:{account}:bucket/\* |

## 7. **Athena**

This module deploys an athena workgroup.

#### To deploy the module:

```
make deploy-athena
```

| Target        | Result                  | Verification                                                               |
| ------------- | ----------------------- | -------------------------------------------------------------------------- |
| deploy-athena | Create Athena workgroup | Verify following Athena workgroup is created <br> 1. {app}-{env}-workgroup |

---

## 8. **Data Lakes**

The solution allows the user to deploy 6 data lakes, 1) billing data lake 2) inventory data lake, 3) splunk data lake 4) price data lake 5) trade data lake 6) stocks data lake. Although we recommend that the user deploys all the 6 data lakes, the user does not need to deploy all the 6 data lakes. If the user wishes to deploy only one data lake to explore the functionalities of DAIVI solution, then we recommend deploying the billing data lake at the minimum.

## 9. **FinOps Billing S3-Glue-S3 Data Lake - Static**

Billing Data Lake is divided into 3 modules. 1) Static - Glue Jobs for Tables with Static Schema 2) Dynamic - Glue Jobs for Tables with Dynamic Schema and 3) CUR - Setting up CUR reports after 24 hours of enabling cost explorer in Billing and Cost Management.

This module sets up the Glue Jobs for Tables with Static Schema.

#### To deploy the module:

```
make deploy-finops-billing-s3-glue-s3
make grant-default-database-permissions
make drop-default-database
make start-finops-billing-s3-glue-s3-hive-job 
make start-finops-billing-s3-glue-s3-iceberg-static-job 
make start-finops-billing-s3-glue-s3table-job 
make grant-lake-formation-finops-billing-s3-glue-s3table-catalog
make start-finops-billing-s3-glue-s3-hive-data-quality-ruleset (wait for finops-billing-s3-glue-s3-hive glue job to complete before running this)
```

| Target                                        | Result                                                                            | Verification                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| --------------------------------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| deploy-finops-billing-s3-glue-s3                                | Deploy billing infrastructure                                                     | Following S3 buckets are created: <br> 1. {account}-{app}-{env}-finops-billing-s3-glue-s3-data <br> 2. {account}-{app}-{env}-finops-billing-s3-glue-s3-hive <br> 3. {account}-{app}-{env}-finops-billing-s3-glue-s3-iceberg <br><br> Following S3 table bucket is created: <br> 1. finops-billing-s3-glue-s3table <br> <br> Following Glue database is created: <br> 1. finops_billing_s3_glue_s3 <br><br> Following Glue tables are created: <br> 1. finops_billing_s3_glue_s3_hive <br> 2. finops_billing_s3_glue_s3_iceberg_static <br><br> Following Glue jobs are created: <br> 1. finops-billing-s3-glue-s3-hive <br> 2. finops-billing-s3-glue-s3-iceberg-static <br> 3. finops-billing-s3-glue-s3-iceberg-dynamic <br> 4. finops-billing-s3-glue-s3table |
| grant-default-database-permissions            | Grant deployment role permission to drop "default" database                       | Verify that the deployment role is granted permission to drop "default" database                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| drop-default-database                         | Drop "default" Glue database                                                      | Verify that the "default" Glue database is dropped                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| start-finops-billing-s3-glue-s3-hive-job                        | Run the finops-billing-s3-glue-s3-hive glue job                                         | Verify that the glue job starts. wait for the glue job to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| start-finops-billing-s3-glue-s3-iceberg-static-job              | Run the finops-billing-s3-glue-s3-iceberg-static glue job                               | Verify that the glue job starts. wait for the glue job to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| start-finops-billing-s3-glue-s3table-job                     | Run the finops-billing-s3-glue-s3table job                                           | Verify that the glue job starts. wait for the glue job to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| grant-lake-formation-finops-billing-s3-glue-s3table-catalog | Grant Lake Formation permissions to inventory S3 table catalog                    | Verify that the permission is added Lakeformation                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| start-finops-billing-s3-glue-s3-hive-data-quality-ruleset       | Execute ruleset associated with finops_billing_s3_glue_s3_hive Glue table | Verify that the ruleset is executed                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |

---

## 10. **FinOps Billing S3-Glue-S3 Data Lake - Dynamic**

Billing Data Lake is divided into 3 modules. 1) Static - Glue Jobs for Tables with Static Schema 2) Dynamic - Glue Jobs for Tables with Dynamic Schema and 3) CUR - Setting up CUR reports after 24 hours of enabling cost explorer report.

This module sets up the Glue Jobs for Tables with Dynamic Schema.

#### To deploy the module:

```
make upload-billing-s3-glue-s3-iceberg-dynamic-report-1 (wait for billing-workflow to start and complete)
make upload-billing-s3-glue-s3-iceberg-dynamic-report-2 (wait for billing-workflow to start and complete)
make grant-lake-formation-billing-s3-glue-s3-iceberg-dynamic
```

| Target                                       | Result                                                                                                                                                    | Verification                                                                                                                                                                                                                       |
| -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| upload-billing-s3-glue-s3-iceberg-dynamic-report-1              | Uploads the first cost and usage report to an S3 bucket for triggering a dynamic Glue workflow for billing data processing finops-billing-s3-glue-s3-workflow   | Verify that the following Glue workflow is executed: <br> 1. {app}-{env}-billing-workflow <br> <br> After the glue workflow completes, confirm creation of the following Glue table: <br> 1. finops_billing_s3_glue_s3_iceberg_dynamic |
| upload-billing-s3-glue-s3-iceberg-dynamic-report-2              | Uploads the second cost and usage report to an S3 bucket for triggering a dynamic Glue workflow for billing data processing finops-billing-s3-glue-s3-workflow | Verify that the following Glue workflow is executed: <br> 1. finops-billing-s3-glue-s3-workflow                                                                                                                                         |
| grant-lake-formation-billing-s3-glue-s3-iceberg-dynamic | Grants lake formation permissions to an admin role for accessing and managing the Iceberg table finops_billing_s3_glue_s3_iceberg_dynamic                     | Verify that the Lakeformation permisison is granted                                                                                                                                                                                |

---

## 11. **FinOps Billing S3-Glue-S3 Data Lake - CUR**

> [!CAUTION]
> Please execute "Billing Set UP" as outlined below and then wait for at least 24 hours before deploying this module, due to the nature of Billing and Cost Management. In the meantime, you can proceed to the [the next section](#12-inventory-data-lake---static).

Billing Data Lake is divided into 3 modules. 1) Static - Glue Jobs for Tables with Static Schema 2) Dynamic - Glue Jobs for Tables with Dynamic Schema and 3) CUR - Setting up CUR reports after 24 hours of enabling cost explorer report.

This module sets up the Cost and Usage Report.

**Billing Set Up**: You will need to enable Cost Explorer in Billing and Cost Management before you can configure it to generate daily CUR reports in a S3 bucket. If you have not done this for your account already, please open "Billing and Cost Management" and click on "Cost Explorer" under "Cost and Usage Analysis". When you visit this page for the first time it will show a welcome message "Welcome to AWS Cost Management. Since this is your first visit, it will take some time to prepare your cost and usage data. Please check back in 24 hours."

#### To deploy the module:

```
make activate-finops-s3-glue-s3-cost-allocation-tags
make deploy-finops-s3-glue-s3-billing-cur
```

| Target                        | Result                                                                                                 | Verification                                                                      |
| ----------------------------- | ------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| activate-finops-s3-glue-s3-cost-allocation-tags | Activate cost allocation tag in AWS Cost Explorer                                                      | Verify that the cost allocation tags are activated in Billing and Cost Management |
| deploy-finops-s3-glue-s3-billing-cur            | Deploy an AWS Cost and Usage Report (CUR) configuration to generate Cost and Usage Reports (CUR) daily | Verify that Cost and Usage Report (CUR) is created in Billing and Cost Management |

## 12. **FinOps Inventory S3-Glue-S3 Data Lake - Static**

Inventory Data Lake is divided into 2 modules. 1) Static - Glue Jobs for Tables with Static Schema 2) Dynamic - Glue Jobs for Tables with Dynamic Schema

This module sets up the Glue Jobs for Tables with Static Schema.

#### To deploy the module:

```
make deploy-finops-inventory-s3-glue-s3
make grant-default-database-permissions
make drop-default-database
make start-finops-inventory-s3-glue-s3-hive-job 
make start-finops-inventory-s3-glue-s3-iceberg-static-job 
make start-finops-inventory-s3-glue-s3table-job 
make grant-lake-formation-inventory-s3-glue-s3table-catalog
make start-inventory-s3-glue-s3-hive-data-quality-ruleset (wait for finops-inventory-s3-glue-s3-hive glue job to complete before running this)
```

| Target                                          | Result                                                                                | Verification                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| ----------------------------------------------- | ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| deploy-finops-inventory-s3-glue-s3                                | Deploy inventory infrastructure                                                       | Following S3 buckets are creatd: <br> 1. {account}-{app}-{env}-finops-inventory-s3-glue-s3-source <br> 2. {account}-{app}-{env}-finops-inventory-s3-glue-s3-target <br> 3. {account}-{app}-{env}-finops-inventory-s3-glue-s3-hive <br> 4. {account}-{app}-{env}-finops-inventory-s3-glue-s3-iceberg  <br><br> Following S3 table bucket is created: <br> 1. finops-inventory-s3-glue-s3table <br> <br> Following Glue database is created: <br> 1. finops_inventory_s3_glue_s3 <br><br> Following Glue tables are created <br> 1. finops_inventory_s3_glue_s3_hive <br> 2. finops_inventory_s3_glue_s3_iceberg_static <br><br> Following Glue jobs are created: <br> 1. finops-inventory-s3-glue-s3-hive <br> 2. finops-inventory-s3-glue-s3-iceberg-static <br> 3. finops-inventory-s3-glue-s3-iceberg-dynamic <br> 4. finops-inventory-s3-glue-s3table |
| grant-default-database-permissions              | Grant deployment role permission to drop "default" Glue database                      | Verify that the deployment role is granted permission to drop "default" database                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| drop-default-database                           | Drops "default" Glue database                                                         | Verify that the "default" Glue database is dropped                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| start-finops-inventory-s3-glue-s3-hive-job                        | Run the finops-inventory-s3-glue-s3-hive glue job                                           | Verify that the glue job starts. wait for the glue job to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| start-finops-inventory-s3-glue-s3-iceberg-static-job              | Run the finops-inventory-s3-glue-s3-iceberg-static glue job                                 | Verify that the glue job starts. wait for the glue job to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| start-finops-inventory-s3-glue-s3table-job                     | Run the finops-inventory-s3-glue-s3table job                                             | Verify that the glue job starts. wait for the glue job to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| grant-lake-formation-inventory-s3-glue-s3table-catalog | Grant Lake Formation permissions to inventory S3 table catalog                        | Verify that the permission is added Lakeformation                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| start-inventory-s3-glue-s3-hive-data-quality-ruleset       | Execute ruleset associated with finops_inventory_s3_glue_s3_hive Glue table | Verify that the ruleset is executed                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |

---

## 13. **FinOps Inventory S3-Glue-S3 Data Lake - Dynamic**

Inventory Data Lake is divided into 2 modules. 1) Static - Glue Jobs for Tables with Static Schema 2) Dynamic - Glue Jobs for Tables with Dynamic Schema and

This module sets up the Glue Jobs for Tables with Dynamic Schema.

#### To deploy the module:

```
make upload-inventory-s3-glue-s3-iceber-dynamic-report-1 (wait for inventory-workflow to start and complete)
make upload-inventory-s3-glue-s3-iceber-dynamic-report-2 (wait for inventory-workflow to start and complete)
make grant-lake-formation-inventory-s3-glue-s3-iceberg-dynamic
```

| Target                                         | Result                                                                                                                                                   | Verification                                                                                                                                                                                                                          |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| upload-inventory-s3-glue-s3-iceber-dynamic-report-1              | Uploads the first inventory report to an S3 bucket for triggering a dynamic Glue workflow for inventory data processing finops-inventory-s3-glue-s3-workflow  | Verify that the following Glue workflow is executed: <br> 1. finops-inventory-s3-glue-s3-workflow <br> <br> After the glue workflow completes, confirm creation of the following Glue table: <br> 1.finops_inventory_s3_glue_s3_iceberg_dynamic |
| upload-inventory-s3-glue-s3-iceber-dynamic-report-2              | Uploads the second inventory report to an S3 bucket for triggering a dynamic Glue workflow for inventory data processing finops-inventory-s3-glue-s3-workflow | Verify that the following Glue workflow is executed: <br> 1. finops-inventory-s3-glue-s3-workflow                                                                                                                                          |
| grant-lake-formation-inventory-s3-glue-s3-iceberg-dynamic | Grants lake formation permissions to an admin role for accessing and managing the Iceberg table finops_inventory_s3_glue_s3_iceberg_dynamic                  | Verify that the Lakeformation permisison is granted                                                                                                                                                                                   |

---

## 14. **FinOps Splunk S3-Glue-S3 Data Lake**

This module deploys splunk datalake.

#### To deploy the module:

```
make deploy-finops-usage-splunk-glue-s3 (wait for EC2 instance's Status check to show '3/3 checks passed' before proceeding, recommended to wait at least 5 minutes before proceeding)
make grant-default-database-permissions
make drop-default-database
make start-finops-usage-splunk-glue-s3-iceberg-job 
make start-finops-usage-splunk-glue-s3table-job 
make grant-lake-formation-finops-usage-splunk-glue-s3table-catalog
```

| Target                                       | Result                                                        | Verification                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| -------------------------------------------- | ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| deploy-finops-usage-splunk-glue-s3                                | Deploy splunk application to an EC2 instance and configure it | Verify that the following EC2 instance is created. <br> 1. {app}_{env}-splunk-instance <br> 2. Give 10 minutes for Splunk instance to be operational on EC2, and then execute the remaining make targets <br><br> Following S3 buckets are creatd: <br> 1. {account}-{app}-{env}-finops-usage-splunk-gule-s3-iceberg  <br><br> Following S3 table bucket is created: <br> 1. finops-usage-splunk-glue-s3table <br> <br> Verify that following Glue database is created: <br> 1. finops_usage_splunk_glue_s3 <br><br> Following Glue tables are created: <br> 1. finops_usage_splunk_glue_s3_iceberg <br><br> Following Glue jobs are created: <br> 1. finops-usage-splunk-glue-s3-iceberg <br> 2. finops-usage-splunk-glue-s3table |
| grant-default-database-permissions           | Grant deployment role permission to drop "default" database   | Verify that the deployment role is granted permission to drop "default" database                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| drop-default-database                        | Drop "default" Glue database                                  | Verify that the "default" Glue database is dropped                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| start-finops-usage-splunk-glue-s3-iceberg-job              | Run finops-usage-splunk-glue-s3-iceberg Glue job                | Verify that the glue job starts. wait for the glue job to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| start-finops-usage-splunk-glue-s3table-job                     | Run finops-usage-splunk-glue-s3table Glue job                | Verify that the glue job starts. wait for the glue job to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| grant-lake-formation-finops-usage-splunk-glue-s3table-catalog | Grant Lake Formation permissions to Splunk S3 table catalog   |

---

## 15. **Equity Price S3-Glue-S3 Data Lake**

This module deploys price datalake.

#### To deploy the module:

```
make deploy-equity-price-s3-glue-s3
make grant-default-database-permissions
make drop-default-database
make start-equity-price-s3-glue-s3-hive-job
make start-equity-price-s3-glue-s3-iceberg-job
make start-equity-price-s3-glue-s3table-job
make grant-lake-formation-equity-price-s3-glue-s3table-catalog
make start-equity-price-s3-glue-s3-hive-data-quality-ruleset (wait for equity-price-s3-glue-s3-hive glue job to complete before running this)
```

| Target                                | Result                                                                        | Verification                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| ------------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| deploy-equity-price-s3-glue-s3                          | Deploy price infra                                                            | Following buckets are created <br> 1. {account}-{app}-{env}-equity-price-s3-glue-s3-data <br> 2. {account}-{app}-{env}-equity-price-s3-glue-s3-hive <br> 3. {account}-{app}-{env}-equity-price-s3-glue-s3-iceberg <br> <br> Following s3 table bucket is created <br> 1. equity-price-s3-glue-s3table <br> <br> Following glue tables are created <br> 1. equity_price_s3_glue_s3_hive <br> 2. equity_price_s3_glue_s3_iceberg <br> <br> Following glue jobs are created <br> 1. equity-price-s3-glue-s3-hive <br> 2. equity-price-s3-glue-s3-iceberg <br> 3. equity-price-s3-glue-s3table <br> |
| grant-default-database-permissions            | Grant deployment role permission to drop "default" database                       | Verify that the deployment role is granted permission to drop "default" database                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| drop-default-database                         | Drop "default" Glue database                                                      | Verify that the "default" Glue database is dropped                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| start-equity-price-s3-glue-s3-hive-job                  | Run equity-price-s3-glue-s3-hive glue job                                           | Verify that glue job starts and wait for it to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| start-equity-price-s3-glue-s3-iceberg-job               | Run equity-price-s3-glue-s3-iceberg glue job                                        | Verify that glue job starts and wait for it to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| start-equity-price-s3-glue-s3table-job               | Run equity-price-s3-glue-s3table glue job                                        | Verify that glue job starts and wait for it to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| start-equity-price-s3-glue-s3-hive-data-quality-ruleset | Execute ruleset associated with equity_price_s3_glue_s3_hive glue table | Verify that  the ruleset is executed                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |

## 16. **Equity Trade S3-Glue-S3 Data Lake**

This module deploys trade datalake.

#### To deploy the module:

```
make deploy-equity-trade-s3-glue-s3
make grant-default-database-permissions
make drop-default-database
make start-equity-trade-s3-glue-s3-hive-job
make start-equity-trade-s3-glue-s3-iceberg-job
make start-equity-trade-s3-glue-s3table-job
make grant-lake-formation-equity-trade-s3-glue-s3table-catalog
make start-equity-trade-s3-glue-s3-hive-data-quality-ruleset (wait for equity-trade-s3-glue-s3-hive glue job to complete before running this)
```

| Target                                | Result                                                                        | Verification                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| ------------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| deploy-equity-trade-s3-glue-s3                          | Deploy trade infra                                                            | Following buckets are created <br> 1. {account}-{app}-{env}-equity-trade-s3-glue-s3-data <br> 2. {account}-{app}-{env}-equity-trade-s3-glue-s3-hive <br> 3. {account}-{app}-{env}-equity-trade-s3-glue-s3-iceberg <br> <br> Following s3 table bucket is created <br> 1. equity-trade-s3-glue-s3table <br> <br> Following glue tables are created <br> 1. equity_trade_s3_glue_s3_hive <br> 2. equity_trade_s3_glue_s3_iceberg <br> <br> Following glue jobs are created <br> 1. equity-trade-s3-glue-s3-hive <br> 2. equity-trade-s3-glue-s3-iceberg <br> 3. equity-trade-s3-glue-s3table <br> |
| grant-default-database-permissions            | Grant deployment role permission to drop "default" database                       | Verify that the deployment role is granted permission to drop "default" database                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| drop-default-database                         | Drop "default" Glue database                                                      | Verify that the "default" Glue database is dropped                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| start-equity-trade-s3-glue-s3-hive-job                  | Run equity-trade-s3-glue-s3-hive glue job                                           | Verify that glue job starts and wait for it to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| start-equity-trade-s3-glue-s3-iceberg-job               | Run equity-trade-s3-glue-s3-iceberg glue job                                        | Verify that glue job starts and wait for it to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| start-equity-trade-s3-glue-s3table-job               | Run equity-trade-s3-glue-s3table glue job                                        | Verify that glue job starts and wait for it to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| start-equity-trade-s3-glue-s3-hive-data-quality-ruleset | Execute ruleset associated with equity_trade_s3_glue_s3_hive glue table | Verify that  the ruleset is executed                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |

## 17. **Equity Trade MSK-Glue-S3 Data Lake**

This module deploys trade datalake.

#### To deploy the module:

```
make deploy-equity-trade-msk-glue-s3
make start-equity-trade-msk-glue-s3-job
make run-equity-trade-msk-glue-s3-test-harness
```

| Target                 | Result                        | Verification                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| ---------------------- | ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| deploy-equity-trade-msk-glue-s3           | Deploy trade infra            | Following buckets are created <br> 1. {account}-{app}-{env}-equity-trade-msk-glue-s3-hive <br> 2. {account}-{app}-{env}-equity-trade-msk-glue-s3-iceberg <br> <br> <br> <br> Following glue database is created <br> 1. equity_trade_msk_glue_s3 <br> <br> Following glue tables are created <br> 1. equity_trade_s3_glue_s3_hive <br> 2. equity_trade_s3_glue_s3_iceberg <br> <br> Following glue connection is created <br> equity-trade-msk-glue-s3-msk-glue-connection <br> <br> following glue job is created <br> equity-trade-msk-glue-s3-job |
| start-equity-trade-msk-glue-s3-job        | Run the equity-trade-msk-glue-s3 | Verify that the glue job starts. wait for the glue job to complete                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| run-equity-trade-msk-glue-s3-test-harness | Run the {app}-{env}-msk-producer-lambda   | Verify that the lambda runs for 1 minutes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |

## 18. **Equity Trade MSK-Flink-MSK Data Lake**

#### Prerequisites

- Java(Version 11)
- mvn (Maven)

This module deploys equity trade datalake. Current implementation doesn't store data to Glue catalog. The stock streaming data is processed via Amazon Managed Flink application and push outbound to MSK cluster. In future update, the data will also be stored in Glue catalog.

#### To deploy the module:

```
make build-equity-trade-msk-flink-msk-app
make deploy-equity-trade-msk-flink-msk
make run-equity-trade-msk-flink-msk-test-harness
```

| Target                 | Result                            | Verification                                                                                                                                                                                                                                                                                                                                                                                        |
| ---------------------- | --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| build-equity-trade-msk-flink-msk-app        | build the jar file                | verify msf-1.0-SNAPSHOT.jar file exists at iac/roots/datalakes/stocks/java-app/msf/target                                                                                                                                                                                                                                                                                                           |
| deploy-equity-trade-msk-flink-msk          | deploys the trade streaming infra | Verify following resources are created <br> 1. Amazon managed flink application --> equity-trade-msk-flink-msk <br> 2. {app}-{env}-msk-producer-lambda <br> 3. EC2 instance deployed with kafka ui tool --> {app}-{env}-msk-client. <br> To view the MSK cluster topics and messages, update the ec2 security group to allow traffic from your public ip and access the UI on EC2 public ip on port 9000 |
| run-equity-trade-msk-flink-msk-test-harness | Run the {app}-{env}-msk-producer-lambda       | Verify that the lambda runs for 1 minutes                                                                                                                                                                                                                                                                                                                                                           |

## 19. **Equity Order DynamoDB-ZeroETL-S3 Data Lake**

This module configures zero etl integration between Amazon DynamoDb and Amazon SageMaker Lakehouse. DynamoDB zero integration eliminates the need to build custom data movement pipelines by automatically replicating DynamoDB data to Amazon Sagemaker Lakehouse.

#### To deploy the module:

```
make deploy-equity-order-dd-zetl-s3-prereq
make deploy-equity-order-dd-zetl-s3
```

| Target                            | Result                                                         | Verification                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| --------------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| deploy-equity-order-dd-zetl-s3-prereq | Creats S3 bucket to store the data needed to populate DynamoDB | Following S3 buckets are created: <br> 1. {account}-{app}-{env}-equity-order-dd-zetl-s3-data <br>                                                                                                                                                                                                                                             |
| deploy-equity-order-dd-zetl-s3             | Uploads equity orders data to s3 bucket                        | Verify that {app}-{env}-equity-orders-db-table dynamodb table is created with data populated <br> <br> Verify the following Glue database is created: equity_order_dd_zetl_s3 <br> <br> Verify the following zero etl integration is created and is in active state: {app}-{env}-ddb-glue-zetl-integration <br> <br> Verify the following Glue database table is created: {app}_{env}_equity_orders_db_table (Wait for few mintues for the initial integration to complete) |

## 20. **Sagemaker Project Configuration**

This module configures the Sagemaker Producer and Consumer Projects to load the Data Lakes into Lakehouse by granting project roles lake house permissions to the data lakes.

#### To deploy the module:

```
make deploy-project-config
make finops-billing-s3-glue-s3-grant-producer-s3tables-catalog-permissions
make finops-inventory-s3-glue-s3-grant-producer-s3tables-catalog-permissions
make finops-usage-splunk-glue-s3-grant-producer-s3tables-catalog-permissions
make equity-price-s3-glue-s3-grant-producer-s3tables-catalog-permissions
make equity-trade-s3-glue-s3-grant-producer-s3tables-catalog-permissions
```

| Target                                                | Result                                                                                                                   | Verification                                                                                                        |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------- |
| deploy-project-config                                 | Deploy Project Config                                                                                                    | Grants Lake Formation permissions to the producer project role and consumer project role to access the 3 data lakes |
| finops-billing-s3-glue-s3-grant-producer-s3tables-catalog-permissions   | Grants Lake Formation access permissions to a project producer role for querying billing data through S3 table catalog   | Verify that the project role is granted lake formation permissions                                                  |
| finops-inventory-s3-glue-s3-grant-producer-s3tables-catalog-permissions | Grants Lake Formation access permissions to a project producer role for querying inventory data through S3 table catalog | Verify that the project role is granted lake formation permissions                                                  |
| finops-usage-splunk-glue-s3-grant-producer-s3tables-catalog-permissions    | Grants Lake Formation access permissions to a project producer role for querying splunk data through S3 table catalog    | Verify that the project role is granted lake formation permissions                                                  |
| equity-price-s3-glue-s3-grant-producer-s3tables-catalog-permissions     | Grants Lake Formation access permissions to a project producer role for querying price data through S3 table catalog     | Verify that the project role is granted lake formation permissions                                                  |
| equity-trade-s3-glue-s3-grant-producer-s3tables-catalog-permissions     | Grants Lake Formation access permissions to a project producer role for querying trade data through S3 table catalog     | Verify that the project role is granted lake formation permissions                                                  |
---

## 21. **Datazone Domain and Projects**

This module deploys datazone domain and datazone project.

#### To deploy the module:

```
make deploy-datazone-domain
make deploy-datazone-project-prereq (wait for 5 minutes for the environment to be created and activated)
make deploy-datazone-producer-project
make deploy-datazone-consumer-project
make deploy-datazone-custom-project
```

| Target                           | Result                                | Verification                                                                                                                                                             |
| -------------------------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| deploy-datazone-domain           | Deploy Datazone Domain                | Verify that a Datazone domain **Exchange** is created                                                                                                                    |
| deploy-datazone-project-prereq   | Deploy Datazone Project Prerequisites | Verify that Datazone project prerequisites are created **producer_project**, **consumer_project** and **custom_project** are created in the Datazone domain **Exchange** |
| deploy-datazone-producer-project | Deploy Datazone Producer Project      | Verify that Datazone **Producer** project is created in the Datazone domain **Exchange**                                                                                 |
| deploy-datazone-consumer-project | Deploy Datazone Consumer Project      | Verify that Datazone **Consumer** project is created in the Datazone domain **Exchange**                                                                                 |
| deploy-datazone-custom-project   | Deploy Datazone Consumer Project      | Verify that Datazone **Custom** project is created in the Datazone domain **Exchange**                                                                                   |

---

## 22. **Snowflake Connection**

This module deploys a Snowflake connection for SageMaker Lakehouse, enabling data access between SageMaker Studio UI and Snowflake.

#### Prerequisites

Before deploying this module, you need:

1. A Snowflake account with appropriate access credentials
2. Snowflake objects (database, warehouse, table, schema) must be created and accessible. For detailed instructions on creating and setting up free trial Snowflake for use with SageMaker, refer to [Amazon SageMaker with Snowflake as datasource](https://github.com/aws-samples/amazon-sagemaker-w-snowflake-as-datasource/blob/main/snowflake-instructions.md).
> [!IMPORTANT]
> All Snowflake object names (database, schema, table, columns names, warehouse name) must be in lowercase due to current limitations in Athena's Snowflake connector.

For information about Athena-Snowflake connector limitations, see [AWS documentation](https://docs.aws.amazon.com/athena/latest/ug/connectors-snowflake.html#connectors-snowflake-limitations).

#### Snowflake Setup Guide

Before deploying the connection, you need to ensure your Snowflake objects are properly configured with lowercase names. If you don't have appropriate lowercase object or would like to set them up for this module deployment, follow these steps in your Snowflake account:

1. **Login to Snowflake Web Interface (make sure you are logged in as `ACCOUNTADMIN`)**:

   - Navigate to your Snowflake account URL (e.g., `https://youraccount.snowflakecomputing.com`)
   - Login with your admin credentials

2. **Create Lowercase Database (For all commands below, open a Snowflake worksheet and execute)**:

   ```sql
   CREATE DATABASE IF NOT EXISTS "daivi_db";
   ```

3. **Use the Database**:

   ```sql
   USE DATABASE "daivi_db";
   ```

4. **Create Lowercase Schema**:

   ```sql
   CREATE SCHEMA IF NOT EXISTS "daivi_schema";
   ```

5. **Use the Schema**:

   ```sql
   USE SCHEMA "daivi_schema";
   ```

6. **Create Sample Table with Lowercase Name**:

   ```sql
   CREATE OR REPLACE TABLE "daivi_sample_table" (
   "id" INTEGER,
   "name" STRING,
   "value" FLOAT
   );
   ```

7. **Insert Sample Data into Table**:

   ```sql
   INSERT INTO "daivi_sample_table" VALUES
   (1, 'item1', 10.5),
   (2, 'item2', 20.3),
   (3, 'item3', 30.7);
   ```

8. **Create Lowercase Warehouse**:
   ```sql
   CREATE WAREHOUSE IF NOT EXISTS "daivi_wh"
   WITH WAREHOUSE_SIZE = 'XSMALL'
   AUTO_SUSPEND = 60
   AUTO_RESUME = TRUE;
   ```

9. **Highlight all of the fields below and test the query**:
   ```sql
   USE WAREHOUSE "daivi_wh";
   USE DATABASE "daivi_db";
   USE SCHEMA "daivi_schema";
   SELECT * FROM "daivi_sample_table";
   ```

If you followed steps above to create your snowflake object, then use these lowercase values in the next steps of the deployment:

- Database: `daivi_db`
- Warehouse: `daivi_wh`
- Schema: `daivi_schema`

#### Required Information

When running the deployment, you will be prompted to provide the following information:

1. **Snowflake Connection Name** - Name for the connection (defaults to 'snowflake' if not specified)
2. **Snowflake Username** - Your Snowflake account username
3. **Snowflake Password** - Your Snowflake account password
4. **Snowflake Host** - Your Snowflake account URL (e.g., `youraccount.snowflakecomputing.com`)
5. **Snowflake Port** - Port number for Snowflake connection (defaults to 443 if not specified)
6. **Snowflake Warehouse** - Name of the warehouse to use (must be lowercase)
7. **Snowflake Database** - Name of the database to connect to (must be lowercase)
8. **Snowflake Schema** - Name of the schema within the database (must be lowercase)

These credentials will be securely stored in AWS Secrets Manager and used by the DataZone connection.

#### To deploy the module:

```
make deploy-snowflake-connection
```

| Target                      | Result                                                              | Verification                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| --------------------------- | ------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| deploy-snowflake-connection | Creates a DataZone connection to Snowflake for the Producer project | Verify that the following resources are created: <br> 1. AWS Secrets Manager secret containing Snowflake credentials: {app}-{env}-snowflake-credentials <br> 2. Lambda function to manage the DataZone connection: {app}-{env}-datazone-conn-lambda <br> 3. IAM role for the Lambda function: {app}-{env}-lambda-datazone-conn-role <br> 4. SNS topic for Lambda DLQ: {app}-{env}-datazone-conn-lambda-dlq <br> 5. Login to SageMaker DataZone Producer project and verify the Snowflake connection appears in the connections list |

#### Post-Deployment Verification

After successful deployment, you should verify that the Snowflake connection is properly established:

1. Login to SageMaker Unified Studio using the Project Owner credentials (username containing "powner", e.g., `lois-lanikini-powner@example.com`)
2. Navigate to the Producer project
3. Select "Data" from the top navigation menu
4. Click on "Connections" in the left sidebar
5. **Note**: It may take 3-5 minutes for the connection to be fully established and appear in SageMaker Unified Studio
6. You should see your Snowflake connection in the list of available connections
7. **Note**: Please execute the next module if you want the querying to work. If you don't want to run Module 22 you need to execute `make update-kms-policy-for-lakehouse` command to provide the role that is used for Federated Querying access to KMS keys that encrypt Glue catalogs. Only run this make command once either here or, as instructed, in the next module. After that you can now use this connection to query Snowflake data directly from SageMaker notebooks and DataZone projects

---

## 23. **Equity Order Snowflake-ZeroETL-Federation**

This module creates a Glue job that generates synthetic trading data and loads it into Snowflake.

#### Prerequisites

> [!CAUTION]
> Module 21 (Snowflake Connection) must be deployed successfully before proceeding with this module.

#### To deploy the module:

```
make deploy-equity-order-sf-zetl-fed
make start-equity-order-sf-zetl-fed-data-generator (wait for glue job to complete)
make grant-lake-formation-snowflake-catalog (wait for snowflake catalog to be created in Lake Formation console before running this command)
make update-kms-policy-for-snowflake-lakehouse
```

| Target                                 | Result                                                                               | Verification                                                                         |
| -------------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------ |
| deploy-equity-order-sf-zetl-fed                 | Creates a Glue job that generates synthetic trading data and loads it into Snowflake | Verify the following Glue job is created: <br> 1. equity-order-sf-zetl-fed-data-generator |
| start-equity-order-sf-zetl-fed-data-generator       | Runs the Glue job to generate and load trading data into Snowflake                   | Verify the Glue job starts and completes successfully                                |
| grant-lake-formation-snowflake-catalog | Grants Lake Formation permissions to access Snowflake data through catalog           | Verify that the permission is added in Lake Formation                                |
| update-kms-policy-for-snowflake-lakehouse        | Updates the KMS policy to allow Lake Formation to access the KMS key                 | Verify that the KMS policy is updated                                                |

#### Post-Deployment Verification

After successful deployment, you should verify that the trading data was successfully loaded:

- Login to SageMaker Unified Studio using the Project Owner credentials (username containing "powner", e.g., `lois-lanikini-powner@example.com`)
- Navigate to the Producer project
- Select "Data" from the top left navigation menu
- Expand "Lakehouse" arrow
- You should see the "trading_orders" table available inside the Snowflake connection you created in the previous step

---

## 24. **Quicksight Subscription**

This module deploys subscription for quicksight.

#### To deploy the module:

```
make deploy-quicksight-subscription
```

| Target                         | Result                         | Verification                                                                                           |
| ------------------------------ | ------------------------------ | ------------------------------------------------------------------------------------------------------ |
| deploy-quicksight-subscription | Deploy QuickSight subscription | Log into the console and directly see the main QuickSight homepage and confirm subscription is created |

---

#### Important Limitation

Currently (as of March 2025), there is a known limitation when creating a QuickSight subscription via Terraform or AWS API:

- You cannot programmatically assign IAM roles or configure data sources during the initial subscription creation
- This requires a two-step deployment process - if you proceed to create QuickSight subscription through Terraform/API
- Refer to the documentation [here](https://docs.aws.amazon.com/quicksight/latest/APIReference/API_CreateAccountSubscription.html)

## 25. **Quicksight Visualization**

This module deploys datasource, datasets and dashboard visualization for quicksight.

#### Before deploying this step:

- Once the subscription is created, navigate to: QuickSight → Manage QuickSight → Security & Permissions
- Locate "IAM Role In Use" section and click "Manage"
- Choose "Use an existing role"
- Select {app}-{env}-quicksight-service-role
- Note: The quicksight-service-role is a custom IAM role configured with least-privilege access to:
  - Amazon Athena
  - AWS Glue Catalog
  - Amazon S3
  - AWS Lake Formation
- After IAM configuration is completed, we can create datasource and dataset using `make deploy-quicksight`

#### Additional Information About IAM Role Configuration

The IAM Role selection process is a one-time setup requirement for each AWS Root Account where the subscription exists. If you delete and later recreate the subscription in the same AWS Root Account, you will not need to reconfigure the IAM Role because:

1. The IAM configuration is cached by the service
2. The system will automatically use the previously configured IAM Role settings

**Note:** This automatic role reuse only applies when recreating subscriptions within the same AWS Root Account.

#### To deploy the module:

```
make deploy-quicksight-dataset
```

| Target                    | Result                                | Verification                                                              |
| ------------------------- | ------------------------------------- | ------------------------------------------------------------------------- |
| deploy-quicksight-dataset | Deploy QuickSight dataset and reports | Verify that you see a {app}\_{env}\_Billing_Dashboard populated with data |

---

## 26. **Custom Data Lineage**

This module helps users create custom assets and publish custom lineage to Sagemaker Catalog.

Grant project owner permission to create custom asset type:

1. Navigate to the Amazon SageMaker in the AWS Console and select "Corporate" domain
2. Login to the Sagemaker Unified Studio using the domain owner role with "downer" in the name (`ann-chouvey-downer@example.com` in this tutorial)
3. Click on "Govern->Domain units" to open "Domain Units" page
4. Click "Corporate" to open the root domain unit
5. Scroll down to click on "Custom asset type creation policy"
6. Click on "ADD POLICY GRANT" button
7. Select "Corporate" as the project
8. Select "Producer" project from the projects dropdown
9. Select both "Owner" and "Contributor"
10. Click on "ADD POLICY GRANT" button
11. Log out of the Sagemaker Unified Studio

Create Sagemaker notebook to create custom assets and custom lineage:

1. Login to the Sagemaker Unified Studio using the project owner role with "powner" in the name (`lois-lanikini-powner@example.com` in this tutorial)
2. Select "Browse all project" button and open "Producer" Project
3. Select "Build->JupyterLab" from the top bar
4. Click "Start space" button if it has not started
5. Click on "Python 3" to create a Jupyter Notebook using Python3
6. Click on "Save" icon to give the notebook a name, enter "Lineage.ipynb" and click on "Rename" button
7. Copy the content of the file "/iac/roots/sagemaker/lineage/lineage.py" into the cell of Jupyter Notebook
8. Update line 371 with the app name you selected and line 372 with the environment name you selected
9. Execute the notebook

Verify custom assets and custom lineage:

1. Select "Producer->Data" in top middle drop down
2. Click on "Project catalog->Assets"
3. It should show you 2 custom assets: "Trade" and "Order"
4. Click on "Trade" asset
5. Click on "Lineage" tab on top
6. Click on "<<" buttton on left of "Job run" to expand it
7. Click on "3 columns" drop down in "Trade" asset to expand the columns
8. You should see column level lineage between "Order" and "Trade" assets

## 27. **EMR Serverless with Jupyter Notebook**

This module helps users create a Jupyter Notebook and execute a Spark query against Lakehouse using EMR Serverless.

Spark query using EMR Servlerless may fail if "default" Glue database exists. Please delete the "default" Glue database if it exists following the steps outlined above.

```
make grant-default-database-permissions
make drop-default-database
```

Execute following steps to create the Jupyter Notebook.

1. Login to the Sagemaker Unified Studio using the project owner role with "powner" in the name (`lois-lanikini-powner@example.com` in this tutorial)
2. Select "Browse all project" button and open "Producer" Project
3. Select "Build->JupyterLab" from the top bar
4. Click "Start space" button if it has not started
5. Click on "Python 3" to create a Jupyter Notebook using Python3
6. Click on "Save" icon to give the notebook a name, enter "emr.ipynb" and click on "Rename" button
7. Add the following line to the first cell in the notebook

```
spark.sql('SELECT * FROM daivi_dev1_billing.daivi_dev1_billing_hive limit 10;')
```

8. Update the above query in the cell, by replacing "daivi" with the app name you selected and "dev1" with the environment name you selected
9. Click on the first drop down above the cell and select "PySpark" from the drop down
10. Click on the second drop down above the cell and select the EMR serverless cluster starting with "emr" in the name
11. Execute the notebook
12. Please wait for the Spark engine to start and exeucte the query and display the results

## 28. **Spark Code Interpreter**

The Spark Code Interpreter module deploys a conversational Gen AI solution that analyzes datasets from megabytes to petabytes using Amazon Bedrock Agents and Apache Spark. The solution provides two execution options: Spark on AWS Lambda (SoAL) for datasets up to 500MB, and Amazon EMR Serverless for larger datasets.

#### To deploy the module:

```
make deploy-spark-code-interpreter
```

#### To verify the deployment:

1. Check that the ECR repositories have been created and contain the Docker images
2. Verify that the Lambda function has been deployed with the container image
3. Confirm that the EC2 instance is running and the Streamlit application is accessible

For detailed deployment instructions, component descriptions, and troubleshooting guidance, refer to the [Spark Code Interpreter README](../iac/roots/spark-code-interpreter/README.md).

#### To destroy the module:

```
make destroy-spark-code-interpreter
```
## 29. **Post Deployment Testing**

Open Sagemaker Lakehouse following the steps given below. 

1. Login to SageMaker Unified Studio using the Project Owner credentials (username containing "powner", e.g., `lois-lanikini-powner@example.com`)
2. Navigate to the Producer project
3. Select "Data" from the left navigation menu
4. Expand "Lakehouse" node in the second navigation menu
5. You should see "AwsDataCatalog", "s3tablescatalog", "snowflake"

Verify "finops-billing-s3-glue-s3"

1. Open "AwsDataCatlog" -> "finops-billing-s3-glue-s3" -> "Tables"
2. Click on three vertical dots next to "finops_billing_s3_glue_s3_hive" and select "Preview data" to see first 10 records in the table
3. Click on three vertical dots next to "finops_billing_s3_glue_s3_iceberg_static" and select "Preview data" to see first 10 records in the table
4. Click on three vertical dots next to "finops_billing_s3_glue_s3_iceberg_dynamic" and select "Preview data" to see first 10 records in the table
5. Open "s3tablescatalog" -> "finops-billing-s3-glue-s3table" -> "<app name>" -> "Table"
6. Click on three vertical dots next to "finops_billing_s3_glue_s3table" and select "Preview data" to see first 10 records in the table

Verify "finops-inventory-s3-glue-s3"

1. Open "AwsDataCatlog" -> "finops-inventory-s3-glue-s3" -> "Tables"
2. Click on three vertical dots next to "finops_inventory_s3_glue_s3_hive" and select "Preview data" to see first 10 records in the table
3. Click on three vertical dots next to "finops_inventory_s3_glue_s3_iceberg_static" and select "Preview data" to see first 10 records in the table
4. Click on three vertical dots next to "finops_inventory_s3_glue_s3_iceberg_dynamic" and select "Preview data" to see first 10 records in the table
5. Open "s3tablescatalog" -> "finops-inventory-s3-glue-s3table" -> "<app name>" -> "Table"
6. Click on three vertical dots next to "finops_inventory_s3_glue_s3table" and select "Preview data" to see first 10 records in the table

Verify "finops-usage-splunk-glue-s3"

1. Open "AwsDataCatlog" -> "finops-usage-splunk-glue-s3" -> "Table"
2. Click on three vertical dots next to "finops_usage_splunk_glue_s3_iceberg" and select "Preview data" to see first 10 records in the table
3. Open "s3tablescatalog" -> "finops-usage-splunk-glue-s3table" -> "<app name>" -> "Table"
4. Click on three vertical dots next to "finops_usage_splunk_glue_s3table" and select "Preview data" to see first 10 records in the table

Verify "equity-price-s3-glue-s3"

1. Open "AwsDataCatlog" -> "equity-price-s3-glue-s3" -> "Tables"
2. Click on three vertical dots next to "equity_price_s3_glue_s3_hive" and select "Preview data" to see first 10 records in the table
3. Click on three vertical dots next to "equity_price_s3_glue_s3_iceberg" and select "Preview data" to see first 10 records in the table
4. Open "s3tablescatalog" -> "equity-price-s3-glue-s3table" -> "<app name>" -> "Table"
5. Click on three vertical dots next to "equity_price_s3_glue_s3table" and select "Preview data" to see first 10 records in the table

Verify "equity-trade-s3-glue-s3"

1. Open "AwsDataCatlog" -> "equity-trade-s3-glue-s3" -> "Tables"
2. Click on three vertical dots next to "equity_trade_s3_glue_s3_hive" and select "Preview data" to see first 10 records in the table
3. Click on three vertical dots next to "equity_trade_s3_glue_s3_iceberg" and select "Preview data" to see first 10 records in the table
4. Open "s3tablescatalog" -> "equity-trade-s3-glue-s3table" -> "<app name>" -> "Table"
5. Click on three vertical dots next to "equity_trade_s3_glue_s3table" and select "Preview data" to see first 10 records in the table

Verify "equity-trade-msk-glue-s3"

1. Open "AwsDataCatlog" -> "equity-trade-msk-glue-s3" -> "Tables"
2. Click on three vertical dots next to "equity_trade_msk_glue_s3_hive" and select "Preview data" to see first 10 records in the table
3. Click on three vertical dots next to "equity_trade_msk_glue_s3_iceberg" and select "Preview data" to see first 10 records in the table

Verify "equity-order-dd-zetl-s3"

1. Open "AwsDataCatlog" -> "equity-order-dd-zetl-s3" -> "Table"
2. Click on three vertical dots next to "<app name>_<env name>_equity_orders_db_table" and select "Preview data" to see first 10 records in the table

Verify "equity-trade-msk-flink-msk"

1. Open "Managed Apache Flink" service
2. Open "equity-trade-msk-flink-msk" application
3. Click on "Open Apache Flink Dashboard" 
4. Click on "Kafka Streaming Job" in "Running Job List"
5. Scroll down to the list of processed and verify "Source", "Process", "Map" and "Sink" show number of records processed

Verify "equity-orders-snowflake"

1. Open "snowflake" -> "daivi_schema" -> "Table"
2. Click on three vertical dots next to "equity_orders" and select "Preview data" to see first 10 records in the table

## 30. **Clean Up Cache**

This module helps users clean up Terraform cache from local machine. Please run the following make command to clean up local cache.

```
make clean-tf-cache
```

## 31. **AgentCore**

This module deploys an Agentic AI financial analyst powered by Amazon Bedrock AgentCore. It consists of three independent Terraform roots that must be deployed in order: backend → gateway → demo.

> [!NOTE]
> The AgentCore module uses AWS Terraform provider v6 (`~> 6.0`), independent from the rest of the solution (which uses v5). The deployer role must be a Lake Formation admin before first deploy.

#### Prerequisites

- Modules 15 (Equity Price S3-Glue-S3 Data Lake) and 16 (Equity Trade S3-Glue-S3 Data Lake) must be deployed, including their Iceberg Glue jobs. The backend looks up the `equity_price_s3_glue_s3_iceberg` and `equity_trade_s3_glue_s3_iceberg` tables, so `terraform plan` fails if they do not exist. These modules in turn require Modules 1 (Foundation), 5 (Glue Iceberg Jar File), 6 (Lake Formation) and 7 (Athena)
- Module 7 (Athena) must be deployed. The agent's queries run in the `{app}-{env}-workgroup` workgroup and write results to the `{account}-{app}-{env}-athena-output` bucket
- The deployer role must be listed as a Lake Formation data lake admin
- The account must be able to invoke Amazon Nova 2 Lite and Claude Haiku 4.5 in Amazon Bedrock. Anthropic models require a one-time use case form per account
- `pip3` installed locally (for Lambda layer builds)

#### To deploy the module:

```bash
# 1. Backend (creates Lambdas, Cognito, SSM params)
cd iac/roots/agentcore/backend
terraform init
terraform apply

# 2. Gateway (reads backend SSM params, creates MCP gateway)
cd ../gateway
terraform init
terraform apply

# 3. Demo UI (reads gateway SSM params, creates chat app)
cd ../demo
terraform init
terraform apply
```

| Target                     | Result                                                                                          | Verification                                                                                                                                                                                                                                                                                                          |
| -------------------------- | ----------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| deploy-agentcore-backend   | Deploys Cognito, 4 Lambda functions, AgentCore Memory, read-only Lake Formation grants on the equity trade and price tables, SSM parameters | Verify the following resources are created: <br> 1. Cognito User Pool with domain and the user `daivi-agent@example.com` <br> 2. Lambda functions: `get-databases`, `get-database-tables`, `execute-query`, `web-search` <br> 3. AgentCore Memory `{app}_{env}_agentcore_memory` with 3 strategies <br> 4. Lake Formation `SELECT` and `DESCRIBE` grants on `equity_trade_s3_glue_s3_iceberg` and `equity_price_s3_glue_s3_iceberg` for the `{app}-{env}-agentcore-lambda-role` role <br> 5. SSM parameters under `/{app}/{env}/agentcore/*` |
| deploy-agentcore-gateway   | Deploys Bedrock AgentCore MCP gateway with CUSTOM_JWT auth and 4 tool targets                   | Verify the following resources are created: <br> 1. AgentCore MCP gateway <br> 2. 4 gateway targets wired to backend Lambdas <br> 3. SSM parameter `/{app}/{env}/agentcore/gateway-url`                                                                                                                              |
| deploy-agentcore-demo      | Deploys chat UI with API Gateway, Lambda (Strands agent on Nova 2 Lite or Claude Haiku 4.5), and Cognito auth  | Verify the following resources are created: <br> 1. API Gateway HTTP API with `GET /` and `POST /chat` routes <br> 2. Demo Lambda with Strands agent <br> 3. Access the API Gateway URL, sign in with `daivi-agent@example.com` (temporary password: run `make get-agentcore-demo-password`), and verify the chat responds to queries        |

#### Post-Deployment Verification

1. Get the demo URL:
   ```bash
   make get-agentcore-demo-url
   ```
2. Open the URL in a browser — you will see the login page
3. Fetch the temporary password for the demo user `daivi-agent@example.com`:
   ```bash
   make get-agentcore-demo-password
   ```
   or
   ```bash
   aws ssm get-parameter \
     --name "/{APP}/{ENV}/agentcore/demo-user-temp-password" \
     --with-decryption \
     --query Parameter.Value \
     --output text
   ```
   Sign in with that username and password. The temporary password is only valid until the first sign-in.
4. Cognito will prompt you to set a new password on first login
5. After signing in, try a query like: "Which stocks were traded the most?"
6. The agent should identify available databases, write SQL, execute it via Athena, and return results

#### To destroy the module (in reverse order):

```bash
cd iac/roots/agentcore/demo
terraform destroy

cd ../gateway
terraform destroy

cd ../backend
terraform destroy
```

For more details see the [AgentCore module README](../iac/roots/agentcore/README.md).

---

## Troubleshooting

### Outdated CLI version

If you encounter this error during terraform execution:

```
│ Error: local-exec provisioner error
│
│   with null_resource.create_smus_domain,
│   on domain.tf line 9, in resource "null_resource" "create_smus_domain":
│    9:   provisioner "local-exec" {
```

#### Resolution

This error may occur due to an outdated AWS CLI version. To resolve this:

1. Verify your AWS CLI version:

```
aws --version
```

2. Ensure you have AWS CLI version 2.0.0 or higher installed. Refer to the following [documentation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) to update for Windows, macOS, and Linux.

3. After updating, retry the terraform operation

**Note**: The local-exec provisioner requires proper AWS CLI configuration to execute AWS commands successfully.

### Glue/EMR Jobs Fail: "default" Database Conflict

Certain Glue Jobs or EMR Jobs may fail if "default" Glue database exists. Please note that the "default" Glue database may also get created automatically, when you execute certain glue jobs.

#### Resolution

If you notice an error, either in a Glue job or an EMR job, related to a specific role not having permissions to "default" glue database, then please delete the "default" Glue database if it exists following the steps outlined above.

```
make grant-default-database-permissions
make drop-default-database
```
