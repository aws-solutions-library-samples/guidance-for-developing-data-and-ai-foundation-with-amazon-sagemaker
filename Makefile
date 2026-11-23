# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

SHELL := /usr/bin/env bash -euo pipefail -c

APP_NAME = ###APP_NAME###
ENV_NAME = ###ENV_NAME###
AWS_ACCOUNT_ID = ###AWS_ACCOUNT_ID###
AWS_DEFAULT_REGION = ###AWS_DEFAULT_REGION###
AWS_PRIMARY_REGION = ###AWS_PRIMARY_REGION###
AWS_SECONDARY_REGION = ###AWS_SECONDARY_REGION###
TF_S3_BACKEND_NAME = ###TF_S3_BACKEND_NAME###

#################### Global Constants ####################

ADMIN_ROLE = Admin

#################### Init Wizard ####################

init:
	./init.sh

#################### Terraform Backend ####################

deploy-tf-backend-cf-stack:
	aws cloudformation deploy \
	--template-file ./iac/bootstrap/tf-backend-cf-stack.yml \
	--stack-name $(TF_S3_BACKEND_NAME) \
	--tags App=$(APP_NAME) Env=$(ENV_NAME) \
	--region $(AWS_PRIMARY_REGION) \
	--capabilities CAPABILITY_NAMED_IAM \
	--parameter-overrides file://iac/bootstrap/parameters.json
	aws cloudformation deploy \
	--template-file ./iac/bootstrap/tf-backend-cf-stack.yml \
	--stack-name $(TF_S3_BACKEND_NAME) \
	--tags App=$(APP_NAME) Env=$(ENV_NAME) \
	--region $(AWS_SECONDARY_REGION) \
	--capabilities CAPABILITY_NAMED_IAM \
	--parameter-overrides file://iac/bootstrap/parameters-secondary.json
	aws cloudformation deploy \
	--template-file ./iac/bootstrap/tf-backend-cf-stack.yml \
	--stack-name $(TF_S3_BACKEND_NAME) \
	--tags App=$(APP_NAME) Env=$(ENV_NAME) \
	--region $(AWS_PRIMARY_REGION) \
	--capabilities CAPABILITY_NAMED_IAM \
	--parameter-overrides file://iac/bootstrap/parameters-crr.json

destroy-tf-backend-cf-stack:
	@./build-script/empty-s3.sh empty_s3_bucket_by_name "$(APP_NAME)-$(ENV_NAME)-tf-back-end-$(AWS_ACCOUNT_ID)-$(AWS_PRIMARY_REGION)"
	aws cloudformation delete-stack \
	--stack-name $(TF_S3_BACKEND_NAME)
	aws cloudformation wait stack-delete-complete \
	--stack-name $(TF_S3_BACKEND_NAME) \
	--region $(AWS_PRIMARY_REGION)
	@./build-script/empty-s3.sh empty_s3_bucket_by_name "$(APP_NAME)-$(ENV_NAME)-tf-back-end-$(AWS_ACCOUNT_ID)-$(AWS_SECONDARY_REGION)"
	aws cloudformation delete-stack \
	--stack-name $(TF_S3_BACKEND_NAME)
	aws cloudformation wait stack-delete-complete \
	--stack-name $(TF_S3_BACKEND_NAME) \
	--region $(AWS_SECONDARY_REGION)

#################### Terraform Cache Clean-up ####################

clean-tf-cache:
	@echo "Removing Terraform caches in iac/roots/."
	find . -type d -name ".terraform" -exec rm -rf {} +
	@echo "Complete"
	
#################### KMS Keys ####################

deploy-kms-keys:
	@echo "Deploying KMS Keys"
	(cd iac/roots/foundation/kms-keys; \
		terraform init; \
		terraform apply -auto-approve;)
		@echo "Finished Deploying KMS Keys"

destroy-kms-keys:
	@echo "Destroying KMS Keys"
	(cd iac/roots/foundation/kms-keys; \
		terraform init; \
		terraform destroy -auto-approve;)
		@echo "Finished Destroying KMS Keys"

#################### IAM Roles ####################

deploy-iam-roles:
	@echo "Deploying IAM Roles"
	(cd iac/roots/foundation/iam-roles; \
		terraform init; \
		terraform apply -var CURRENT_ROLE="$(ADMIN_ROLE)" -auto-approve;)
		@echo "Finished Deploying IAM Roles"

destroy-iam-roles:
	@echo "Destroying IAM Roles"
	(cd iac/roots/foundation/iam-roles; \
		terraform init; \
		terraform destroy -var CURRENT_ROLE="$(ADMIN_ROLE)" -auto-approve;)
		@echo "Finished Destroying IAM Roles"

#################### Buckets ####################

deploy-buckets:
	@echo "Deploying Buckets"
	(cd iac/roots/foundation/buckets; \
		terraform init; \
		terraform apply -auto-approve;)
		@echo "Finished Deploying Buckets"

destroy-buckets:
	@echo "Destroying Buckets"
	(cd iac/roots/foundation/buckets; \
		terraform init; \
		terraform destroy -auto-approve;)
		@echo "Finished Destroying Data Bucket"

#################### VPC ############################

deploy-vpc:
	@echo "Deploying VPC"
	(cd iac/roots/foundation/vpc; \
		terraform init; \
		terraform apply -auto-approve;)
		@echo "Finished Deploying VPC"

destroy-vpc:
	@echo "Destorying VPC"
	(cd iac/roots/foundation/vpc; \
		terraform init; \
		terraform destroy -auto-approve;)
		@echo "Finished Destroying VPC"

#################### Serverless MSK ############################

build-msk-data-generator-lambda-layer-zip:
	@echo "Building Lambda Layer"
	cd iac/roots/foundation/msk-serverless/data-generator; \
	rm -f dependencies_layer.zip; \
	mkdir -p python; \
	pip install -r requirements.txt --platform manylinux2014_x86_64 --python-version 3.12 --only-binary=:all: --target ./python; \
	zip -r dependencies_layer.zip python/; \
	rm -rf python/
	@echo "Finished Building Lambda Layer"

deploy-msk:
	@echo "Deploying MSK cluster"
	(cd iac/roots/foundation/msk-serverless; \
		terraform init; \
		terraform apply -auto-approve;)
		@echo "Finished Deploying MSK Cluster"

destroy-msk:
	@echo "Destorying MSK Cluster"
	(cd iac/roots/foundation/msk-serverless; \
		terraform init; \
		terraform destroy -auto-approve;)
		@echo "Finished Destroying MSK Cluster"

#################### Identity Center ####################

deploy-idc-org:
	@echo "Deploying Organization-Level Identity Center"
	(cd iac/roots/idc/idc-org; \
		terraform init; \
		terraform apply -auto-approve;)
		@echo "Finished Deploying Organization-Level Identity Center"

destroy-idc-org:
	@echo "Destroying Organization-Level Identity Center"
	(cd iac/roots/idc/idc-org; \
		terraform init; \
		terraform destroy -auto-approve;)
		@echo "Finished Destroying Organization-Level Identity Center"

deploy-idc-acc:
	@echo "Deploying Account-Level Identity Center"
	(cd iac/roots/idc/idc-acc; \
		terraform init; \
		terraform apply -var ADMIN_ROLE="$(ADMIN_ROLE)" -auto-approve;)
		@echo "Finished Deploying Account-Level Identity Center"

destroy-idc-acc:
	@echo "Destroying Account-Level Identity Center"
	(cd iac/roots/idc/idc-acc; \
		terraform init; \
		terraform destroy -var ADMIN_ROLE="$(ADMIN_ROLE)" -auto-approve;)
		@echo "Finished Destroying Account-Level Identity Center"

disable-mfa:
	@echo "Disable MFA of IAM Identity Center"
	@echo "Building Lambda layer for MFA disabler"
	chmod +x iac/roots/idc/disable-mfa/build_layer.sh
	iac/roots/idc/disable-mfa/build_layer.sh
	@echo "Finished building Lambda layer"
	(cd iac/roots/idc/disable-mfa; \
		terraform init; \
		terraform apply -auto-approve;)
		@echo "Finished Deploying Identity Center"

clean-mfa-components:
	@echo "Destroying Bucket, Layer, and Roles creation of MFA Disable"
	(cd iac/roots/idc/disable-mfa; \
		terraform init; \
		terraform destroy -auto-approve;)
		@echo "Finished cleanup"

deploy-dyo-idc:
	@echo "Creating SSM parameter with IAM Identity Center user mappings"
	@if [ -z "$(APP_NAME)" ] || [ -z "$(ENV_NAME)" ]; then \
		echo "Error: APP and ENV variables are required. Please set them using APP=<app-name> ENV=<environment>"; \
		exit 1; \
	fi; \
	IDENTITY_STORE_ID=$$(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text); \
	KMS_KEY_ID=$$(aws kms describe-key --key-id alias/aws/ssm --query 'KeyMetadata.KeyId' --output text); \
	CALLER_EMAIL=$$(aws sts get-caller-identity --query 'Arn' --output text | grep -o '[^/]*$$'); \
	JSON_STRUCTURE="{\"$$IDENTITY_STORE_ID\":{"; \
	for GROUP in "Admin" "Domain Owner" "Project Contributor" "Project Owner"; do \
		echo "Processing $$GROUP..."; \
		GROUP_ID=$$(aws identitystore list-groups \
			--identity-store-id $$IDENTITY_STORE_ID \
			--filters "AttributePath=DisplayName,AttributeValue=$$GROUP" \
			--query 'Groups[0].GroupId' \
			--output text); \
		if [ "$$GROUP_ID" != "None" ]; then \
			MEMBERS=$$(aws identitystore list-group-memberships \
				--identity-store-id $$IDENTITY_STORE_ID \
				--group-id $$GROUP_ID); \
			MEMBER_COUNT=$$(echo $$MEMBERS | jq '.GroupMemberships | length'); \
			if [ "$$MEMBER_COUNT" -gt 0 ]; then \
				USER_EMAILS=$$(echo $$MEMBERS | jq -r '.GroupMemberships[].MemberId.UserId // .GroupMemberships[].MemberId' | while read MEMBER_ID; do \
					if [[ $$MEMBER_ID =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$$ ]]; then \
						aws identitystore describe-user \
							--identity-store-id $$IDENTITY_STORE_ID \
							--user-id "$$MEMBER_ID" \
							--query 'UserName' \
							--output text; \
					else \
						echo "Invalid user ID format: $$MEMBER_ID" >&2; \
					fi; \
				done | grep -v None | awk -v ORS=, '{print "\""$$0"\""}' | sed 's/,$$/\n/');\
				if [ ! -z "$$USER_EMAILS" ]; then \
					JSON_STRUCTURE="$$JSON_STRUCTURE\"$$GROUP\":[$$USER_EMAILS],"; \
				elif [ "$$GROUP" = "Domain Owner" ] || [ "$$GROUP" = "Project Owner" ] || [ "$$GROUP" = "Admin" ]; then \
					echo "Group $$GROUP exists but has no valid users. Adding caller ($$CALLER_EMAIL) as $$GROUP"; \
					JSON_STRUCTURE="$$JSON_STRUCTURE\"$$GROUP\":[\"$$CALLER_EMAIL\"],"; \
				else \
					JSON_STRUCTURE="$$JSON_STRUCTURE\"$$GROUP\":[],"; \
				fi; \
			else \
				if [ "$$GROUP" = "Domain Owner" ] || [ "$$GROUP" = "Project Owner" ] || [ "$$GROUP" = "Admin" ]; then \
					echo "Group $$GROUP exists but has no members. Adding caller ($$CALLER_EMAIL) as $$GROUP"; \
					JSON_STRUCTURE="$$JSON_STRUCTURE\"$$GROUP\":[\"$$CALLER_EMAIL\"],"; \
				else \
					JSON_STRUCTURE="$$JSON_STRUCTURE\"$$GROUP\":[],"; \
				fi; \
			fi; \
		else \
			echo "Warning: Group '$$GROUP' not found in Identity Center"; \
			if [ "$$GROUP" = "Domain Owner" ] || [ "$$GROUP" = "Project Owner" ] || [ "$$GROUP" = "Admin" ]; then \
				echo "Adding caller ($$CALLER_EMAIL) as $$GROUP"; \
				JSON_STRUCTURE="$$JSON_STRUCTURE\"$$GROUP\":[\"$$CALLER_EMAIL\"],"; \
			else \
				JSON_STRUCTURE="$$JSON_STRUCTURE\"$$GROUP\":[],"; \
			fi; \
		fi; \
	done; \
	JSON_STRUCTURE=$${JSON_STRUCTURE%,}; \
	JSON_STRUCTURE="$$JSON_STRUCTURE}}"; \
	aws ssm put-parameter \
		--name "/$(APP_NAME)/$(ENV_NAME)/identity-center/users" \
		--description "Map of IAM Identity Center users and their group associations" \
		--type "SecureString" \
		--value "$$JSON_STRUCTURE" \
		--key-id "$$KMS_KEY_ID" \
		--tags "Key=Environment,Value=$(ENV_NAME)" "Key=Application,Value=$(APP_NAME)"
	echo "SSM parameter created/updated successfully"; \

deploy-byo-idc:
	@if [ -z "$(APP_NAME)" ] || [ -z "$(ENV_NAME)" ]; then \
		echo "Error: APP and ENV variables are required. Please set them using APP=<app-name> ENV=<environment>"; \
	fi; \
	echo ""; \
	echo "=== IAM Identity Center User Mapping ==="; \
	echo ""; \
	read -p "Enter Identity Store ID: " IDENTITY_STORE_ID; \
	echo ""; \
	echo "Note: You can separate multiple email addresses using either commas or spaces"; \
	echo "Example: user1@example.com,user2@example.com  or  user1@example.com user2@example.com"; \
	echo ""; \
	KMS_KEY_ID=$$(aws kms describe-key --key-id alias/aws/ssm --query 'KeyMetadata.KeyId' --output text); \
	JSON_STRUCTURE="{\"$$IDENTITY_STORE_ID\":{"; \
	for GROUP in "Admin" "Domain Owner" "Project Contributor" "Project Owner"; do \
		echo ""; \
		echo "=== $$GROUP Configuration ==="; \
		VALID_EMAILS=""; \
		while true; do \
			if [ "$$GROUP" = "Domain Owner" ] || [ "$$GROUP" = "Project Owner" ]; then \
				echo "Enter email addresses for $$GROUP"; \
				echo "(At least one valid email required)"; \
			else \
				echo "Enter email addresses for $$GROUP"; \
				echo "(Press enter if none)"; \
			fi; \
			echo -n "> "; \
			read EMAILS; \
			if [ ! -z "$$EMAILS" ]; then \
				EMAILS=$$(echo "$$EMAILS" | tr ',' ' '); \
				VALID_EMAILS=""; \
				for EMAIL in $$EMAILS; do \
					if echo "$$EMAIL" | grep -qE '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$$'; then \
						if [ -z "$$VALID_EMAILS" ]; then \
							VALID_EMAILS="$$EMAIL"; \
						else \
							VALID_EMAILS="$$VALID_EMAILS $$EMAIL"; \
						fi; \
					else \
						echo "⚠️  Warning: Invalid email format: $$EMAIL - skipping"; \
					fi; \
				done; \
			fi; \
			if [ "$$GROUP" = "Domain Owner" ] || [ "$$GROUP" = "Project Owner" ]; then \
				if [ -z "$$VALID_EMAILS" ]; then \
					echo "❌ Error: At least one valid email is required for $$GROUP. Please try again."; \
					echo ""; \
					continue; \
				fi; \
			fi; \
			break; \
		done; \
		if [ ! -z "$$VALID_EMAILS" ]; then \
			echo "✅ Valid emails accepted for $$GROUP"; \
			echo ""; \
			FORMATTED_EMAILS=$$(echo $$VALID_EMAILS | tr ' ' '\n' | awk -v ORS=, '{print "\""$$0"\""}' | sed 's/,$$/\n/'); \
			JSON_STRUCTURE="$$JSON_STRUCTURE\"$$GROUP\":[$$FORMATTED_EMAILS],"; \
		else \
			echo "ℹ️  No emails provided for $$GROUP"; \
			echo ""; \
			JSON_STRUCTURE="$$JSON_STRUCTURE\"$$GROUP\":[],"; \
		fi; \
	done; \
	JSON_STRUCTURE=$${JSON_STRUCTURE%,}; \
	JSON_STRUCTURE="$$JSON_STRUCTURE}}"; \
	echo ""; \
	echo "=== Review Configuration ==="; \
	echo ""; \
	echo "$$JSON_STRUCTURE" | jq .; \
	echo ""; \
	read -p "Do you want to proceed with creating/updating the SSM parameter? (y/n): " CONFIRM; \
	if [ "$$CONFIRM" = "y" ]; then \
		aws ssm put-parameter \
			--name "/$(APP_NAME)/$(ENV_NAME)/identity-center/users" \
			--description "Map of IAM Identity Center users and their group associations" \
			--type "SecureString" \
			--value "$$JSON_STRUCTURE" \
			--key-id "$$KMS_KEY_ID" \
			--tags "Key=Environment,Value=$(ENV_NAME)" "Key=Application,Value=$(APP_NAME)" && \
		echo ""; \
		echo "SSM parameter created/updated successfully"; \
	else \
		echo ""; \
		echo "Operation cancelled"; \
	fi

#################### Sagemaker Domain ####################

deploy-domain-prereq:
	@echo "Deploying Pre-requisites for SageMaker Studio Domain"
	(cd iac/roots/sagemaker/domain-prereq; \
		terraform init; \
		terraform apply -auto-approve;)
		@echo "Finished Deploying Pre-requisites for SageMaker Studio Domain"

destroy-domain-prereq:
	@echo "Destroying Pre-requisites for SageMaker Studio Domain"
	(cd iac/roots/sagemaker/domain-prereq; \
		terraform init; \
		terraform destroy -auto-approve;)
		@echo "Finished Destroying Pre-requisites for SageMaker Studio Domain"

deploy-domain:
	@echo "Deploying Sagemaker Studio Domain"
	(cd iac/roots/sagemaker/domain; \
		terraform init; \
		terraform apply -auto-approve;)
		@echo "Finished Deploying Sagemaker Studio Domain"

destroy-domain:
	@echo "Destroying Sagemaker Studio Domain"
	(cd iac/roots/sagemaker/domain; \
		terraform init; \
		terraform destroy -auto-approve;)
		@echo "Finished Destroying Sagemaker Studio Domain"

#################### Sagemaker Project ####################

deploy-project-prereq:
	@echo "Deploying Sagemaker Studio Domain Project Prereqs"
	(cd iac/roots/sagemaker/project-prereq; \
		terraform init; \
		terraform apply -auto-approve;)
		@echo "Finished Deploying Sagemaker Studio Domain Project Prereqs"

destroy-project-prereq:
	@echo "Destroying Sagemaker Studio Domain Project Prereqs"
	(cd iac/roots/sagemaker/project-prereq; \
		terraform init; \
		terraform destroy -auto-approve;)
		@echo "Finished Destroying Sagemaker Studio Domain Project Prereqs"

deploy-producer-project:
	@echo "Deploying Sagemaker Studio Domain Producer Project"
	(cd iac/roots/sagemaker/producer-project; \
		terraform init; \
		terraform apply -auto-approve;)
		@echo "Finished Deploying Sagemaker Studio Domain Producer Project"

destroy-producer-project:
	@echo "Destroying Sagemaker Studio Domain Producer Project"
	(cd iac/roots/sagemaker/producer-project; \
		terraform init; \
		terraform destroy -auto-approve;)
		@echo "Finished Destroying Sagemaker Studio Domain Producer Project"

deploy-consumer-project:
	@echo "Deploying Sagemaker Studio Domain Consumer Project"
	(cd iac/roots/sagemaker/consumer-project; \
		terraform init; \
		terraform apply -auto-approve;)
		@echo "Finished Deploying Sagemaker Studio Domain Consumer Project"

destroy-consumer-project:
	@echo "Destroying Sagemaker Studio Domain Consumer Project"
	(cd iac/roots/sagemaker/consumer-project; \
		terraform init; \
		terraform destroy -auto-approve;)
		@echo "Finished Destroying Sagemaker Studio Domain Consumer Project"

extract-producer-info:
	($(eval domain_id:=${shell aws datazone list-domains --query "items[?name=='Corporate'].id" --output text}) \
	 $(eval producer_project_id:=${shell aws datazone list-projects --domain-identifier ${domain_id} --query "items[?name=='Producer'].id" --output text}) \
	 aws ssm --region $(AWS_PRIMARY_REGION) put-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/producer/id --value ${shell aws datazone list-projects --domain-identifier ${domain_id} --query "items[?name=='Producer'].id" --output text} --type "String" --overwrite;\
	 $(eval stack_names:=${shell aws cloudformation list-stacks --no-paginate --stack-status-filter CREATE_COMPLETE --query 'StackSummaries[*].StackName' --output text}) \
	 $(eval tooling:=Tooling) \
	 $(foreach stack_name,$(stack_names), \
			$(if $(filter $(domain_id), $(shell aws cloudformation describe-stacks --stack-name $(stack_name) --query "Stacks[0].Tags[?Key=='AmazonDataZoneDomain'].Value" --output text)),\
				$(if $(filter $(producer_project_id),$(shell aws cloudformation describe-stacks --stack-name $(stack_name) --query "Stacks[0].Tags[?Key=='AmazonDataZoneProject'].Value" --output text)),\
					$(if $(filter $(tooling),$(shell aws cloudformation describe-stacks --stack-name $(stack_name) --query "Stacks[0].Tags[?Key=='AmazonDataZoneBlueprint'].Value" --output text)),\
						aws ssm --region $(AWS_PRIMARY_REGION) put-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/producer/role --value ${shell aws cloudformation describe-stacks --stack-name $(stack_name) --query "Stacks[0].Outputs[?OutputKey=='UserRole'].OutputValue" --output text} --type "String" --overwrite;\
						aws ssm --region $(AWS_PRIMARY_REGION) put-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/producer/role-name --value ${shell aws cloudformation describe-stacks --stack-name $(stack_name) --query "Stacks[0].Outputs[?OutputKey=='UserRoleName'].OutputValue" --output text} --type "String" --overwrite;\
						aws ssm --region $(AWS_PRIMARY_REGION) put-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/producer/security-group --value ${shell aws cloudformation describe-stacks --stack-name $(stack_name) --query "Stacks[0].Outputs[?OutputKey=='SecurityGroup'].OutputValue" --output text} --type "String" --overwrite;\
						aws ssm --region $(AWS_PRIMARY_REGION) put-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/producer/tooling-env-id --value ${shell aws cloudformation describe-stacks --stack-name $(stack_name) --query "Stacks[0].Tags[?Key=='AmazonDataZoneEnvironment'].Value" --output text} --type "String" --overwrite;\
						exit 0; \
					)\
				)\
			)\
	 ) \
	 )

extract-consumer-info:
	($(eval domain_id:=${shell aws datazone list-domains --query "items[?name=='Corporate'].id" --output text}) \
	 $(eval consumer_project_id:=${shell aws datazone list-projects --domain-identifier ${domain_id} --query "items[?name=='Consumer'].id" --output text}) \
	 aws ssm --region $(AWS_PRIMARY_REGION) put-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/consumer/id --value ${shell aws datazone list-projects --domain-identifier ${domain_id} --query "items[?name=='Consumer'].id" --output text} --type "String" --overwrite;\
	 $(eval stack_names:=${shell  aws cloudformation list-stacks --query 'StackSummaries[*].StackName' --output text}) \
	 $(eval tooling:=Tooling) \
	 $(foreach stack_name,$(stack_names), \
			$(if $(filter $(domain_id),$(shell aws cloudformation describe-stacks --stack-name $(stack_name) --query "Stacks[0].Tags[?Key=='AmazonDataZoneDomain'].Value" --output text)),\
				$(if $(filter $(consumer_project_id),$(shell aws cloudformation describe-stacks --stack-name $(stack_name) --query "Stacks[0].Tags[?Key=='AmazonDataZoneProject'].Value" --output text)),\
					$(if $(filter $(tooling),$(shell aws cloudformation describe-stacks --stack-name $(stack_name) --query "Stacks[0].Tags[?Key=='AmazonDataZoneBlueprint'].Value" --output text)),\
						aws ssm --region $(AWS_PRIMARY_REGION) put-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/consumer/role --value ${shell aws cloudformation describe-stacks --stack-name $(stack_name) --query "Stacks[0].Outputs[?OutputKey=='UserRole'].OutputValue" --output text} --type "String" --overwrite;\
						aws ssm --region $(AWS_PRIMARY_REGION) put-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/consumer/role-name --value ${shell aws cloudformation describe-stacks --stack-name $(stack_name) --query "Stacks[0].Outputs[?OutputKey=='UserRoleName'].OutputValue" --output text} --type "String" --overwrite;\
						exit 0; \
					)\
				)\
			)\
	 ) \
	 )

#################### Glue ####################

deploy-glue-jars:
	@echo "Downloading and Deploying Required JAR File"
	mkdir -p jars
	export DYNAMIC_RESOLUTION=y; \

	curl -o jars/s3-tables-catalog-for-iceberg-runtime-0.1.7.jar \
		"https://repo1.maven.org/maven2/software/amazon/s3tables/s3-tables-catalog-for-iceberg-runtime/0.1.7/s3-tables-catalog-for-iceberg-runtime-0.1.7.jar"
	
	aws s3 cp "jars/s3-tables-catalog-for-iceberg-runtime-0.1.7.jar" \
		"s3://$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-glue-jars/" \
		--region "$(AWS_PRIMARY_REGION)"
	
	rm -rf jars/
	@echo "Finished Downloading and Deploying Required JAR File"

#################### Lake Formation ####################

set-up-lake-formation-admin-role:
	aws lakeformation put-data-lake-settings \
		--cli-input-json "{\"DataLakeSettings\": {\"DataLakeAdmins\": [{\"DataLakePrincipalIdentifier\": \"arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ADMIN_ROLE}\"}]}}" \
		--region "${AWS_PRIMARY_REGION}"
		
create-glue-s3tables-catalog:
	aws glue create-catalog \
        --cli-input-json '{"Name": "s3tablescatalog", "CatalogInput": { "FederatedCatalog": { "Identifier": "arn:aws:s3tables:${AWS_PRIMARY_REGION}:${AWS_ACCOUNT_ID}:bucket/*", "ConnectionName": "aws:s3tables" }, "CreateDatabaseDefaultPermissions": [], "CreateTableDefaultPermissions": [] } }' \
        --region "${AWS_PRIMARY_REGION}"

register-s3table-catalog-with-lake-formation:
	aws lakeformation register-resource \
        --resource-arn "arn:aws:s3tables:${AWS_PRIMARY_REGION}:${AWS_ACCOUNT_ID}:bucket/*" \
        --role-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${APP_NAME}-${ENV_NAME}-lakeformation-service-role" \
        --with-federation \
        --region "${AWS_PRIMARY_REGION}"

grant-default-database-permissions:
	@echo "Checking default database and granting Lake Formation permissions"
	@if aws glue get-database --name default >/dev/null 2>&1; then \
		echo "Default database exists. Granting Lake Formation permissions..."; \
		aws lakeformation grant-permissions \
			--principal DataLakePrincipalIdentifier="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ADMIN_ROLE}" \
			--resource '{"Database": {"Name": "default"}}' \
			--permissions "DROP" \
			--region $(AWS_PRIMARY_REGION); \
		echo "Successfully granted Lake Formation permissions for default database"; \
	else \
		echo "Default database does not exist"; \
	fi

drop-default-database:
	aws glue delete-database --name default \
		--region $(AWS_PRIMARY_REGION) || true; \

#################### Athena ####################

deploy-athena:
	@echo "Deploying Athena"
	(cd iac/roots/athena; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Athena"

destroy-athena:
	@echo "Destroying Athena"
	(cd iac/roots/athena; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying Athena"

#################### Billing ####################

deploy-finops-billing-s3-glue-s3:
	@echo "Deploying Billing Infrastructure"
	(cd iac/roots/datalakes/finops-billing-s3-glue-s3; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Billing Infrastructure"

destroy-finops-billing-s3-glue-s3:

	@echo "Emptying S3 buckets"
	$(ENV_PATH)../build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-billing-s3-glue-s3-data" || true
	$(ENV_PATH)../build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-billing-s3-glue-s3-hive" || true
	$(ENV_PATH)../build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-billing-s3-glue-s3-iceberg" || true

	@echo "Destroying Billing Infrastructure"
	(cd iac/roots/datalakes/finops-billing-s3-glue-s3; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying Billing Infrastructure"

start-finops-billing-s3-glue-s3-hive-job:
	@echo "Starting Billing Hive Job"
	(aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name finops-billing-s3-glue-s3-hive)
	@echo "Started Billing Hive Job"

start-finops-billing-s3-glue-s3-iceberg-static-job:
	@echo "Starting Billing Iceberg Static Job"
	(aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name finops-billing-s3-glue-s3-iceberg-static)
	@echo "Started Billing Iceberg Static Job"

start-finops-billing-s3-glue-s3table-job:
	@echo "Starting Billing S3 Table Job"
	(aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name finops-billing-s3-glue-s3table;)
	@echo "Started Billing S3 Table Job"

grant-lake-formation-finops-billing-s3-glue-s3table-catalog:
	aws lakeformation grant-permissions \
		--principal DataLakePrincipalIdentifier="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ADMIN_ROLE}" \
		--resource "{\"Table\": {\"CatalogId\": \"${AWS_ACCOUNT_ID}:s3tablescatalog/finops-billing-s3-glue-s3table\", \"DatabaseName\": \"${APP_NAME}\", \"Name\": \"finops_billing_s3_glue_s3table\"}}" \
		--permissions ALL \
		--permissions-with-grant-option ALL \
		--region "$(AWS_PRIMARY_REGION)"

start-finops-billing-s3-glue-s3-hive-data-quality-ruleset:
	@echo "Starting Billing Hive Data Quality Ruleset"
	aws glue start-data-quality-ruleset-evaluation-run \
		--region $(AWS_PRIMARY_REGION) \
		--role "$(APP_NAME)-$(ENV_NAME)-glue-role"  \
		--ruleset-names "finops_billing_s3_glue_s3_hive_ruleset" \
		--data-source '{"GlueTable":{"DatabaseName":"finops_billing_s3_glue_s3","TableName":"finops_billing_s3_glue_s3_hive"}}'

	@echo "Started Billing Hive Data Quality Ruleset"

start-billing-s3-glue-s3-iceberg-data-quality-ruleset:
	@echo "Starting Billing Iceberg Data Quality Ruleset"
	aws glue start-data-quality-ruleset-evaluation-run \
		--region $(AWS_PRIMARY_REGION) \
		--role "$(APP_NAME)-$(ENV_NAME)-glue-role"  \
		--ruleset-names "finops_billing_s3_glue_s3_iceberg_ruleset" \
		--data-source '{"GlueTable":{"DatabaseName":"finops_billing_s3_glue_s3","TableName":"finops_billing_s3_glue_s3_iceberg_static"}}'
	@echo "Started Billing Iceberg Data Quality Ruleset"

upload-billing-s3-glue-s3-iceberg-dynamic-report-1:
	@echo "Starting Upload of Billing Report 1 to trigger dynamic Glue Workflow"
	aws s3 cp \
		data/billing/dynamic/cost-and-usage-report-00002.csv.gz \
		s3://${AWS_ACCOUNT_ID}-$(APP_NAME)-$(ENV_NAME)-finops-billing-s3-glue-s3-data/billing/$(APP_NAME)-$(ENV_NAME)-cost-and-usage-report/manual/
	@echo "Finished Upload of Billing Report 1"

upload-billing-s3-glue-s3-iceberg-dynamic-report-2:
	@echo "Starting Upload of Billing Report 2 to trigger dynamic Glue Workflow"
	aws s3 cp \
		data/billing/dynamic/cost-and-usage-report-00003.csv.gz \
		s3://${AWS_ACCOUNT_ID}-$(APP_NAME)-$(ENV_NAME)-finops-billing-s3-glue-s3-data/billing/$(APP_NAME)-$(ENV_NAME)-cost-and-usage-report/manual/
	@echo "Finished Upload of Billing Report 2"

grant-lake-formation-billing-s3-glue-s3-iceberg-dynamic:
	aws lakeformation grant-permissions \
    	--principal DataLakePrincipalIdentifier="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ADMIN_ROLE}" \
        --resource "{\"Table\": {\"DatabaseName\": \"finops_billing_s3_glue_s3\", \"Name\": \"finops_billing_s3_glue_s3_iceberg_dynamic\"}}" \
        --permissions ALL \
        --permissions-with-grant-option ALL \
        --region "$(AWS_PRIMARY_REGION)"

activate-finops-s3-glue-s3-cost-allocation-tags:
	@echo "Activating Cost Allocation Tags"
	aws ce update-cost-allocation-tags-status \
        --region us-east-1 \
        --cost-allocation-tags-status '[{"TagKey":"Application","Status":"Active"},{"TagKey":"Environment","Status":"Active"},{"TagKey":"Usage","Status":"Active"}]'
	@echo "Finished Activating Cost Allocation Tags"

deploy-finops-s3-glue-s3-billing-cur:
	@echo "Deploying Billing CUR Report"
	(cd iac/roots/datalakes/finops-billing-s3-glue-s3-cur; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Billing CUR Report"

destroy-finops-s3-glue-s3-billing-cur:
	@echo "Destroying Billing CUR Report"
	(cd iac/roots/datalakes/finops-billing-s3-glue-s3-cur; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished DDestroying Billing CUR Report"

#################### Inventory ####################

download-finops-inventory-sec-reports:
	@echo "Downloading Costco SEC Reports"
	@mkdir -p /tmp/costco-sec
	
	# Format Costco's CIK with leading zeros
	$(eval COSTCO_CIK := $(shell printf "%010d" 909832))
	
	# Download Costco's submissions data
	@curl -H "User-Agent: $(APP_NAME)-$(ENV_NAME)-inventory-downloader" \
		-o /tmp/costco-sec/submissions.json \
		"https://data.sec.gov/submissions/CIK$(COSTCO_CIK).json"
	
	# Upload to S3
	@aws s3 cp "/tmp/costco-sec/submissions.json" \
		"s3://$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-finops-inventory-s3-glue-s3-source/" \
		--region "$(AWS_PRIMARY_REGION)"
	
	# Download company facts
	@curl -H "User-Agent: $(APP_NAME)-$(ENV_NAME)-inventory-downloader" \
		-o /tmp/costco-sec/company_facts.json \
		"https://data.sec.gov/api/xbrl/companyfacts/CIK$(COSTCO_CIK).json"
	
	# Upload company facts to S3
	@aws s3 cp "/tmp/costco-sec/company_facts.json" \
		"s3://$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-finops-inventory-s3-glue-s3-source/" \
		--region "$(AWS_PRIMARY_REGION)"

	# Download last 5 years of 10-K and 10-Q reports
	@for year in {2019..2023}; do \
		echo "Downloading reports for $$year"; \
		for form in "10-K" "10-Q"; do \
			curl -H "User-Agent: $(APP_NAME)-$(ENV_NAME)-inventory-downloader" \
				-o "/tmp/costco-sec/$$form-$$year.htm" \
				"https://www.sec.gov/Archives/edgar/data/909832/$$year/*.$$form"; \
			aws s3 cp "/tmp/costco-sec/$$form-$$year.htm" \
				"s3://$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-finops-inventory-s3-glue-s3-source/" \
				--region "$(AWS_PRIMARY_REGION)"; \
			sleep 0.1; \
		done; \
	done
	
	@rm -rf /tmp/costco-sec
	@echo "Finished downloading Costco SEC Reports"

deploy-finops-inventory-s3-glue-s3:
	@echo "Deploying Inventory Infrastructure"
	(cd iac/roots/datalakes/finops-inventory-s3-glue-s3; \
		terraform init; \
		terraform apply -auto-approve;)
		@echo "Downloading SEC reports..."
		@$(MAKE) download-finops-inventory-sec-reports
		@echo "Finished Deploying Inventory Infrastructure"

destroy-finops-inventory-s3-glue-s3:

	@echo "Emptying S3 buckets"
	$(ENV_PATH)../build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-inventory-source" || true
	$(ENV_PATH)../build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-inventory-target" || true
	$(ENV_PATH)../build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-inventory-hive" || true
	$(ENV_PATH)../build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-inventory-iceberg" || true

	@echo "Destroying Inventory Infrastructure and Job"
	(cd iac/roots/datalakes/finops-inventory-s3-glue-s3; \
		terraform init; \
		terraform destroy -auto-approve;)
		@echo "Finished Destroying Inventory Infrastructure and Job"

start-finops-inventory-s3-glue-s3-hive-job:
	@echo "Starting Inventory Job"
	(aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name finops-inventory-s3-glue-s3-hive)
	@echo "Started Inventory Job"

start-finops-inventory-s3-glue-s3-iceberg-static-job:
	@echo "Starting Inventory Iceberg Static Job"
	(aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name finops-inventory-s3-glue-s3-iceberg-static)
	@echo "Started Inventory Iceberg Static Job"

start-finops-inventory-s3-glue-s3table-job:
	@echo "Starting Inventory S3 Job"
	(aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name finops-inventory-s3-glue-s3table)
	@echo "Started Inventory S3 Table Job"

grant-lake-formation-inventory-s3-glue-s3table-catalog:
	aws lakeformation grant-permissions \
		--principal DataLakePrincipalIdentifier="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ADMIN_ROLE}" \
		--resource "{\"Table\": {\"CatalogId\": \"${AWS_ACCOUNT_ID}:s3tablescatalog/finops-inventory-s3-glue-s3table\", \"DatabaseName\": \"${APP_NAME}\", \"Name\": \"finops_inventory_s3_glue_s3table\"}}" \
		--permissions ALL \
		--permissions-with-grant-option ALL \
		--region "$(AWS_PRIMARY_REGION)"

start-inventory-s3-glue-s3-hive-data-quality-ruleset:
	@echo "Starting Inventory Hive Data Quality Ruleset"
	aws glue start-data-quality-ruleset-evaluation-run \
		--region $(AWS_PRIMARY_REGION) \
		--role "$(APP_NAME)-$(ENV_NAME)-glue-role"  \
		--ruleset-names "finops-inventory-s3-glue-s3-hive-ruleset" \
        --data-source '{"GlueTable":{"DatabaseName":"finops_inventory_s3_glue_s3","TableName":"finops_inventory_s3_glue_s3_hive"}}'
	@echo "Started Inventory Hive Data Quality Ruleset"

start-inventory-s3-glue-s3-iceberg-data-quality-ruleset:
	@echo "Starting Inventory Iceberg Data Quality Ruleset"
	aws glue start-data-quality-ruleset-evaluation-run \
		--region $(AWS_PRIMARY_REGION) \
		--role "$(APP_NAME)-$(ENV_NAME)-glue-role"  \
		--ruleset-names "finops-inventory-s3-glue-s3-iceberg-ruleset" \
		--data-source '{"GlueTable":{"DatabaseName":"finops_inventory_s3_glue_s3","TableName":"finops_inventory_s3_glue_s3_iceberg_static"}}'
	@echo "Started Inventory Iceberg Data Quality Ruleset"

upload-inventory-s3-glue-s3-iceber-dynamic-report-1:
	@echo "Starting Upload of Inventory Report 1 to trigger dynamic Glue Workflow"
	aws s3 cp \
		data/inventory/dynamic/bc8bbf78-546e-4a5b-ac3d-d5dae9ffadab.csv.gz \
		s3://${AWS_ACCOUNT_ID}-$(APP_NAME)-$(ENV_NAME)-finops-inventory-s3-glue-s3-target/${AWS_ACCOUNT_ID}-$(APP_NAME)-$(ENV_NAME)-finops-inventory-s3-glue-s3-source/InventoryConfig/data/
	@echo "Finished Upload of Inventory Report 1"

upload-inventory-s3-glue-s3-iceber-dynamic-report-2:
	@echo "Starting Upload of Inventory Report 2 to trigger dynamic Glue Workflow"
	aws s3 cp \
		data/inventory/dynamic/b359c3d9-b58e-4f23-aee4-4b75ab78b3bb.csv.gz \
		s3://${AWS_ACCOUNT_ID}-$(APP_NAME)-$(ENV_NAME)-finops-inventory-s3-glue-s3-target/${AWS_ACCOUNT_ID}-$(APP_NAME)-$(ENV_NAME)-finops-inventory-s3-glue-s3-source/InventoryConfig/data/
	@echo "Finished Upload of Inventory Report 2"

grant-lake-formation-inventory-s3-glue-s3-iceberg-dynamic:
	aws lakeformation grant-permissions \
    	--principal DataLakePrincipalIdentifier="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ADMIN_ROLE}" \
        --resource "{\"Table\": {\"DatabaseName\": \"finops_inventory_s3_glue_s3\", \"Name\": \"finops_inventory_s3_glue_s3_iceberg_dynamic\"}}" \
        --permissions ALL \
        --permissions-with-grant-option ALL \
        --region "$(AWS_PRIMARY_REGION)"

#################### Splunk ####################

deploy-finops-usage-splunk-glue-s3:
	@echo "Deploying Splunk"
	(cd iac/roots/datalakes/finops-usage-splunk-glue-s3; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Splunk"

destroy-finops-usage-splunk-glue-s3:

	@echo "Emptying S3 buckets"
	$(ENV_PATH)../build-script/empty-s3.sh empty_s3_bucket_by_name "${AWS_ACCOUNT_ID}-$(APP_NAME)-$(ENV_NAME)-finops-usage-splunk-glue-s3-iceberg" || true

	@echo "Destroying Splunk"
	(cd iac/roots/datalakes/finops-usage-splunk-glue-s3; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying Splunk"

start-finops-usage-splunk-glue-s3-iceberg-job:
	@echo "Starting Splunk Iceberg Static Job"
	aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name finops-usage-splunk-glue-s3-iceberg
	@echo "Started Splunk Iceberg Static Job"

start-finops-usage-splunk-glue-s3table-job:
	@echo "Starting Splunk S3 Table Job"
	aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name finops-usage-splunk-glue-s3table
	@echo "Started Splunk S3 Table Job"

grant-lake-formation-finops-usage-splunk-glue-s3table-catalog:
	aws lakeformation grant-permissions \
		--principal DataLakePrincipalIdentifier="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ADMIN_ROLE}" \
		--resource "{\"Table\": {\"CatalogId\": \"${AWS_ACCOUNT_ID}:s3tablescatalog/finops-usage-splunk-glue-s3table\", \"DatabaseName\": \"${APP_NAME}\", \"Name\": \"finops_usage_splunk_glue_s3table\"}}" \
		--permissions ALL \
		--permissions-with-grant-option ALL \
		--region "$(AWS_PRIMARY_REGION)"

###################### Equity Price S3 Glue S3 #################################

run-equity-price-file-generator:
	@echo "Running Equity Price Generator"
	(cd iac/roots/common/file-generator; \
	python price_generator.py;)
	@echo "Finished Running Equity Price Generator"

deploy-equity-price-s3-glue-s3:
	@echo "Deploying Equity Price Infrastructure"
	(cd iac/roots/datalakes/equity-price-s3-glue-s3; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Equity Price Infrastructure"

destroy-equity-price-s3-glue-s3:

	@echo "Emptying S3 buckets"
	build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-equity-price-s3-glue-s3-data" || true
	build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-equity-price-s3-glue-s3-hive" || true
	build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-equity-price-s3-glue-s3-iceberg" || true

	@echo "Destroying Equity Price Infrastructure"
	(cd iac/roots/datalakes/equity-price-s3-glue-s3; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished DepDestroyingloying Equity Price Infrastructure"

start-equity-price-s3-glue-s3-hive-job:
	@echo "Starting Equity Price Hive Job"
	(aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name equity-price-s3-glue-s3-hive)
	@echo "Started Equity Price Hive Job"

start-equity-price-s3-glue-s3-iceberg-job:
	@echo "Starting Equity Price Iceberg Static Job"
	(aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name equity-price-s3-glue-s3-iceberg)
	@echo "Started Equity Price Iceberg Static Job"

start-equity-price-s3-glue-s3table-job:
	@echo "Starting Equity Price S3 Table Job"
	(aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name equity-price-s3-glue-s3table)
	@echo "Started Equity Price S3 Table Job"

grant-lake-formation-equity-price-s3-glue-s3table-catalog:
	aws lakeformation grant-permissions \
		--principal DataLakePrincipalIdentifier="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ADMIN_ROLE}" \
		--resource "{\"Table\": {\"CatalogId\": \"${AWS_ACCOUNT_ID}:s3tablescatalog/equity-price-s3-glue-s3table\", \"DatabaseName\": \"${APP_NAME}\", \"Name\": \"equity_price_s3_glue_s3table\"}}" \
		--permissions ALL \
		--permissions-with-grant-option ALL \
		--region "$(AWS_PRIMARY_REGION)"

start-equity-price-s3-glue-s3-hive-data-quality-ruleset:
	@echo "Starting Equity Price Hive Data Quality Ruleset"
	aws glue start-data-quality-ruleset-evaluation-run \
		--region $(AWS_PRIMARY_REGION) \
		--role "$(APP_NAME)-$(ENV_NAME)-glue-role"  \
		--ruleset-names "equity_price_s3_glue_s3_hive_ruleset" \
		--data-source '{"GlueTable":{"DatabaseName":"equity_price_s3_glue_s3","TableName":"equity_price_s3_glue_s3_hive"}}'
	@echo "Started Equity Price Hive Data Quality Ruleset"

start-equity-price-s3-glue-s3-iceberg-data-quality-ruleset:
	@echo "Starting Equity Price Iceberg Data Quality Ruleset"
	aws glue start-data-quality-ruleset-evaluation-run \
		--region $(AWS_PRIMARY_REGION) \
		--role "$(APP_NAME)-$(ENV_NAME)-glue-role"  \
		--ruleset-names "equity_price_s3_glue_s3_iceberg_ruleset" \
		--data-source '{"GlueTable":{"DatabaseName":"equity_price_s3_glue_s3","TableName":"equity_price_s3_glue_s3_iceberg"}}'
	@echo "Started Equity Price Iceberg Data Quality Ruleset"

###################### Equity Trade S3 Glue S3 #################################

run-equity-trade-file-generator:
	@echo "Running Equity Trade Generator"
	(cd iac/roots/common/file-generator; \
	python equity_trade_generator.py;)
	@echo "Finished Running Equity Trade Generator"

deploy-equity-trade-s3-glue-s3:
	@echo "Deploying Equity Trade Infrastructure"
	(cd iac/roots/datalakes/equity-trade-s3-glue-s3; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Trade Infrastructure"

destroy-equity-trade-s3-glue-s3:

	@echo "Emptying S3 buckets"
	build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-equity-trade-s3-glue-s3-data" || true
	build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-equity-trade-s3-glue-s3-hive" || true
	build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-equity-trade-s3-glue-s3-iceberg" || true

	@echo "Destroying Equity Trade Infrastructure"
	(cd iac/roots/datalakes/equity-trade-s3-glue-s3; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished DepDestroyingloying Equity Trade Infrastructure"

start-equity-trade-s3-glue-s3-hive-job:
	@echo "Starting Equity Trade Hive Job"
	(aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name equity-trade-s3-glue-s3-hive)
	@echo "Started Equity Trade Hive Job"

start-equity-trade-s3-glue-s3-iceberg-job:
	@echo "Starting Equity Trade Iceberg Static Job"
	(aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name equity-trade-s3-glue-s3-iceberg)
	@echo "Started Equity Trade Iceberg Static Job"

start-equity-trade-s3-glue-s3table-job:
	@echo "Starting Equity Trade S3 Table Job"
	(aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name equity-trade-s3-glue-s3table)
	@echo "Started Equity Trade S3 Table Job"

grant-lake-formation-equity-trade-s3-glue-s3table-catalog:
	aws lakeformation grant-permissions \
		--principal DataLakePrincipalIdentifier="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ADMIN_ROLE}" \
		--resource "{\"Table\": {\"CatalogId\": \"${AWS_ACCOUNT_ID}:s3tablescatalog/equity-trade-s3-glue-s3table\", \"DatabaseName\": \"${APP_NAME}\", \"Name\": \"equity_trade_s3_glue_s3table\"}}" \
		--permissions ALL \
		--permissions-with-grant-option ALL \
		--region "$(AWS_PRIMARY_REGION)"

start-equity-trade-s3-glue-s3-hive-data-quality-ruleset:
	@echo "Starting Equity Trade Hive Data Quality Ruleset"
	aws glue start-data-quality-ruleset-evaluation-run \
		--region $(AWS_PRIMARY_REGION) \
		--role "$(APP_NAME)-$(ENV_NAME)-glue-role"  \
		--ruleset-names "equity_trade_s3_glue_s3_hive_ruleset" \
		--data-source '{"GlueTable":{"DatabaseName":"equity_trade_s3_glue_s3","TableName":"equity_trade_s3_glue_s3_hive"}}'
	@echo "Started Equity Trade Data Quality Ruleset"

start-equity-trade-s3-glue-s3-iceberg-data-quality-ruleset:
	@echo "Starting Equity Trade Iceberg Data Quality Ruleset"
	aws glue start-data-quality-ruleset-evaluation-run \
		--region $(AWS_PRIMARY_REGION) \
		--role "$(APP_NAME)-$(ENV_NAME)-glue-role"  \
		--ruleset-names "equity_trade_s3_glue_s3_iceberg_ruleset" \
		--data-source '{"GlueTable":{"DatabaseName":"equity_trade_s3_glue_s3","TableName":"equity_trade_s3_glue_s3_iceberg"}}'
	@echo "Started Equity Trade Iceberg Data Quality Ruleset"

######################## Equity Trade MSK Glue S3 ################################

deploy-equity-trade-msk-glue-s3:
	@echo "Deploying Equity Trade Infrastructure"
	(cd iac/roots/datalakes/equity-trade-msk-glue-s3; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Equity Trade Infrastructure"

destroy-equity-trade-msk-glue-s3:
	@echo "Emptying S3 buckets"
	build-script/empty-s3.sh empty_s3_bucket_by_name "${AWS_ACCOUNT_ID}-$(APP_NAME)-$(ENV_NAME)-trade-hive" || true
	build-script/empty-s3.sh empty_s3_bucket_by_name "${AWS_ACCOUNT_ID}-$(APP_NAME)-$(ENV_NAME)-trade-iceberg" || true
	@echo "Destroying Trade Infrastructure"
	(cd iac/roots/datalakes/equity-trade-msk-glue-s3; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying Trade Infrastructure"

start-equity-trade-msk-glue-s3-job:
	@echo "Starting Eqity Trade Job"
	(aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name equity-trade-msk-glue-s3)
	@echo "Started Trade Job"

run-equity-trade-msk-glue-s3-test-harness:
	@echo "Starting Test Harness Lambda"
	(aws lambda invoke --region $(AWS_PRIMARY_REGION) --function-name $(APP_NAME)-$(ENV_NAME)-msk-producer-lambda --payload '{"body" : "{\"topic\" : \"trade-topic\", \"duration\" : 1}"}' response.json --cli-binary-format raw-in-base64-out --cli-read-timeout 900;)
	@echo "Finished Starting Test Harness Lambda"

###################### Equity Trade MSK Flink MSK ##############################

build-equity-trade-msk-flink-msk-app:
	cd iac/roots/datalakes/equity-trade-msk-flink-msk/java-app/msf && \
	mvn clean package

deploy-equity-trade-msk-flink-msk:
	@echo "Deploying Equity Trade Infrastructure"
	(cd iac/roots/datalakes/equity-trade-msk-flink-msk; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Equity Trade Infrastructure"

destroy-equity-trade-msk-flink-msk:
	@echo "Destroying Equity Trade Infrastructure"
	(cd iac/roots/datalakes/equity-trade-msk-flink-msk; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying Equity Trade Infrastructure"

run-equity-trade-msk-flink-msk-test-harness:
	@echo "Starting Test Harness Lambda"
	(aws lambda invoke --region $(AWS_PRIMARY_REGION) --function-name $(APP_NAME)-$(ENV_NAME)-msk-producer-lambda --payload '{"body" : "{\"duration\" : 1}"}' response.json --cli-binary-format raw-in-base64-out --cli-read-timeout 900;)
	@echo "Finished Starting Test Harness Lambda"

#################### Z-ETL Dynamodb #####################

deploy-equity-order-dd-zetl-s3-prereq:
	@echo "Deploying Z-ETL DynamoDB Pre-requisites"
	(cd iac/roots/z-etl/dynamodb/equity-order-dd-zetl-s3-prereq; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Z-ETL DynamoDB Pre-requisites"

destroy-equity-order-dd-zetl-s3-prereq:
	@echo "Emptying S3 buckets"
	$(ENV_PATH)../build-script/empty-s3.sh empty_s3_bucket_by_name "${AWS_ACCOUNT_ID}-$(APP_NAME)-$(ENV_NAME)-equity-order-dd-zetl-s3-data" || true

	@echo "Destroying Z-ETL DynamoDB Pre-requisites"
	(cd iac/roots/z-etl/dynamodb/equity-order-dd-zetl-s3-prereq; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying Z-ETL DynamoDB Pre-requisites"

deploy-equity-order-dd-zetl-s3:
	@echo "Deploying Z-ETL DynamoDB"
	(cd iac/roots/z-etl/dynamodb/equity-order-dd-zetl-s3; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Z-ETL DynamoDB"

destroy-equity-order-dd-zetl-s3:
	@echo "Emptying S3 buckets"
	$(ENV_PATH)../build-script/empty-s3.sh empty_s3_bucket_by_name "${AWS_ACCOUNT_ID}-${APP_NAME}-${ENV_NAME}-equity-order-dd-zetl-s3" || true

	@echo "Destroying Z-ETL DynamoDB"
	(cd iac/roots/z-etl/dynamodb/equity-order-dd-zetl-s3; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying Z-ETL DynamoDB"

#################### Project Configuration ####################

deploy-project-config:
	@echo "Deploying Project Configuration"
	(cd iac/roots/sagemaker/project-config; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Project Configuration"

destroy-project-config:
	@echo "Destroying Project Configuration"
	(cd iac/roots/sagemaker/project-config; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying Project Configuration"

deploy-project-user:
	@echo "Deploying Project User"
	(cd iac/roots/sagemaker/project-user; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Project User"

finops-billing-s3-glue-s3-grant-producer-s3tables-catalog-permissions:
	@echo "Grant Producer S3Tables Catalog Permissions"
	$(eval producer_role_arn:=$(shell aws ssm --region $(AWS_PRIMARY_REGION) get-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/producer/role --query Parameter.Value --output text))
	aws lakeformation grant-permissions \
    	--principal DataLakePrincipalIdentifier="$(producer_role_arn)" \
    	--resource "{\"Table\": {\"CatalogId\": \"$(AWS_ACCOUNT_ID):s3tablescatalog/finops-billing-s3-glue-s3table\", \"DatabaseName\": \"$(APP_NAME)\", \"Name\": \"finops_billing_s3_glue_s3table\"}}" \
    	--permissions ALL \
    	--region "$(AWS_PRIMARY_REGION)"
	@echo "Finished granting Producer S3Tables Catalog Permissions"

finops-billing-s3-glue-s3-grant-consumer-s3tables-catalog-permissions:
	@echo "Grant Consumer S3Tables Catalog Permissions"
	$(eval consumer_role_arn:=$(shell aws ssm --region $(AWS_PRIMARY_REGION) get-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/consumer/role --query Parameter.Value --output text))
	aws lakeformation grant-permissions \
    	--principal DataLakePrincipalIdentifier="$(consumer_role_arn)" \
    	--resource "{\"Table\": {\"CatalogId\": \"$(AWS_ACCOUNT_ID):s3tablescatalog/finops-billing-s3-glue-s3table\", \"DatabaseName\": \"$(APP_NAME)\", \"Name\": \"finops_billing_s3_glue_s3table\"}}" \
    	--permissions ALL \
    	--region "$(AWS_PRIMARY_REGION)"
	@echo "Finished Consumer Project Configuration"

finops-inventory-s3-glue-s3-grant-producer-s3tables-catalog-permissions:
	@echo "Grant Producer S3Tables Catalog Permissions"
	$(eval producer_role_arn:=$(shell aws ssm --region $(AWS_PRIMARY_REGION) get-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/producer/role --query Parameter.Value --output text))
	aws lakeformation grant-permissions \
    	--principal DataLakePrincipalIdentifier="$(producer_role_arn)" \
    	--resource "{\"Table\": {\"CatalogId\": \"$(AWS_ACCOUNT_ID):s3tablescatalog/finops-inventory-s3-glue-s3table\", \"DatabaseName\": \"$(APP_NAME)\", \"Name\": \"finops_inventory_s3_glue_s3table\"}}" \
    	--permissions ALL \
    	--region "$(AWS_PRIMARY_REGION)"
	@echo "Finished granting Producer S3Tables Catalog Permissions"

finops-inventory-s3-glue-s3-grant-consumer-s3tables-catalog-permissions:
	@echo "Grant Consumer S3Tables Catalog Permissions"
	$(eval consumer_role_arn:=$(shell aws ssm --region $(AWS_PRIMARY_REGION) get-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/consumer/role --query Parameter.Value --output text))
	aws lakeformation grant-permissions \
    	--principal DataLakePrincipalIdentifier="$(consumer_role_arn)" \
    	--resource "{\"Table\": {\"CatalogId\": \"$(AWS_ACCOUNT_ID):s3tablescatalog/finops-inventory-s3-glue-s3table\", \"DatabaseName\": \"$(APP_NAME)\", \"Name\": \"finops_inventory_s3_glue_s3table\"}}" \
    	--permissions ALL \
    	--region "$(AWS_PRIMARY_REGION)"
	@echo "Finished Consumer Project Configuration"

finops-usage-splunk-glue-s3-grant-producer-s3tables-catalog-permissions:
	@echo "Grant Producer S3Tables Catalog Permissions"
	$(eval producer_role_arn:=$(shell aws ssm --region $(AWS_PRIMARY_REGION) get-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/producer/role --query Parameter.Value --output text))
	aws lakeformation grant-permissions \
    	--principal DataLakePrincipalIdentifier="$(producer_role_arn)" \
    	--resource "{\"Table\": {\"CatalogId\": \"$(AWS_ACCOUNT_ID):s3tablescatalog/finops-usage-splunk-glue-s3table\", \"DatabaseName\": \"$(APP_NAME)\", \"Name\": \"finops_usage_splunk_glue_s3table\"}}" \
    	--permissions ALL \
    	--region "$(AWS_PRIMARY_REGION)"
	@echo "Finished granting Producer S3Tables Catalog Permissions"

finops-usage-splunk-glue-s3-grant-consumer-s3tables-catalog-permissions:
	@echo "Granting Consumer S3Tables Catalog Permissions"
	$(eval consumer_role_arn:=$(shell aws ssm --region $(AWS_PRIMARY_REGION) get-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/consumer/role --query Parameter.Value --output text))
	aws lakeformation grant-permissions \
    	--principal DataLakePrincipalIdentifier="$(consumer_role_arn)" \
    	--resource "{\"Table\": {\"CatalogId\": \"$(AWS_ACCOUNT_ID):s3tablescatalog/finops-usage-splunk-glue-s3table\", \"DatabaseName\": \"$(APP_NAME)\", \"Name\": \"finops_usage_splunk_glue_s3table\"}}" \
    	--permissions ALL \
    	--region "$(AWS_PRIMARY_REGION)"
	@echo "Finished Granting Consumer S3Tables Catalog Permissions"

equity-price-s3-glue-s3-grant-producer-s3tables-catalog-permissions:
	@echo "Grant Producer S3Tables Catalog Permissions"
	$(eval producer_role_arn:=$(shell aws ssm --region $(AWS_PRIMARY_REGION) get-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/producer/role --query Parameter.Value --output text))
	aws lakeformation grant-permissions \
    	--principal DataLakePrincipalIdentifier="$(producer_role_arn)" \
    	--resource "{\"Table\": {\"CatalogId\": \"$(AWS_ACCOUNT_ID):s3tablescatalog/equity-price-s3-glue-s3table\", \"DatabaseName\": \"$(APP_NAME)\", \"Name\": \"equity_price_s3_glue_s3table\"}}" \
    	--permissions ALL \
    	--region "$(AWS_PRIMARY_REGION)"
	@echo "Finished granting Producer S3Tables Catalog Permissions"

equity-price-s3-glue-s3-grant-consumer-s3tables-catalog-permissions:
	@echo "Grant Producer S3Tables Catalog Permissions"
	$(eval consumer_role_arn:=$(shell aws ssm --region $(AWS_PRIMARY_REGION) get-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/consumer/role --query Parameter.Value --output text))
	aws lakeformation grant-permissions \
    	--principal DataLakePrincipalIdentifier="$(consumer_role_arn)" \
    	--resource "{\"Table\": {\"CatalogId\": \"$(AWS_ACCOUNT_ID):s3tablescatalog/equity-price-s3-glue-s3table\", \"DatabaseName\": \"$(APP_NAME)\", \"Name\": \"equity_price_s3_glue_s3table\"}}" \
    	--permissions ALL \
    	--region "$(AWS_PRIMARY_REGION)"
	@echo "Finished granting Producer S3Tables Catalog Permissions"	

equity-trade-s3-glue-s3-grant-producer-s3tables-catalog-permissions:
	@echo "Grant Producer S3Tables Catalog Permissions"
	$(eval producer_role_arn:=$(shell aws ssm --region $(AWS_PRIMARY_REGION) get-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/producer/role --query Parameter.Value --output text))
	aws lakeformation grant-permissions \
    	--principal DataLakePrincipalIdentifier="$(producer_role_arn)" \
    	--resource "{\"Table\": {\"CatalogId\": \"$(AWS_ACCOUNT_ID):s3tablescatalog/equity-trade-s3-glue-s3table\", \"DatabaseName\": \"$(APP_NAME)\", \"Name\": \"equity_trade_s3_glue_s3table\"}}" \
    	--permissions ALL \
    	--region "$(AWS_PRIMARY_REGION)"
	@echo "Finished granting Producer S3Tables Catalog Permissions"

equity-trade-s3-glue-s3-grant-consumer-s3tables-catalog-permissions:
	@echo "Grant Producer S3Tables Catalog Permissions"
	$(eval consumer_role_arn:=$(shell aws ssm --region $(AWS_PRIMARY_REGION) get-parameter --name /$(APP_NAME)/$(ENV_NAME)/sagemaker/producer/role --query Parameter.Value --output text))
	aws lakeformation grant-permissions \
    	--principal DataLakePrincipalIdentifier="$(consumer_role_arn)" \
    	--resource "{\"Table\": {\"CatalogId\": \"$(AWS_ACCOUNT_ID):s3tablescatalog/equity-trade-s3-glue-s3table\", \"DatabaseName\": \"$(APP_NAME)\", \"Name\": \"equity_trade_s3_glue_s3table\"}}" \
    	--permissions ALL \
    	--region "$(AWS_PRIMARY_REGION)"
	@echo "Finished granting Producer S3Tables Catalog Permissions"	

#################### SageMaker Unified Studio Lakehouse Snowflake Connection for Producer ####################

deploy-snowflake-connection:
	@echo "--- SageMaker Lakehouse Snowflake Connection Setup for Producer Project ---"
	@echo "This will create a SageMaker Unified Studio Lakehouse data source connection to Snowflake."
	@echo "VPC details (Subnet, AZ, Security Groups) and Athena spill bucket/prefix will be retrieved/derived automatically."
	@echo "You will be prompted for Snowflake credentials (username/password) which will be stored in a new AWS Secrets Manager secret."
	@echo "You will also be prompted for other Snowflake connection details."
	@echo ""
	@read -p "Enter Snowflake Connection Name you want to use [default: 'snowflake']: " SNOWFLAKE_CONNECTION_NAME; \
	SNOWFLAKE_CONNECTION_NAME=$${SNOWFLAKE_CONNECTION_NAME:-'snowflake'}; \
	read -p "Enter Snowflake Username: " SNOWFLAKE_USERNAME; \
	if [ -z "$$SNOWFLAKE_USERNAME" ]; then echo "Snowflake Username cannot be empty."; exit 1; fi; \
	read -sp "Enter Snowflake Password: " SNOWFLAKE_PASSWORD; echo; \
	if [ -z "$$SNOWFLAKE_PASSWORD" ]; then echo "Snowflake Password cannot be empty."; exit 1; fi; \
	read -p "Enter Snowflake Host (e.g., youraccount.snowflakecomputing.com): " SNOWFLAKE_HOST; \
	if [ -z "$$SNOWFLAKE_HOST" ]; then echo "Snowflake Host cannot be empty."; exit 1; fi; \
	read -p "Enter Snowflake Port [default: 443]: " SNOWFLAKE_PORT; \
	SNOWFLAKE_PORT=$${SNOWFLAKE_PORT:-443}; \
	read -p "Enter Snowflake Warehouse name: " SNOWFLAKE_WAREHOUSE; \
	if [ -z "$$SNOWFLAKE_WAREHOUSE" ]; then echo "Snowflake Warehouse name cannot be empty."; exit 1; fi; \
	read -p "Enter Snowflake Database name: " SNOWFLAKE_DATABASE; \
	if [ -z "$$SNOWFLAKE_DATABASE" ]; then echo "Snowflake Database name cannot be empty."; exit 1; fi; \
	read -p "Enter Snowflake Schema name: " SNOWFLAKE_SCHEMA; \
	if [ -z "$$SNOWFLAKE_SCHEMA" ]; then echo "Snowflake Schema name cannot be empty."; exit 1; fi; \
	echo ""; \
	echo "Deploying SageMaker Lakehouse Snowflake Connection for Producer Project..."; \
	export TF_VAR_AWS_ACCOUNT_ID="$(AWS_ACCOUNT_ID)"; \
	export TF_VAR_SNOWFLAKE_CONNECTION_NAME="$$SNOWFLAKE_CONNECTION_NAME"; \
	export TF_VAR_SNOWFLAKE_USERNAME="$$SNOWFLAKE_USERNAME"; \
	export TF_VAR_SNOWFLAKE_PASSWORD="$$SNOWFLAKE_PASSWORD"; \
	export TF_VAR_SNOWFLAKE_HOST="$$SNOWFLAKE_HOST"; \
	export TF_VAR_SNOWFLAKE_PORT="$$SNOWFLAKE_PORT"; \
	export TF_VAR_SNOWFLAKE_WAREHOUSE="$$SNOWFLAKE_WAREHOUSE"; \
	export TF_VAR_SNOWFLAKE_DATABASE="$$SNOWFLAKE_DATABASE"; \
	export TF_VAR_SNOWFLAKE_SCHEMA="$$SNOWFLAKE_SCHEMA"; \
	(cd iac/roots/sagemaker/snowflake-connection; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished deploying SageMaker Lakehouse Snowflake Connection."

destroy-snowflake-connection:
	@echo "Destroying SageMaker Lakehouse Snowflake Connection for Producer Project"
	(cd iac/roots/sagemaker/snowflake-connection; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished destroying SageMaker Lakehouse Snowflake Connection"

grant-lake-formation-snowflake-catalog:
	@CATALOG_ID_SUFFIX=$$(aws ssm get-parameter --name "/${APP_NAME}/${ENV_NAME}/snowflake/connection-name" --query "Parameter.Value" --output text --region "${AWS_PRIMARY_REGION}"); \
	aws lakeformation grant-permissions \
		--principal DataLakePrincipalIdentifier="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ADMIN_ROLE}" \
		--resource '{"Catalog": {"Id": "${AWS_ACCOUNT_ID}:'$${CATALOG_ID_SUFFIX}'"}}' \
		--permissions ALL SUPER_USER \
		--permissions-with-grant-option ALL \
		--region "${AWS_PRIMARY_REGION}"

# Updates the KMS key policy for the Glue secret key to allow SageMaker Lakehouse Federated Query access.
# This is necessary to enable SageMaker Lakehouse to perform federated queries against encrypted data sources.
# The target adds a policy statement that grants the SageMakerStudioQueryExecutionRole permission to use the KMS key.
# This target should be executed after deploying the Snowflake connection and before using SageMaker Lakehouse federated queries.
update-kms-policy-for-lakehouse:
	@echo "Updating KMS policy for SageMaker Lakehouse Federated Query"
	@if [ -z "$(APP_NAME)" ] || [ -z "$(ENV_NAME)" ] || [ -z "$(AWS_ACCOUNT_ID)" ]; then \
		echo "Error: Required environment variables APP_NAME, ENV_NAME, or AWS_ACCOUNT_ID are not set"; \
		echo "Please ensure these variables are set before running this target"; \
		exit 1; \
	fi; \
	KMS_ALIAS="$(APP_NAME)-$(ENV_NAME)-glue-secret-key"; \
	echo "Looking for KMS key with alias: $$KMS_ALIAS"; \
	KMS_KEY_ID=$$(aws kms describe-key --key-id alias/$$KMS_ALIAS --query 'KeyMetadata.KeyId' --output text 2>/dev/null); \
	if [ -z "$$KMS_KEY_ID" ] || [ "$$KMS_KEY_ID" = "None" ]; then \
		echo "Error: KMS key with alias '$$KMS_ALIAS' not found"; \
		echo "Please ensure the KMS key exists and you have permission to access it"; \
		exit 1; \
	fi; \
	echo "Found KMS key with ID: $$KMS_KEY_ID"; \
	echo "Retrieving current KMS key policy..."; \
	CURRENT_POLICY=$$(aws kms get-key-policy --key-id $$KMS_KEY_ID --policy-name default --query Policy --output text 2>/dev/null); \
	if [ -z "$$CURRENT_POLICY" ]; then \
		echo "Error: Failed to retrieve current policy for KMS key"; \
		echo "Please ensure you have permission to read the key policy"; \
		exit 1; \
	fi; \
	echo "Successfully retrieved current KMS key policy"; \
	echo "Checking if policy already contains SageMaker Lakehouse Federated Query statement..."; \
	if echo "$$CURRENT_POLICY" | jq -e '.Statement[] | select(.Sid == "Allow access for SageMaker Lakehouse Federated Query")' > /dev/null; then \
		echo "Policy already contains the required statement for SageMaker Lakehouse Federated Query"; \
		echo "No changes needed"; \
		exit 0; \
	fi; \
	echo "Adding SageMaker Lakehouse Federated Query statement to policy..."; \
	NEW_STATEMENT='{"Sid": "Allow access for SageMaker Lakehouse Federated Query", "Effect": "Allow", "Principal": {"AWS": "arn:aws:iam::$(AWS_ACCOUNT_ID):role/SageMakerStudioQueryExecutionRole"}, "Action": "kms:*", "Resource": "*"}'; \
	MODIFIED_POLICY=$$(echo "$$CURRENT_POLICY" | jq --arg new_statement "$$NEW_STATEMENT" '.Statement += [$$new_statement | fromjson]'); \
	if [ -z "$$MODIFIED_POLICY" ] || [ "$$MODIFIED_POLICY" = "null" ]; then \
		echo "Error: Failed to modify KMS key policy"; \
		echo "Please check that the current policy is valid JSON"; \
		exit 1; \
	fi; \
	echo "Successfully modified KMS key policy"; \
	echo "Updating KMS key policy..."; \
	TEMP_POLICY_FILE=$$(mktemp); \
	echo "$$MODIFIED_POLICY" > $$TEMP_POLICY_FILE; \
	aws kms put-key-policy --key-id $$KMS_KEY_ID --policy-name default --policy file://$$TEMP_POLICY_FILE 2>/dev/null; \
	UPDATE_RESULT=$$?; \
	rm -f $$TEMP_POLICY_FILE; \
	if [ $$UPDATE_RESULT -ne 0 ]; then \
		echo "Error: Failed to update KMS key policy"; \
		echo "Please ensure you have permission to update the key policy"; \
		exit 1; \
	fi; \
	echo "✅ Successfully updated KMS key policy for SageMaker Lakehouse Federated Query"; \
	echo "The SageMaker Studio Query Execution Role now has access to the KMS key"

#################### Z-ETL Snowflake ####################

deploy-equity-order-sf-zetl-fed:
	@echo "Deploying Z-ETL Snowflake Data"
	(cd iac/roots/z-etl/snowflake/equity-order-sf-zetl-fed; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Z-ETL Snowflake Data"

destroy-equity-order-sf-zetl-fed:
	@echo "Destroying Z-ETL Snowflake Data"
	(cd iac/roots/z-etl/snowflake/equity-order-sf-zetl-fed; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying Z-ETL Snowflake Data"

start-equity-order-sf-zetl-fed-data-generator:
	@echo "Starting Snowflake Data Ingestion Job"
	(aws glue start-job-run --region $(AWS_PRIMARY_REGION) --job-name equity-order-sf-zetl-fed-data-generator)
	@echo "Started Snowflake Data Ingestion Job"

#################### Datazone ####################

deploy-datazone-domain:
	@echo "Deploying Datazone Domain"
	(cd iac/roots/datazone/dz-domain; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Datazone Domain"

destroy-datazone-domain:
	@echo "Destroying Datazone Domain"
	(cd iac/roots/datazone/dz-domain; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying Datazone Domain"

deploy-datazone-project-prereq:
	@echo "Deploying Datazone Project Preqreq"
	(cd iac/roots/datazone/dz-project-prereq; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Datazone Project Preqreq"

destroy-datazone-project-prepreq:
	@echo "Destroying Datazone Project Preqreq"
	(cd iac/roots/datazone/dz-project-prereq; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying Datazone Project Preqreq"

deploy-datazone-producer-project:
	@echo "Deploying Datazone Producer Project"
	(cd iac/roots/datazone/dz-producer-project; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Datazone Producer Project"

destroy-datazone-producer-project:
	@echo "Destroying Datazone Producer Project"
	(cd iac/roots/datazone/dz-producer-project; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying Datazone Producer Project"

deploy-datazone-consumer-project:
	@echo "Deploying Datazone Consumer Project"
	(cd iac/roots/datazone/dz-consumer-project; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Datazone Consumer Project"

destroy-datazone-consumer-project:
	@echo "Destroying Datazone Consumer Project"
	(cd iac/roots/datazone/dz-consumer-project; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying Datazone Consumer Project"

deploy-datazone-custom-project:
	@echo "Deploying Datazone Custom Project"
	(cd iac/roots/datazone/dz-custom-project; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Datazone Custom Project"

destroy-datazone-custom-project:
	@echo "Destroying Datazone Custom Project"
	(cd iac/roots/datazone/dz-custom-project; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying Datazone Custom Project"

#################### Quicksight ####################

deploy-quicksight-subscription:
	@echo "Deploying Quicksight"
	(cd iac/roots/quicksight/subscription; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Quicksight"

deploy-quicksight-dataset:
	@echo "Deploying Quicksight Dataset"
	(cd iac/roots/quicksight/dataset; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying Quicksight Dataset"

############## Spark Code Interpreter #############

##### PREREQUISITES: deploy-kms-keys deploy-vpc #####

deploy-spark-code-interpreter: 
	@echo "Deploying Spark Code Interpreter"
	$(ENV_PATH)utility-functions.sh exec_tf_for_env spark-code-interpreter
	@echo "Finished Deploying Spark Code Interpreter"

destroy-spark-code-interpreter:
	@echo "Destroying Spark Code Interpreter"
	TF_MODE=destroy $(ENV_PATH)utility-functions.sh exec_tf_for_env spark-code-interpreter
	@echo "Destroying Spark Code Interpreter"

#################### AgentCore ####################

##### PREREQUISITES: deploy-price-glue-all deploy-trade-glue-all (the equity price and
##### equity trade data lakes; the backend looks up their Iceberg tables, so plan fails
##### without them), deploy-kms-keys, deploy-buckets and deploy-athena.
##### The deploying principal must also be a Lake Formation data lake admin,
##### because the backend grants LF permissions on the data lake tables.
#####
##### The three roots are ordered and must be applied in sequence. The gateway
##### reads SSM parameters published by the backend, and the demo reads SSM
##### parameters published by the gateway. Teardown runs in reverse.

deploy-agentcore-backend:
	@echo "Deploying AgentCore Backend"
	(cd iac/roots/agentcore/backend; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying AgentCore Backend"

destroy-agentcore-backend:
	@echo "Destroying AgentCore Backend"
	@echo "Note: memory strategies are torn down one at a time, allow 25 to 30 minutes"
	./build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-agentcore-lambda" || true
	(cd iac/roots/agentcore/backend; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying AgentCore Backend"

deploy-agentcore-gateway:
	@echo "Deploying AgentCore Gateway"
	(cd iac/roots/agentcore/gateway; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying AgentCore Gateway"

destroy-agentcore-gateway:
	@echo "Destroying AgentCore Gateway"
	(cd iac/roots/agentcore/gateway; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying AgentCore Gateway"

deploy-agentcore-demo:
	@echo "Deploying AgentCore Demo"
	(cd iac/roots/agentcore/demo; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying AgentCore Demo"

destroy-agentcore-demo:
	@echo "Destroying AgentCore Demo"
	./build-script/empty-s3.sh empty_s3_bucket_by_name "$(AWS_ACCOUNT_ID)-$(APP_NAME)-$(ENV_NAME)-agentcore-demo" || true
	(cd iac/roots/agentcore/demo; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying AgentCore Demo"

get-agentcore-demo-url:
	@aws apigatewayv2 get-apis \
		--region $(AWS_PRIMARY_REGION) \
		--query "Items[?Name=='$(APP_NAME)-$(ENV_NAME)-agentcore-demo'].ApiEndpoint" \
		--output text

get-agentcore-demo-password:
	@aws ssm get-parameter \
		--region $(AWS_PRIMARY_REGION) \
		--name "/$(APP_NAME)/$(ENV_NAME)/agentcore/demo-user-temp-password" \
		--with-decryption \
		--query Parameter.Value \
		--output text

# Short aliases, matching the commands documented in the module READMEs
deploy-agentcore: deploy-agentcore-all
destroy-agentcore: destroy-agentcore-all

#################### Deploy All ####################

deploy-data-pipeline:
	@echo "Deploying data-pipeline module"
	@(\
	  cd iac/roots/data-pipeline; \
	  terraform init; \
	  terraform apply -auto-approve; \
	)
	@echo "Finished deploying data-pipeline module"

destroy-data-pipeline:
	@echo "Destroying data-pipeline module"
	@(\
	  cd iac/roots/data-pipeline; \
	  terraform init; \
	  terraform destroy -auto-approve; \
	)
	@echo "Finished destroying data-pipeline module"


# Deploy all targets in the correct order, one make target at a time
# Deploy all targets in the correct order, one make target at a time
deploy-all: deploy-foundation-all deploy-idc-all deploy-domain-all deploy-projects-all deploy-glue-jars-all deploy-lake-formation-all deploy-athena-all deploy-billing-static-all deploy-billing-dynamic-all deploy-billing-cur-all deploy-inventory-static-all deploy-inventory-dynamic-all deploy-splunk-all deploy-price-glue-all deploy-trade-glue-all deploy-trade-msk-all deploy-trade-flink-all deploy-zetl-ddb-all deploy-project-configuration-all deploy-datazone-all deploy-quicksight-subscription-all deploy-snowflake-connection-all deploy-snowflake-z-etl-all deploy-quicksight-all deploy-spark-code-interpreter-all deploy-agentcore-all
deploy-foundation-all: deploy-kms-keys deploy-iam-roles deploy-buckets deploy-vpc build-msk-data-generator-lambda-layer-zip deploy-msk
deploy-idc-all: deploy-idc-acc disable-mfa
deploy-domain-all: deploy-domain-prereq deploy-domain
deploy-projects-all: deploy-project-prereq deploy-producer-project deploy-consumer-project extract-producer-info extract-consumer-info
deploy-glue-jars-all: deploy-glue-jars
deploy-lake-formation-all: create-glue-s3tables-catalog register-s3table-catalog-with-lake-formation grant-default-database-permissions drop-default-database
deploy-athena-all: deploy-athena
deploy-billing-static-all: deploy-finops-billing-s3-glue-s3 grant-default-database-permissions drop-default-database start-finops-billing-s3-glue-s3-hive-job start-finops-billing-s3-glue-s3-iceberg-static-job start-finops-billing-s3-glue-s3table-job grant-lake-formation-finops-billing-s3-glue-s3table-catalog start-finops-billing-s3-glue-s3-hive-data-quality-ruleset 
deploy-billing-dynamic-all: upload-billing-s3-glue-s3-iceberg-dynamic-report-1 upload-billing-s3-glue-s3-iceberg-dynamic-report-2 grant-lake-formation-billing-s3-glue-s3-iceberg-dynamic
deploy-billing-cur-all: activate-finops-s3-glue-s3-cost-allocation-tags deploy-finops-s3-glue-s3-billing-cur
deploy-inventory-static-all: deploy-finops-inventory-s3-glue-s3 grant-default-database-permissions drop-default-database start-finops-inventory-s3-glue-s3-hive-job start-finops-inventory-s3-glue-s3-iceberg-static-job start-finops-inventory-s3-glue-s3table-job grant-lake-formation-inventory-s3-glue-s3table-catalog start-inventory-s3-glue-s3-hive-data-quality-ruleset 
deploy-inventory-dynamic-all: upload-inventory-s3-glue-s3-iceber-dynamic-report-1 upload-inventory-s3-glue-s3-iceber-dynamic-report-2 grant-lake-formation-inventory-s3-glue-s3-iceberg-dynamic
deploy-splunk-all: deploy-finops-usage-splunk-glue-s3 grant-default-database-permissions drop-default-database start-finops-usage-splunk-glue-s3-iceberg-job start-finops-usage-splunk-glue-s3table-job grant-lake-formation-finops-usage-splunk-glue-s3table-catalog
deploy-price-glue-all: deploy-equity-price-s3-glue-s3 grant-default-database-permissions drop-default-database start-equity-price-s3-glue-s3-hive-job start-equity-price-s3-glue-s3-iceberg-job start-equity-price-s3-glue-s3table-job grant-lake-formation-equity-price-s3-glue-s3table-catalog start-equity-price-s3-glue-s3-hive-data-quality-ruleset
deploy-trade-glue-all: deploy-equity-trade-s3-glue-s3 grant-default-database-permissions drop-default-database start-equity-trade-s3-glue-s3-hive-job start-equity-trade-s3-glue-s3-iceberg-job start-equity-trade-s3-glue-s3table-job grant-lake-formation-equity-trade-s3-glue-s3table-catalog start-equity-trade-s3-glue-s3-hive-data-quality-ruleset
deploy-trade-msk-all: deploy-equity-trade-msk-glue-s3 start-equity-trade-msk-glue-s3-job run-equity-trade-msk-glue-s3-test-harness
deploy-trade-flink-all: build-equity-trade-msk-flink-msk-app deploy-equity-trade-msk-flink-msk run-equity-trade-msk-flink-msk-test-harness
deploy-zetl-ddb-all: deploy-equity-order-dd-zetl-s3-prereq deploy-equity-order-dd-zetl-s3
deploy-project-configuration-all: deploy-project-config finops-billing-s3-glue-s3-grant-producer-s3tables-catalog-permissions finops-inventory-s3-glue-s3-grant-producer-s3tables-catalog-permissions finops-usage-splunk-glue-s3-grant-producer-s3tables-catalog-permissions equity-price-s3-glue-s3-grant-producer-s3tables-catalog-permissions equity-trade-s3-glue-s3-grant-producer-s3tables-catalog-permissions
deploy-datazone-all: deploy-datazone-domain deploy-datazone-project-prereq deploy-datazone-producer-project deploy-datazone-consumer-project deploy-datazone-custom-project
deploy-snowflake-connection-all: deploy-snowflake-connection 
deploy-snowflake-z-etl-all: deploy-equity-order-sf-zetl-fed start-equity-order-sf-zetl-fed-data-generator grant-lake-formation-snowflake-catalog update-kms-policy-for-snowflake-lakehouse
deploy-quicksight-subscription-all: deploy-quicksight-subscription
deploy-quicksight-all: deploy-quicksight-dataset
deploy-spark-code-interpreter-all: deploy-spark-code-interpreter
deploy-agentcore-all: deploy-agentcore-backend deploy-agentcore-gateway deploy-agentcore-demo

#################### Destroy All ####################

# Destroy all targets in the correct order, one make target at a time
destroy-all: destroy-agentcore-all destroy-spark-code-interpreter-all destroy-snowflake-z-etl-all destroy-snowflake-connection-all destroy-datazone-all destroy-project-configuration-all destroy-zetl-ddb-all destroy-trade-flink-all destroy-trade-msk-all destroy-trade-glue-all destroy-price-glue-all destroy-splunk-all destroy-inventory-all destroy-billing-cur-all destroy-billing-all destroy-athena-all destroy-projects-all destroy-domain-all destroy-idc-all destroy-foundation-all
destroy-foundation-all: destroy-msk destroy-vpc destroy-buckets destroy-iam-roles destroy-kms-keys
destroy-idc-all: destroy-idc-acc
destroy-domain-all: destroy-domain destroy-domain-prereq
destroy-projects-all: destroy-consumer-project destroy-producer-project destroy-project-prereq
destroy-athena-all: destroy-athena
destroy-billing-all: destroy-finops-billing-s3-glue-s3
destroy-billing-cur-all: destroy-finops-s3-glue-s3-billing-cur
destroy-inventory-all: destroy-finops-inventory-s3-glue-s3
destroy-splunk-all: destroy-finops-usage-splunk-glue-s3
destroy-price-glue-all: destroy-equity-price-s3-glue-s3
destroy-trade-glue-all: destroy-equity-trade-s3-glue-s3
destroy-trade-msk-all: destroy-equity-trade-msk-glue-s3
destroy-trade-flink-all: destroy-equity-trade-msk-flink-msk
destroy-zetl-ddb-all: destroy-equity-order-dd-zetl-s3 destroy-equity-order-dd-zetl-s3-prereq 
destroy-project-configuration-all: destroy-project-config
destroy-datazone-all: destroy-datazone-custom-project destroy-datazone-consumer-project destroy-datazone-producer-project destroy-datazone-project-prereq destroy-datazone-domain
destroy-snowflake-connection-all: destroy-snowflake-connection
destroy-snowflake-z-etl-all: destroy-equity-order-sf-zetl-fed
destroy-spark-code-interpreter-all: destroy-spark-code-interpreter
destroy-agentcore-all: destroy-agentcore-demo destroy-agentcore-gateway destroy-agentcore-backend
