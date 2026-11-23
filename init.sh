#!/usr/bin/env bash

# Copyright 2025 Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

# This function reads the file that is supplied as the first function argument.
# It then resolves all placeholder values found in that file by
# replacing the ###ENV_VAR_NAME### placeholder with the value of the ENV_VAR_NAME.
# param1: the name of the file that has placeholders to resolve
resolve_placeholders () {

    local filePath="$1"

    local SED_PATTERNS
    local resolvedContent="$(cat "$filePath")"

    # Loop that replaces variable placeholders with values
    local varName
    while read varName
    do
        local envVarValue="${!varName}"

        if [[ "$envVarValue" == "blank" ]]; then
            envVarValue=""
        fi

        SED_PATTERNS="s|###${varName}###|${envVarValue}|g;"

        resolvedContent="$(echo "$resolvedContent" | sed ''"$SED_PATTERNS"'')"

    done <<< "$(IFS=$'\n'; echo -e "${ENV_KEYS[*]}" )"

    echo "$resolvedContent" > "$filePath"
}

echo -e "\nGreetings prototype user! Before you can get started deploying this prototype,"
echo -e "we need to collect some settings values from you...\n"

echo -e "\n12 digit AWS account ID to deploy resources to"
read -p "Enter value: " answer
AWS_ACCOUNT_ID="$answer"

echo -e "\nThe application name that is used to name resources
It is best to use a short value to avoid resource name length limits
Example: daivi"
read -p "Enter value: " answer
APP_NAME="$answer"

echo -e "\nThe environment name that is used to name resources and to determine
the value of environment-specific configurations.
It is best to use a short value to avoid resource name length limits
Examples: quid7, mxr9, your initials with a number"
read -p "Enter value: " answer
ENV_NAME="$answer"

echo -e "\nPrimary AWS region to deploy application resources to
Example: us-east-1"
read -p "Enter value: " answer
AWS_PRIMARY_REGION="$answer"
AWS_DEFAULT_REGION="$answer"

echo -e "\nSecondary AWS region to deploy application resources to
Example: us-west-2"
read -p "Enter value: " answer
AWS_SECONDARY_REGION="$answer"

TF_S3_BACKEND_NAME="${APP_NAME}-${ENV_NAME}-tf-back-end"

envKeysString="AWS_ACCOUNT_ID APP_NAME AWS_DEFAULT_REGION ENV_NAME AWS_PRIMARY_REGION AWS_SECONDARY_REGION TF_S3_BACKEND_NAME"
ENV_KEYS=($(echo "$envKeysString"))
templateFilePathsStr="./set-env-vars.sh ./Makefile
./iac/roots/quicksight/dataset/terraform.tfvars
./iac/roots/quicksight/dataset/backend.tf
./iac/roots/quicksight/subscription/terraform.tfvars
./iac/roots/quicksight/subscription/backend.tf
./iac/roots/idc/idc-org/terraform.tfvars
./iac/roots/idc/idc-org/backend.tf
./iac/roots/idc/idc-acc/terraform.tfvars
./iac/roots/idc/idc-acc/backend.tf
./iac/roots/idc/disable-mfa/terraform.tfvars
./iac/roots/spark-code-interpreter/terraform.tfvars
./iac/roots/spark-code-interpreter/backend.tf
./iac/roots/agentcore/demo/terraform.tfvars
./iac/roots/agentcore/demo/backend.tf
./iac/roots/agentcore/backend/terraform.tfvars
./iac/roots/agentcore/backend/backend.tf
./iac/roots/agentcore/gateway/terraform.tfvars
./iac/roots/agentcore/gateway/backend.tf
./iac/roots/network/terraform.tfvars
./iac/roots/network/backend.tf
./iac/roots/foundation/buckets/terraform.tfvars
./iac/roots/foundation/buckets/backend.tf
./iac/roots/foundation/iam-roles/terraform.tfvars
./iac/roots/foundation/iam-roles/backend.tf
./iac/roots/foundation/msk-serverless/terraform.tfvars
./iac/roots/foundation/msk-serverless/backend.tf
./iac/roots/foundation/vpc/terraform.tfvars
./iac/roots/foundation/kms-keys/terraform.tfvars
./iac/roots/foundation/kms-keys/backend.tf
./iac/roots/common/msk-provisioned/terraform.tfvars
./iac/roots/common/msk-provisioned/backend.tf
./iac/roots/datazone/dz-project-prereq/terraform.tfvars
./iac/roots/datazone/dz-project-prereq/backend.tf
./iac/roots/datazone/dz-custom-project/terraform.tfvars
./iac/roots/datazone/dz-custom-project/backend.tf
./iac/roots/datazone/dz-domain/terraform.tfvars
./iac/roots/datazone/dz-domain/backend.tf
./iac/roots/datazone/dz-consumer-project/terraform.tfvars
./iac/roots/datazone/dz-consumer-project/backend.tf
./iac/roots/datazone/dz-producer-project/terraform.tfvars
./iac/roots/datazone/dz-producer-project/backend.tf
./iac/roots/datalakes/equity-trade-msk-flink-msk/terraform.tfvars
./iac/roots/datalakes/equity-trade-msk-flink-msk/backend.tf
./iac/roots/datalakes/finops-usage-splunk-glue-s3/terraform.tfvars
./iac/roots/datalakes/finops-usage-splunk-glue-s3/backend.tf
./iac/roots/datalakes/finops-billing-s3-glue-s3-cur/terraform.tfvars
./iac/roots/datalakes/finops-billing-s3-glue-s3-cur/backend.tf
./iac/roots/datalakes/finops-inventory-s3-glue-s3/terraform.tfvars
./iac/roots/datalakes/finops-inventory-s3-glue-s3/backend.tf
./iac/roots/datalakes/equity-trade-msk-glue-s3/terraform.tfvars
./iac/roots/datalakes/equity-trade-msk-glue-s3/backend.tf
./iac/roots/datalakes/equity-trade-s3-glue-s3/terraform.tfvars
./iac/roots/datalakes/equity-trade-s3-glue-s3/backend.tf
./iac/roots/datalakes/finops-billing-s3-glue-s3/terraform.tfvars
./iac/roots/datalakes/finops-billing-s3-glue-s3/backend.tf
./iac/roots/datalakes/equity-price-s3-glue-s3/terraform.tfvars
./iac/roots/datalakes/equity-price-s3-glue-s3/backend.tf
./iac/roots/z-etl/dynamodb/equity-order-dd-zetl-s3-prereq/terraform.tfvars
./iac/roots/z-etl/dynamodb/equity-order-dd-zetl-s3-prereq/backend.tf
./iac/roots/z-etl/dynamodb/equity-order-dd-zetl-s3/terraform.tfvars
./iac/roots/z-etl/dynamodb/equity-order-dd-zetl-s3/backend.tf
./iac/roots/z-etl/snowflake/equity-order-sf-zetl-fed/terraform.tfvars
./iac/roots/z-etl/snowflake/equity-order-sf-zetl-fed/backend.tf
./iac/roots/sagemaker/consumer-project/terraform.tfvars
./iac/roots/sagemaker/consumer-project/backend.tf
./iac/roots/sagemaker/producer-project/terraform.tfvars
./iac/roots/sagemaker/producer-project/backend.tf
./iac/roots/sagemaker/snowflake-connection/terraform.tfvars
./iac/roots/sagemaker/snowflake-connection/backend.tf
./iac/roots/sagemaker/domain-prereq/terraform.tfvars
./iac/roots/sagemaker/domain-prereq/backend.tf
./iac/roots/sagemaker/project-config/terraform.tfvars
./iac/roots/sagemaker/project-config/backend.tf
./iac/roots/sagemaker/project-user/terraform.tfvars
./iac/roots/sagemaker/project-user/backend.tf
./iac/roots/sagemaker/domain/terraform.tfvars
./iac/roots/sagemaker/domain/backend.tf
./iac/roots/sagemaker/project-prereq/terraform.tfvars
./iac/roots/sagemaker/project-prereq/backend.tf
./iac/roots/athena/terraform.tfvars
./iac/roots/athena/backend.tf
./iac/bootstrap/parameters.json
./iac/bootstrap/parameters-secondary.json
./iac/bootstrap/parameters-crr.json
./review/checkov.txt
./Makefile-4-customer"
templateFilePaths=($(echo "$templateFilePathsStr"))

for templatePath in "${templateFilePaths[@]}"; do

    if [[ $templatePath == *4-customer ]]; then
        templatePath="./Makefile"
    fi

    if [[ -f "$templatePath" ]]; then
        echo -e "\nResolving placeholders in ${templatePath}"
        resolve_placeholders "$templatePath"
    fi
done

echo -e "\nSUCCESS!\n"
