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
* [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

*Note: Make sure that the latest AWS CLI version is installed. If not, some functionalities won't be deployed correctly.*
* [Terraform >= 1.8.0](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
* [Git CLI](https://git-scm.com/downloads)
* [Python >= 3.10](https://www.python.org/downloads/)
* [PIP >= 25.0.1](https://pypi.org/project/pip/)
* [make](https://www.gnu.org/software/make/)
* [jq](https://stedolan.github.io/jq/)

*Note: Make sure the machine you are deploying from has up to 15 GB free space to deploy the entire solution. We have included a clean up script (module 21) to clean up the cache in the local machine after deployment.*

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

1) **Deployment Role**: Use AWS CLI to login to the account you wish to deploy to, using a deployment role with sufficient privileges to deploy the solution, preferably using the admin role or an equivalent role with sufficient privileges. The solution assumes that you will login to AWS Management console using this deployment role. This role is also referred to as Admin role in the deployment instructions. 

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

2) **Initialization**: From your terminal, go to the root directory of the DAIVI codebase and execute the following command. 
This command will run a wizard that will ask you to provide a value for all of the configuration settings documented above. 
It will perform a search/replace on the project files so that they use the values you provide.

```
make init
```

3) **Set Up Terraform Backend**: Execute the following command to set up S3 buckets to store the project's Terraform state.

```
make deploy-tf-backend-cf-stack
```

## Deployment Steps

The Makefile contains a "deploy-all" target, but we strongly recommend tha you "**DO NOT**" use this make target. We do not recommend deploying the solution in one go. This is due to the time needed for some make targets to initialize, warm-up and execute correctly. For example, job schedulers need time to properly set up their triggers. Also some make targets have linear dependency on other make targets. Deploying it in one go will likely cause configuration errors since some deployed make targets may not be fully functional yet and thus, not ready to be used.

Therefore, we recommend deploying the make targets incrementally, one make target at a time,  to allow each make target to execute successfully and be fully operational before the next make target is executed:
1. Deploy each make target one at a time
2. Wait for each make target to complete 
3. Verify that the make target is fully operational
4. Only then proceed to the next make target

The solution consists of a number of modules. Each module consists of a number of make targets. Please deploy the modules in the order mentioned below (just skip "Billing Data Lake - CUR" module, which you will execute after 24 hours). Each module has a make target, ex: deploy-foundation. Please "**DO NOT**" invoke the make target for a module. Instead invoke individual make targets under each module in the order they are mentioned, waiting for each make target to complete successfully before moving to the next make target. 

You will need to deploy the following modules in order to deploy the whole solution. 

| Order | Module                                                                |
|-------|----------------------------------------------------------------------|
| 1     | [Foundation](#1-foundation)                                           |
| 2     | [IAM Identity Center](#2-iam-identity-center)                         |
| 3     | [Sagemaker Domain](#3-sagemaker-domain)                               | 
| 4     | [Sagemaker Projects](#4-sagemaker-projects)                           | 
| 5     | [Glue Iceberg Jar File](#5-glue-iceberg-jar-file)                     | 
| 6     | [Lake Formation](#6-lake-formation)                                   | 
| 7     | [Athena](#7-athena)                                                   |
| 8     | [Data Lakes](#8-data-lakes)                                           |
| 9     | [Billing Data Lake - Static](#9-billing-data-lake---static)           | 
| 10    | [Billing Data Lake - Dynamic](#10-billing-data-lake---dynamic)        | 
| 11    | [Billing Data Lake - CUR (After 24 hours)](#11-billing-data-lake---cur)| 
| 12    | [Inventory Data Lake - Static](#12-inventory-data-lake---static)      | 
| 13    | [Inventory Data Lake - Dynamic](#13-inventory-data-lake---dynamic)    | 
| 14    | [Splunk Data Lake](#14-splunk-datalake)                               |
| 15    | [Dynamodb Zero ETL](#15-DynamoDB-Zero-ETL)                            |
| 16    | [Sagemaker Project Configuration](#16-sagemaker-project-configuration)| 
| 17    | [Datazone Domain and Projects](#17-datazone-domain-and-projects)      | 
| 18    | [Snowflake Connection](#18-snowflake-connection)                      |
| 19    | [Snowflake ETL](#19-snowflake-etl)                                    |
| 20    | [Quicksight Subscription](#20-quicksight-subscription)                | 
| 21    | [Quicksight Visualization](#21-quicksight-visualization)              |
| 22    | [Customer Data Lineage](#22-customer-data-lineage)                    |
| 23    | [EMR Serverless with Jupyter Notebook](#23-emr-serverless-with-jupyter-notebook) |
| 24    | [Clean Up Cache](#24-clean-up-cache)                                  |
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
```

| Target          | Result                                    | Verification                                                                           |  
|------------------|--------------------------------------------|-----------------------------------------------------------------------------------| 
| deploy-kms-keys  | Provisions KMS keys used by different AWS services | Following KMS keys and aliases are created: <br> 1. {app}-{env}-secrets-manager-secret-key <br> 2. {app}-{env}-systems-manager-secret-key <br> 3. {app}-{env}-s3-secret-key <br> 4. {app}-{env}-glue-secret-key <br> 5. {app}-{env}-athena-secret-key <br> 6. {app}-{env}-event-bridge-secret-key <br> 7. {app}-{env}-cloudwatch-secret-key <br> 8. {app}-{env}-datazone-secret-key <br> 9. {app}-{env}-ebs-secret-key                        | 
| deploy-iam-roles | Provisions IAM roles used by different modules              | Following IAM roles are created: <br> 1. {app}-{env}-glue-role <br> 2. {app}-{env}-lakeformation-service-role <br> 3. {app}-{env}-eventbridge-role <br> 4. {app}-{env}-lambda-billing-trigger-role <br> 5. {app}-{env}-lambda-inventory-trigger-role <br> 6. {app}-{env}-splunk-role <br>  7. {app}-{env}-event-bridge-role <br> 8. {app}-{env}-sagemaker-role <br>  9. {app}-{env}-datazone-domain-execution-role <br> 10. {app}-{env}-quicksight-service-role   
| deploy-buckets   | Deploy S3 buckets needed by different modules                         | Following S3 buckets are created: <br> 1. {app}-{env}-glue-scripts-primary <br> 2. {app}-{env}-glue-scripts-primary-log <br> 3. {app}-{env}-glue-scripts-secondary <br> 4. {app}-{env}-glue-scripts-secondary-log  <br> 5. {app}-{env}-glue-jars-primary <br> 6. {app}-{env}-glue-jars-primary-log <br> 7. {app}-{env}-glue-jars-secondary <br> 8. {app}-{env}-glue-jars-secondary-log  <br> 9. {app}-{env}-glue-spark-logs-primary <br> 10. {app}-{env}-glue-spark-logs-primary-log <br> 11. {app}-{env}-glue-spark-logs-secondary <br> 12. {app}-{env}-glue-spark-logs-secondary-log <br> 13. {app}-{env}-glue-temp-primary <br> 14. {app}-{env}-glue-temp-primary-log <br> 15. {app}-{env}-glue-temp-secondary <br> 16. {app}-{env}-glue-temp-secondary-log <br> 17. {app}-{env}-athena-output-primary <br> 18. {app}-{env}-athena-output-primary-log <br> 19. {app}-{env}-athena-output-secondary <br> 20. {app}-{env}-athena-output-secondary-log <br> 21. {app}-{env}-amazon-sagemaker-{account_id}-primary <br> 22. {app}-{env}-amazon-sagemaker-{account_id}-primary-log <br> 23. {app}-{env}-amazon-sagemaker-{account_id}-secondary <br> 24. {app}-{env}-amazon-sagemaker-{account_id}-secondary-log <br> 25. {app}-{env}-smus-project-cfn-template-primary <br> 26. {app}-{env}-smus-project-cfn-template-primary-log <br> 27. {app}-{env}-smus-project-cfn-template-secondary <br> 28. {app}-{env}-smus-project-cfn-template-secondary-log            |  
---

## 2. **IAM Identity Center**

The IAM Identity Center module enables deployment of either:
- An organization-wide instance (managed through AWS Organizations)
- An account-specific instance (isolated to a single AWS account)

Choose the deployment type that best suits your organization's requirements.[Review AWS Documentation](https://docs.aws.amazon.com/singlesignon/latest/userguide/identity-center-instances.html) to understand the differences between Organization-level versus Account-level Identity Center


#### Before deploying this step: 

**Important Note**: Only one instance can be deployed across all regions, and it must be either Organization-level or Account-level.

#### To deploy the organization level identity center configuration:

**Note**: This step is only applied to organization-level IAM Identity Center. For account-level or standalone instance, this step has been automated as part of the deployment process. 
Before configuring Identity Center for organization-level using make targets:
1. Enable the Organization-level manually on the IAM Identity Center Console
- Navigate to IAM Identity Center in the console
- For organization-level: Select "Enable" > *Enable IAM Identity Center with AWS Organizations* > "Enable"
2. Ensure no existing Identity Center instance is running
- Must delete previous instance before deploying new one
- Currently no programmatic support is available to enable Identity Center through IaC


```
make deploy-idc-org
```

#### To deploy the organization level identity center configuration:

```
make deploy-idc-acc
```

| Target        | Result                                                                                      | Verification |  
|----------------|----------------------------------------------------------------------------------------------|--------
| deploy-idc-org | Provisions IAM Identity Center groups, users, and permission sets (Organization-level) | Following groups are created in Identity Center: <br> 1. Admin  <br> 2. Domain Owner  <br> 3. Project Owner <br> 4. Project Coordinator <br> <br> Following users are created in Identity Center: <br> 1. chris-bakony-admin@example.com <br> 2. ann-chouvey-downer@example.com <br> 3. lois-lanikini-powner@example.com <br> 4. ben-doverano-contributor@example.com
| deploy-idc-acc | Deploy IAM Identity Center groups, users (Account-level)                           |Following groups are created in Identity Center: <br> 1. Admin  <br> 2. Domain Owner  <br> 3. Project Owner <br> 4. Project Coordinator <br> <br> Following users are created in Identity Center: <br> 1. chris-bakony-admin@example.com <br> 2. ann-chouvey-downer@example.com <br> 3. lois-lanikini-powner@example.com <br> 4. ben-doverano-contributor@example.com|
---

#### Two Factor Authentication: 

IAM Identity Center is configured to require two-factor authentication. We recommend you retain the two factor authentication configured. In case, you would like disable two-factor athentication in your sandbox account to make it easy for you to login to Sagemaker Unified Studio without requirement two-factor authentication, you can implement following steps. 

1. Click on "Settings" in left navigation panel
2. Click on "Athentication" tab
3. Click "Configure" buttton in "Multi-factor athentication" section
4. Click on "Never" in "MFA Settings"
5. Click on "Save changes" button

We do not recommend disabling multi-factor authentication. However, if you used the above steps to make it easy for you to explore the DAIVI solution in a Sandbox account, we recommend that you enable multi-factor authentication once you have completed exploring DAIVI solution. We do not recommend disabling multi-factor authentication in develpment, test or production environment. 

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

| Target              | Result                         | Verification                              |  
|---------------------|--------------------------------|--------------------------------------|
| deploy-domain-prereq | Deploy Pre-requisite for Domain | Following VPC is created for Sagemaker <br> 1. sagemaker-unified-studio-vpc   | 
| deploy-domain        | Deploy Domain                   | Following Sagemaker resources are created <br> 1. Sagemaker domain called *Corporate* <br> 2. Sagemaker blueprints are enabled under *Corporate* domain <br> 3. Three Sagemaker project profiles are configured under *Corporate* domain  <br> 4. Login to Sagemaker Unified Studio for *Corporate* domain using various user credentials created in *IAM Identity Center* section and confirm that you are able to open the domain. When you login to Sagemaker Unified Studio, it will be ask you to enter usename and one-time password you had created in the *IAM Identity Center* and it will ask you change the password. Please use a password with letter, numbers and special charaters and store the password in a file using your favorite editor.| 
---

## 4. **Sagemaker Projects**

This module deploys two Sagemaker projects, one for **Producer** and one for **Consumer**. When you execute the "deploy-producer-project"  or "deploy-consumer-project" make target, it will launch 5 cloud formation stacks for each project one after other. After executing the "deploy-producer-project" make target, please open Cloud Formation console and monitor the 5 cloud formation stacks get created and completed. Only then, proceed to execute the "deploy-consumer-project" make target and monitor the 5 cloud formation stacks get created and completed. Only then, proceed to execute the remaining 2 make targets "extract-producer-info" and "extract-consumer-info". 

#### To deploy the module:

```
make deploy-project-prereq
make deploy-producer-project (wait for 5 cloud formation stacks to complete)
make deploy-consumer-project (wait for 5 cloud formation stacks to complete)
make extract-producer-info
make extract-consumer-info
```

| Target               | Result                                 | Verification                              | 
|-----------------------|-----------------------------------------|--------------------------------------|
| deploy-project-prereq | Provisions Pre-requisites for Projects        | Provisions Sagemaker foundational resources   | 
| deploy-producer-project       | Provisions Producer Project                          | Provisions following Sagemaker projects: <br> 1. Producer <br> 2. Login to Sagemaker Unified Studio using "Project Owner" user with username containing "powner" and confirm that you see the producer project and you can open it  | deploy-consumer-project       | Provisions Consumer Project                          | Provisions following Sagemaker projects: <br> 1. Consumer <br> 2. Login to Sagemaker Unified Studio using "Project Owner" user with username containing "powner" and confirm that you see the consumer project and you can open it  | 
| extract-producer-info | Extracts id and role of the project producer | Provisions following SSM Parameters: <br> 1. /{app}/{env}/sagemaker/producer/id <br> 2. /{app}/{env}/sagemaker/producer/role <br> 3. /{app}/{env}/sagemaker/producer/role-name   | 
| extract-consumer-info | Extracts id and role of the project consumer | Provisions following SSM Parameters: <br> 1. /{app}/{env}/sagemaker/consumer/id <br> 2. /{app}/{env}/sagemaker/consumer/role <br> 3. /{app}/{env}/sagemaker/consumer/role-name   | 
---

## 5. **Glue Iceberg Jar File**

This module downloads and deploys the glue runtime jar file that is needed for glue jobs to interact with Iceberg tables. 

#### To deploy the module:

```
make deploy-glue-jars
```

| Target                 | Result          | Verification  | 
|-------------------------|------------------|----------|
| deploy-glue-jars   | Deploy Glue jar file | Verify that the iceberg jar file "s3-tables-catalog-for-iceberg-runtime-0.1.5.jar" is uploaded to S3 bucket "{app}-{env}-glue-jars-primary"  |   
---

## 6. **Lake Formation**

This module deploys lake formation configuration to create Glue catalog for s3tables and registers s3table bucket location with lake formation using lake formation service role. 

#### To deploy the module:

```
make create-glue-s3tables-catalog
make register-s3table-catalog-with-lake-formation
```

| Target                                      | Result                                | Verification                 | 
|----------------------------------------------|----------------------------------------|-------------------------|
| create-glue-s3tables-catalog                 | Create Glue catalog for S3tables                    | Verify that the following Glue catalog is created in Lakeformation by opening "Data Catalog -> Catlogs": <br> 1. s3tablescatalog                |    
| register-s3table-catalog-with-lake-formation | Registers S3 table location with lake formation | Verify that the s3table location is registered with Lakeformation by opening "Administration->Data lake locations" and finding an entry for the following data lake location: <br> 1. s3://tables:{region}:{account}:bucket/*  |      

## 7. **Athena**

This module deploys an athena workgroup. 

#### To deploy the module:

```
make deploy-athena
```

| Target                       | Result                                   | Verification    | 
|-------------------------------|-------------------------------------------|------------|
| deploy-athena                 | Create Athena workgroup                      | Verify following Athena workgroup is created <br> 1. {app}-{env}-workgroup         | 
---

## 8. **Data Lakes**

The solution allows the user to deploy 3 data lakes, 1) billing data lake 2) inventory data lake and 3) splunk data lake. Although we recommend that the user deploys all the 3 data lakes, the user does not need to deploy all the 3 data lakes. If the user wishes to deploy only one data lake to explore the functionalities of DAIVI solution, then we recommend deploying the billing data lake at the minimum. 

## 9. **Billing Data Lake - Static**

Billing Data Lake is divided into 3 modules. 1) Static - Glue Jobs for Tables with Static Schema 2) Dynamic - Glue Jobs for Tables with Dynamic Schema and 3) CUR - Setting up CUR reports after 24 hours of enabling cost explorer in Billing and Cost Management. 

This module sets up the Glue Jobs for Tables with Static Schema. 

#### To deploy the module:

```
make deploy-billing
make grant-default-database-permissions 
make drop-default-database
make start-billing-hive-job (wait for glue job to complete)
make start-billing-iceberg-static-job (wait for glue job to complete)
make start-billing-s3table-create-job (wait for glue job to complete)
make start-billing-s3table-job (wait for glue job to complete)
make grant-lake-formation-billing-s3-table-catalog
make start-billing-hive-data-quality-ruleset
```

| Target                                          | Result                                                        | Verification                                     | 
|--------------------------------------------------|----------------------------------------------------------------|---------------------------------------------|
| deploy-billing                                   | Deploy billing infrastructure                                          | Following S3 buckets are created: <br> 1. {app}-{env}-billing-data-primary <br> 2. {app}-{env}-billing-data-primary-log  <br> 3. {app}-{env}-billing-data-secondary <br> 4. {app}-{env}-billing-data-secondary-log <br> 5. {app}-{env}-billing-hive-primary <br> 6. {app}-{env}-billing-hive-primary-log  <br> 7. {app}-{env}-billing-hive-secondary <br> 8. {app}-{env}-billing-hive-data-secondary-log <br> 9. {app}-{env}-billing-iceberg-primary <br> 10. {app}-{env}-billing-iceberg-primary-log  <br> 11. {app}-{env}-billing-iceberg-secondary <br> 12. {app}-{env}-billing-iceberg-data-secondary-log. <br><br> Following S3 table bucket is created: <br> 1. {app}-{env}-billing <br> <br> Following Glue database is created: <br> 1. {app}_{env}_billing <br><br> Following Glue tables are created: <br> 1. {app}_{env}_billing_hive <br> 2. {app}_{env}_billing_iceberg_static <br><br> Following Glue jobs are created: <br> 1. {app}-{env}-billing-hive <br> 2. {app}-{env}-billing-iceberg-static <br> 3. {app}-{env}-billing-s3table-create <br> 4. {app}-{env}-billing-s3table-delete <br> 5. {app}-{env}-billing-s3table                          |    
| grant-default-database-permissions | Grant deployment role permission to drop "default" database | Verify that the deployment role is granted permission to drop "default" database | 
| drop-default-database | Drop "default" Glue database | Verify that the "default" Glue database is dropped |
| start-billing-hive-job                           | Run the {app}-{env}-billing-hive glue job                                          | Verify that the glue job starts. wait for the glue job to complete |
| start-billing-iceberg-static-job                 | Run the {app}-{env}-billing-iceberg-static glue job                                | Verify that the glue job starts. wait for the glue job to complete |   
| start-billing-s3table-create-job                 | Run the {app}-{env}-billing-s3table-create job                      | Verify that the glue job starts. wait for the glue job to complete                    |    
| start-billing-s3table-job                        | Run the  {app}-{env}-billing-s3table job                     | Verify that the glue job starts. wait for the glue job to complete            |    
| grant-lake-formation-billing-s3-table-catalog    | Grant Lake Formation permissions to inventory S3 table catalog | Verify that the permission is added Lakeformation                    |    
| start-billing-hive-data-quality-ruleset          | Execute billing_hive_ruleset associated with {app}_{env}_billing_hive Glue table                     | Verify that billing_hive_ruleset is executed                  |    
---

## 10. **Billing Data Lake - Dynamic**

Billing Data Lake is divided into 3 modules. 1) Static - Glue Jobs for Tables with Static Schema 2) Dynamic - Glue Jobs for Tables with Dynamic Schema and 3) CUR - Setting up CUR reports after 24 hours of enabling cost explorer report. 

This module sets up the Glue Jobs for Tables with Dynamic Schema. 

#### To deploy the module:

```
make upload-billing-dynamic-report-1 (wait for billing-workflow to start and complete)
make upload-billing-dynamic-report-2 (wait for billing-workflow to start and complete)
make grant-lake-formation-billing-iceberg-dynamic
```

| Target      |                            Result                               | Verification                  | 
|----------------------------------------------------------------------------------------------|----| ----|
| upload-billing-dynamic-report-1                   | Uploads the first cost and usage report to an S3 bucket for triggering a dynamic Glue workflow for billing data processing {app}-{env}-billing-workflow | Verify that the following Glue workflow is executed: <br> 1. {app}-{env}-billing-workflow <br> <br> After the glue workflow completes, confirm creation of the following Glue table: <br> 1. {app}_{env}_billing_iceberg_dynamic                 |    
| upload-billing-dynamic-report-2                   | Uploads the second cost and usage report to an S3 bucket for triggering a dynamic Glue workflow for billing data processing {app}_{env}-billing-workflow | Verify that the following Glue workflow is executed: <br> 1. {app}-{env}-billing-workflow                 | 
| grant-lake-formation-billing-iceberg-dynamic      | Grants lake formation permissions to an admin role for accessing and managing the Iceberg table {app}_{env}_billing_iceberg_dynamic | Verify that the Lakeformation permisison is granted |
---    

## 11. **Billing Data Lake - CUR**

> [!CAUTION]
> Please execute "Billing Set UP" as outlined below and then wait for at least 24 hours before deploying this module, due to the nature of Billing and Cost Management. In the meantime, you can proceed to the [the next section](#12-inventory-data-lake---static).

Billing Data Lake is divided into 3 modules. 1) Static - Glue Jobs for Tables with Static Schema 2) Dynamic - Glue Jobs for Tables with Dynamic Schema and 3) CUR - Setting up CUR reports after 24 hours of enabling cost explorer report. 

This module sets up the Cost and Usage Report. 

**Billing Set Up**: You will need to enable Cost Explorer in Billing and Cost Management before you can configure it to generate daily CUR reports in a S3 bucket. If you have not done this for your account already, please open "Billing and Cost Management" and click on "Cost Explorer" under "Cost and Usage Analysis". When you visit this page for the first time it will show a welcome message "Welcome to AWS Cost Management. Since this is your first visit, it will take some time to prepare your cost and usage data. Please check back in 24 hours."

#### To deploy the module:

```
make activate-cost-allocation-tags
make deploy-billing-cur
```

| Target                       | Result                                                                                                                           | Verification     |
|-------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|------------------|
| activate-cost-allocation-tags | Activate cost allocation tag in AWS Cost Explorer                                                                                 | Verify that the cost allocation tags are activated in Billing and Cost Management   |   
| deploy-billing-cur            | Deploy an AWS Cost and Usage Report (CUR) configuration to generate Cost and Usage Reports (CUR) daily  | Verify that Cost and Usage Report (CUR) is created in Billing and Cost Management   |


## 12. **Inventory Data Lake - Static**

Inventory Data Lake is divided into 2 modules. 1) Static - Glue Jobs for Tables with Static Schema 2) Dynamic - Glue Jobs for Tables with Dynamic Schema 

This module sets up the Glue Jobs for Tables with Static Schema. 

#### To deploy the module:

```
make deploy-inventory
make grant-default-database-permissions 
make drop-default-database
make start-inventory-hive-job (wait for glue job to complete)
make start-inventory-iceberg-static-job (wait for glue job to complete)
make start-inventory-s3table-create-job (wait for glue job to complete)
make start-inventory-s3table-job (wait for glue job to complete)
make grant-lake-formation-inventory-s3-table-catalog 
make start-inventory-hive-data-quality-ruleset 
```

| Target                                          | Result                                                        | Verification                                     | 
|--------------------------------------------------|----------------------------------------------------------------|---------------------------------------------|
| deploy-inventory                                   | Deploy inventory infrastructure                                          | Following S3 buckets are creatd: <br> 1. {app}-{env}-inventory-data-primary <br> 2. {app}-{env}-inventory-data-primary-log  <br> 3. {app}-{env}-inventory-data-secondary <br> 4. {app}-{env}-inventory-data-secondary-log <br> 5. {app}-{env}-inventory-hive-primary <br> 6. {app}-{env}-inventory-hive-primary-log  <br> 7. {app}-{env}-inventory-hive-secondary <br> 8. {app}-{env}-inventory-hive-data-secondary-log <br> 9. {app}-{env}-inventory-iceberg-primary <br> 10. {app}-{env}-inventory-iceberg-primary-log  <br> 11. {app}-{env}-inventory-iceberg-secondary <br> 12. {app}-{env}-inventory-iceberg-data-secondary-log. <br><br> Following S3 table bucket is created: <br> 1. {app}-{env}-inventory <br> <br> Following Glue database is created: <br> 1. {app}_{env}_inventory <br><br> Following Glue tables are created <br> 1. {app}_{env}_inventory_hive <br> 2. {app}_{env}_inventory_iceberg_static <br><br> Following Glue jobs are created: <br> 1. {app}-{env}-inventory-hive <br> 2. {app}-{env}-inventory-iceberg-static <br> 3. {app}-{env}-inventory-s3table-create <br> 4. {app}-{env}-inventory-s3table-delete <br> 5. {app}-{env}-inventory-s3table                          |    
| grant-default-database-permissions | Grant deployment role permission to drop "default" Glue database | Verify that the deployment role is granted permission to drop "default" database | 
| drop-default-database | Drops "default" Glue database | Verify that the "default" Glue database is dropped | 
| start-inventory-hive-job                           | Run the {app}-{env}-inventory-hive glue job                                          | Verify that the glue job starts. wait for the glue job to complete |
| start-inventory-iceberg-static-job                 | Run the {app}-{env}-inventory-iceberg-static glue job                                | Verify that the glue job starts. wait for the glue job to complete |   
| start-inventory-s3table-create-job                 | Run the {app}-{env}-inventory-s3table-create job                      | Verify that the glue job starts. wait for the glue job to complete                    |    
| start-inventory-s3table-job                        | Run the  {app}-{env}-inventory-s3table job                     | Verify that the glue job starts. wait for the glue job to complete            |    
| grant-lake-formation-inventory-s3-table-catalog    | Grant Lake Formation permissions to inventory S3 table catalog | Verify that the permission is added Lakeformation                    |    
| start-inventory-hive-data-quality-ruleset          | Execute inventory_hive_ruleset associated with {app}_{env}_inventory_hive Glue table                     | Verify that inventory_hive_ruleset is executed                  |    
---  

## 13. **Inventory Data Lake - Dynamic**

Inventory Data Lake is divided into 2 modules. 1) Static - Glue Jobs for Tables with Static Schema 2) Dynamic - Glue Jobs for Tables with Dynamic Schema and 

This module sets up the Glue Jobs for Tables with Dynamic Schema. 

#### To deploy the module:

```
make upload-inventory-dynamic-report-1 (wait for inventory-workflow to start and complete)
make upload-inventory-dynamic-report-2 (wait for inventory-workflow to start and complete)
make grant-lake-formation-inventory-iceberg-dynamic
```

| Target      |                            Result                               | Verification                  | 
|----------------------------------------------------------------------------------------------|----| ----|
| upload-inventory-dynamic-report-1                   | Uploads the first inventory report to an S3 bucket for triggering a dynamic Glue workflow for inventory data processing {app}_{env}-inventory-workflow | Verify that the following Glue workflow is executed: <br> 1. {app}_{env}-inventory-workflow <br> <br> After the glue workflow completes, confirm creation of the following Glue table: <br> 1. {app}_{env}_inventory_iceberg_dynamic                 |    
| upload-inventory-dynamic-report-2                   | Uploads the second inventory report to an S3 bucket for triggering a dynamic Glue workflow for inventory data processing {app}_{env}-inventory-workflow | Verify that the following Glue workflow is executed: <br> 1. {app}_{env}-inventory-workflow                 | 
| grant-lake-formation-inventory-iceberg-dynamic      | Grants lake formation permissions to an admin role for accessing and managing the Iceberg table {app}_{env}_inventory_iceberg_dynamic | Verify that the Lakeformation permisison is granted |
---  

## 14. **Splunk Datalake**

This module deploys splunk datalake.

#### To deploy the module:

```
make deploy-network (wait for glue job to complete)
make deploy-splunk (wait for EC2 instance's Status check to show '3/3 checks passed' before proceeding, recommended to wait at least 5 minutes before proceeding)
make grant-default-database-permissions 
make drop-default-database
make start-splunk-iceberg-static-job (wait for glue job to complete)
make start-splunk-s3table-create-job (wait for glue job to complete)
make start-splunk-s3table-job 
make grant-lake-formation-splunk-s3-table-catalog 
```

| Target                                      | Result                                                     | Verification                                     | 
|----------------------------------------------|-------------------------------------------------------------|---------------------------------------------|
| deploy-network                               | Deploy VPC network for Splunk application                             | Verify that the following VPC is created: <br> 1. {app}_{env}-vpc                                    |    
| deploy-splunk                                | Deploy splunk application to an EC2 instance and configure it                                              | Verify that the following EC2 instance is created. <br> 1. {app}_{env}-splunk-instance <br> 2. Give 10 minutes for Splunk instance to be operational on EC2, and then execute the remaining make targets <br><br> Following S3 buckets are creatd: <br> 1. {app}-{env}-splunk-iceberg-primary <br> 2. {app}-{env}-splunk-iceberg-primary-log  <br> 3. {app}-{env}-splunk-iceberg-secondary <br> 4. {app}-{env}-splunk-iceberg-data-secondary-log. <br><br> Following S3 table bucket is created: <br> 1. {app}-{env}-splunk <br> <br> Verify that following Glue database is created: <br> 1. {app}_{env}_splunk <br><br> Following Glue tables are created: <br> 1. {app}_{env}_splunk_iceberg <br><br> Following Glue jobs are created: <br> 1. {app}-{env}-splunk-iceberg-static <br> 2. {app}-{env}-splunk-s3table-create <br> 3. {app}-{env}-splunk-s3table-delete <br> 4. {app}_{env}-splunk-s3table                                  |    
| grant-default-database-permissions | Grant deployment role permission to drop "default" database | Verify that the deployment role is granted permission to drop "default" database | 
| drop-default-database | Drop "default" Glue database | Verify that the "default" Glue database is dropped | 
| start-splunk-iceberg-static-job              | Run {app}-{env}-splunk-iceberg-static Glue job                                       | Verify that the glue job starts. wait for the glue job to complete |    
| start-splunk-s3table-create-job              | Run {app}-{env}-splunk-s3table-create Glue job                     | Verify that the glue job starts. wait for the glue job to complete                     |    
| start-splunk-s3table-job                     | Run {app}-{env}-splunk-s3table-create Glue job                     | Verify that the glue job starts. wait for the glue job to complete             |    
| grant-lake-formation-splunk-s3-table-catalog | Grant Lake Formation permissions to Splunk S3 table catalog  |
---   

## 15. **DynamoDB Zero ETL**

This module configures zero etl integration between Amazon DynamoDb and Amazon SageMaker Lakehouse. DynamoDB zero integration eliminates the need to build custom data movement pipelines by automatically replicating DynamoDB data to Amazon Sagemaker Lakehouse.

#### To deploy the module:

```
make deploy-z-etl-dynamodb-data-prereq 
make upload-z-etl-dynamodb-data 
make deploy-z-etl-dynamodb
```

| Target                                               | Result                                                                                                                  | Verification                  | 
|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|--------------------------|
| deploy-z-etl-dynamodb-data-prereq                                 | Creats S3 bucket to store the data needed to populate DynamoDB                                                                                                    | Following S3 buckets are created: <br> 1. {app}-{env}-equity-orders-data-primary <br> 2. {app}-{env}-equity-orders-data-primary-log  <br> 3. {app}-{env}-equity-orders-data-secondary <br> 4. {app}-{env}-equity-orders-data-secondary-log <br>                 |
| upload-z-etl-dynamodb-data                                 | Uploads equity orders data to s3 bucket                                                                                                    | Check for equity_orders.csv.zip file in {app}-{env}-equity-orders-data-primary bucket                  |
| deploy-z-etl-dynamodb                                 | Uploads equity orders data to s3 bucket                                                                                                    | Verify that {app}-{env}-equity-orders-db-table dynamodb table is created with data populated <br> <br> Verify the following Glue database is created: {app}_{env}_equity_orders_zetl_ddb <br> <br> Verify the following zero etl integration is created and is in active state: {app}-{env}-ddb-glue-zetl-integration <br> <br> Verify the following Glue database table is created: {app}\_{env}_equity_orders_db_table (Wait for few mintues for the initial integration to complete)                  |


## 16. **Sagemaker Project Configuration**

This module configures the Sagemaker Producer and Consumer Projects to load the Data Lakes into Lakehouse by granting project roles lake house permissions to the data lakes. 

#### To deploy the module:

```
make deploy-project-config
make billing-grant-producer-s3tables-catalog-permissions
make inventory-grant-producer-s3tables-catalog-permissions
make splunk-grant-producer-s3tables-catalog-permissions
```

| Target                                               | Result                                                                                                                  | Verification                  | 
|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|--------------------------|
| deploy-project-config                                 | Deploy Project Config                                                                                                    | Grants Lake Formation permissions to the producer project role and consumer project role to access the 3 data lakes                 | Verify that the project roles are granted lake formation permissions |   
| billing-grant-producer-s3tables-catalog-permissions   | Grants Lake Formation access permissions to a project producer role for querying billing data through S3 table catalog   | Verify that the project role is granted lake formation permissions  |     
| inventory-grant-producer-s3tables-catalog-permissions | Grants Lake Formation access permissions to a project producer role for querying inventory data through S3 table catalog | Verify that the project role is granted lake formation permissions  |    
| splunk-grant-producer-s3tables-catalog-permissions    | Grants Lake Formation access permissions to a project producer role for querying splunk data through S3 table catalog    | Verify that the project role is granted lake formation permissions  |    
---   

## 17. **Datazone Domain and Projects**

This module deploys datazone domain and datazone project. 

#### To deploy the module:

```
make deploy-datazone-domain
make deploy-datazone-project-prereq (wait for 5 minutes for the environment to be created and activated)
make deploy-datazone-producer-project
make deploy-datazone-consumer-project
make deploy-datazone-custom-project
```

| Target                  | Result                 | Verify                            | 
|--------------------------|-------------------------|------------------------------------|
| deploy-datazone-domain   | Deploy Datazone Domain  | Verify that a Datazone domain **Exchange** is created |    
| deploy-datazone-project-prereq  | Deploy Datazone Project Prerequisites | Verify that Datazone project prerequisites are created **producer_project**, **consumer_project** and **custom_project** are created in the Datazone domain **Exchange**  | deploy-datazone-procuder-project  | Deploy Datazone Producer Project | Verify that Datazone **Producer** project is created in the Datazone domain **Exchange**  | deploy-datazone-consumer-project  | Deploy Datazone Consumer Project | Verify that Datazone **Consumer** project is created in the Datazone domain **Exchange**  | deploy-datazone-custom-project  | Deploy Datazone Consumer Project | Verify that Datazone **Custom** project is created in the Datazone domain **Exchange**  | 
---

## 18. **Snowflake Connection**

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

2. **Create Lowercase Database and Schema**:
   - Open a Snowflake worksheet and execute:
   ```sql
   -- Create database and schema with lowercase names
   CREATE DATABASE IF NOT EXISTS "daivi_db";
   USE DATABASE "daivi_db";
   CREATE SCHEMA IF NOT EXISTS "daivi_schema";
   USE SCHEMA "daivi_schema";
   ```

3. **Create Sample Table with Lowercase Name**:
   ```sql
   -- Create a sample table with lowercase name
   CREATE OR REPLACE TABLE "daivi_sample_table" (
     "id" INTEGER,
     "name" STRING,
     "value" FLOAT
   );
   
   -- Insert sample data
   INSERT INTO "daivi_sample_table" VALUES
     (1, 'item1', 10.5),
     (2, 'item2', 20.3),
     (3, 'item3', 30.7);
   ```

4. **Create or Verify Lowercase Warehouse**:
   ```sql
   -- Create a warehouse with lowercase name
   CREATE WAREHOUSE IF NOT EXISTS "daivi_wh"
   WITH WAREHOUSE_SIZE = 'XSMALL'
   AUTO_SUSPEND = 60
   AUTO_RESUME = TRUE;
   ```

5. **Test Query**:
   ```sql
   -- Test query to verify data access
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

| Target                     | Result                                                | Verification                                     | 
|----------------------------|-------------------------------------------------------|--------------------------------------------------|
| deploy-snowflake-connection | Creates a DataZone connection to Snowflake for the Producer project | Verify that the following resources are created: <br> 1. AWS Secrets Manager secret containing Snowflake credentials: {app}-{env}-snowflake-credentials <br> 2. Lambda function to manage the DataZone connection: {app}-{env}-datazone-conn-lambda <br> 3. IAM role for the Lambda function: {app}-{env}-lambda-datazone-conn-role <br> 4. SNS topic for Lambda DLQ: {app}-{env}-datazone-conn-lambda-dlq <br> 5. Login to SageMaker DataZone Producer project and verify the Snowflake connection appears in the connections list |

#### Post-Deployment Verification

After successful deployment, you should verify that the Snowflake connection is properly established:

1. Login to SageMaker Unified Studio using the Project Owner credentials (username containing "powner", e.g., `lois-lanikini-powner@example.com`)
2. Navigate to the Producer project
3. Select "Data" from the top navigation menu
4. Click on "Connections" in the left sidebar
5. **Note**: It may take 3-5 minutes for the connection to be fully established and appear in SageMaker Unified Studio
6. You should see your Snowflake connection in the list of available connections
7. You can now use this connection to query Snowflake data directly from SageMaker notebooks and DataZone projects
---

## 19. **Snowflake ETL**

This module creates a Glue job that generates synthetic trading data and loads it into Snowflake.

#### Prerequisites

> [!CAUTION]
> Module 18 (Snowflake Connection) must be deployed successfully before proceeding with this module.

#### To deploy the module:

```
make deploy-z-etl-snowflake
make start-trading-data-generator-job (wait for glue job to complete)
make grant-lake-formation-snowflake-catalog (wait for snowflake catalog to be created in Lake Formation console before running this command)
```

| Target                     | Result                                                | Verification                                     | 
|----------------------------|-------------------------------------------------------|--------------------------------------------------|
| deploy-z-etl-snowflake | Creates a Glue job that generates synthetic trading data and loads it into Snowflake | Verify the following Glue job is created: <br> 1. {app}-{env}-trading-data-generator |
| start-trading-data-generator-job | Runs the Glue job to generate and load trading data into Snowflake | Verify the Glue job starts and completes successfully |
| grant-lake-formation-snowflake-catalog | Grants Lake Formation permissions to access Snowflake data through catalog | Verify that the permission is added in Lake Formation |

#### Post-Deployment Verification

After successful deployment, you should verify that the trading data was successfully loaded:
- Login to SageMaker Unified Studio using the Project Owner credentials (username containing "powner", e.g., `lois-lanikini-powner@example.com`)
- Navigate to the Producer project
- Select "Data" from the top left navigation menu
- Expand "Lakehouse" arrow
- You should see the "trading_orders" table available inside the Snowflake connection you created in the previous step
---

## 20. **Quicksight Subscription**

This module deploys subscription for quicksight.

#### To deploy the module:

```
make deploy-quicksight-subscription 
```

| Target                        | Result                        | Verify                                                         |
|--------------------------------|--------------------------------|----------------------------------------------------------------------|
| deploy-quicksight-subscription | Deploy QuickSight subscription | Log into the console and directly see the main QuickSight homepage and confirm subscription is created |   
---

#### Important Limitation
Currently (as of March 2025), there is a known limitation when creating a QuickSight subscription via Terraform or AWS API:
- You cannot programmatically assign IAM roles or configure data sources during the initial subscription creation
- This requires a two-step deployment process - if you proceed to create QuickSight subscription through Terraform/API
- Refer to the documentation [here](https://docs.aws.amazon.com/quicksight/latest/APIReference/API_CreateAccountSubscription.html)



## 21. **Quicksight Visualization**

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

| Target                        | Result                                | Verfication                                                                                  |
|--------------------------------|----------------------------------------|-----------------------------------------------------------------------------------------------|
| deploy-quicksight-dataset | Deploy QuickSight dataset and reports | Verify that you see a {app}_{env}_Billing_Dashboard populated with data  |
---

## 22. **Custom Data Lineage**

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

## 23. **EMR Serverless with Jupyter Notebook**

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

## 24. **Clean Up Cache**

This module helps users clean up Terraform cache from local machine. Please run the following make command to clean up local cache. 

```
make clean-tf-cache 
```

## Troubleshooting 

### Outdated CLI  version 
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