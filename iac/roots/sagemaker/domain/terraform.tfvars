// Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

APP                     = "###APP_NAME###"
ENV                     = "###ENV_NAME###"
AWS_PRIMARY_REGION      = "###AWS_PRIMARY_REGION###"
AWS_SECONDARY_REGION    = "###AWS_SECONDARY_REGION###"
SSM_KMS_KEY_ALIAS       = "###APP_NAME###-###ENV_NAME###-systems-manager-secret-key"
DOMAIN_KMS_KEY_ALIAS    = "###APP_NAME###-###ENV_NAME###-glue-secret-key"

//add your own vpc information, or null if you created vpc in this workshop
SMUS_DOMAIN_VPC_ID                  = null
SMUS_DOMAIN_PRIVATE_SUBNET_IDS      = null
SMUS_DOMAIN_AVAILABILITY_ZONE_NAMES = null

blueprint_ids = [
    "5rd9qqcc5hdujr",
    "anmndpxu191nqf",
    "cjegf7f6kky6w7",
    "dbtz60hvrb2s13",
    "43h4jsps0h7baf",
    "d533nz65rc9duv",
    "6duduhcid2c7af",
    "bly43tfzfsqq93",
    "4y8ipsp95vr0mf",
    "b5u742v3kgqup3",
    "ddjlv3h7kei31j",
    "3hmvwtz507a6zr",
    "d6y5smpdi8x9lz",
    "bcbhfiwy67wrqf",
    "3tysjf9i90fa7b",
    "bigfid01brmulj"
]

domain_user_ids     = ["6448e4f8-30c1-70b0-0dd0-c5f8e4b3289e"]

domain_admin_ids    = ["6448e4f8-30c1-70b0-0dd0-c5f8e4b3289e"]

project_profiles = [
{
    "description": "Build generative AI applications powered by Amazon Bedrock",
    "environmentConfigurations": [
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": false,
                        "name": "enableSpaces",
                        "value": "false"
                    },
                    {
                        "isEditable": false,
                        "name": "maxEbsVolumeSize"
                    },
                    {
                        "isEditable": false,
                        "name": "idleTimeoutInMinutes"
                    },
                    {
                        "isEditable": false,
                        "name": "lifecycleManagement"
                    },
                    {
                        "isEditable": false,
                        "name": "enableNetworkIsolation"
                    },                
                ],
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "gitFullRepositoryId",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "enableSageMakerMLWorkloadsPermissions",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "minIdleTimeoutInMinutes",
                        "value": "60"
                    },
                    {
                        "isEditable": false,
                        "name": "enableGlueWorkloadsPermissions",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "maxEbsVolumeSize",
                        "value": "100"
                    },
                    {
                        "isEditable": false,
                        "name": "idleTimeoutInMinutes",
                        "value": "60"
                    },
                    {
                        "isEditable": true,
                        "name": "workgroupName",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "enableAmazonBedrockIDEPermissions",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "enableNetworkIsolation",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "lifecycleManagement",
                        "value": "ENABLED"
                    },
                    {
                        "isEditable": true,
                        "name": "logGroupRetention",
                        "value": "731"
                    },
                    {
                        "isEditable": false,
                        "name": "sagemakerDomainNetworkType",
                        "value": "VpcOnly"
                    },
                    {
                        "isEditable": true,
                        "name": "enableAthena",
                        "value": "true"
                    },
                    {
                        "isEditable": true,
                        "name": "gitBranchName",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "maxIdleTimeoutInMinutes",
                        "value": "525600"
                    },
                    {
                        "isEditable": false,
                        "name": "gitConnectionArn",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "allowConnectionToUserGovernedEmrClusters",
                        "value": "false"
                    },
                    {
                        "isEditable": false,
                        "name": "enableSpaces",
                        "value": "false"
                    }
                ]
            },
            "deploymentMode": "ON_CREATE",
            "deploymentOrder": 0,
            "description": "Configuration for the Tooling",
            "environmentBlueprintId": "cjegf7f6kky6w7",
            "name": "Tooling"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "knowledgeBaseDescriptions"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceTopP"
                    },
                    {
                        "isEditable": true,
                        "name": "stopSequences"
                    },
                    {
                        "isEditable": true,
                        "name": "description"
                    },
                    {
                        "isEditable": true,
                        "name": "grVersion"
                    },
                    {
                        "isEditable": true,
                        "name": "grId"
                    },
                    {
                        "isEditable": true,
                        "name": "appDefinitionS3Path"
                    },
                    {
                        "isEditable": true,
                        "name": "lastUpdatedTime"
                    },
                    {
                        "isEditable": true,
                        "name": "model"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceTopK"
                    },
                    {
                        "isEditable": true,
                        "name": "openAPISchemaS3Files"
                    },
                    {
                        "isEditable": true,
                        "name": "agentInstructionContinued"
                    },
                    {
                        "isEditable": true,
                        "name": "actionGroupDescriptions"
                    },
                    {
                        "isEditable": true,
                        "name": "actionGroupNames"
                    },
                    {
                        "isEditable": true,
                        "name": "version"
                    },
                    {
                        "isEditable": true,
                        "name": "agentInstruction"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceProfileArn"
                    },
                    {
                        "isEditable": true,
                        "name": "maximumLengthInferenceParam"
                    },
                    {
                        "isEditable": true,
                        "name": "knowledgeBaseIds"
                    },
                    {
                        "isEditable": true,
                        "name": "publishApp"
                    },
                    {
                        "isEditable": true,
                        "name": "documentDataSourceS3Path"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceTemperature"
                    },
                    {
                        "isEditable": true,
                        "name": "featuresEnabled"
                    },
                    {
                        "isEditable": true,
                        "name": "promptTemplate"
                    },
                    {
                        "isEditable": true,
                        "name": "actionExecutorIds"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "A configurable generative AI app with a conversational interface",
            "environmentBlueprintId": "bly43tfzfsqq93",
            "name": "Amazon Bedrock Chat Agent"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "kbDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "parsingPromptText",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "resourceId"
                    },
                    {
                        "isEditable": true,
                        "name": "chunkingOverlapPercentage"
                    },
                    {
                        "isEditable": true,
                        "name": "embeddingModelId"
                    },
                    {
                        "isEditable": true,
                        "name": "metadataField"
                    },
                    {
                        "isEditable": true,
                        "name": "parsingInferenceProfileArn"
                    },
                    {
                        "isEditable": true,
                        "name": "collectionName"
                    },
                    {
                        "isEditable": true,
                        "name": "textField"
                    },
                    {
                        "isEditable": true,
                        "name": "vectorSearchMethodConfiguration"
                    },
                    {
                        "isEditable": true,
                        "name": "parsingModelId",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "webCrawlerInclusionFilters",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "lastUploadTime"
                    },
                    {
                        "isEditable": true,
                        "name": "embeddingModelArn"
                    },
                    {
                        "isEditable": true,
                        "name": "kbName"
                    },
                    {
                        "isEditable": true,
                        "name": "webCrawlerSeedUrls",
                        "value": ",,,,,,,,"
                    },
                    {
                        "isEditable": true,
                        "name": "webCrawlerScope",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "chunkingStrategy"
                    },
                    {
                        "isEditable": true,
                        "name": "s3Prefixes"
                    },
                    {
                        "isEditable": true,
                        "name": "version"
                    },
                    {
                        "isEditable": true,
                        "name": "dataSourceName",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "chunkingNumberOfTokens"
                    },
                    {
                        "isEditable": true,
                        "name": "dataSourceIds"
                    },
                    {
                        "isEditable": true,
                        "name": "vectorField"
                    },
                    {
                        "isEditable": true,
                        "name": "webCrawlerRateLimit",
                        "value": "300"
                    },
                    {
                        "isEditable": true,
                        "name": "webCrawlerExclusionFilters",
                        "value": ""
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "A reusable component for providing your own data to apps",
            "environmentBlueprintId": "3tysjf9i90fa7b",
            "name": " Amazon Bedrock Knowledge Base"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "grPlaceholderTwo"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicSixName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicThreeExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grPromptAttackFilters"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicFiveExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicSevenName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicTwoExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grPlaceholderOne"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexPatternFive"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicSixDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grPIIList"
                    },
                    {
                        "isEditable": true,
                        "name": "grWordlistOne"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicFiveDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicSevenExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grMisconductFilters"
                    },
                    {
                        "isEditable": true,
                        "name": "grHateFilters"
                    },
                    {
                        "isEditable": true,
                        "name": "grSexualFilters"
                    },
                    {
                        "isEditable": true,
                        "name": "grWordlistThree"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicSixExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicOneName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicNineName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicEightExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicTwoDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexNameFive"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexPatternFour"
                    },
                    {
                        "isEditable": true,
                        "name": "version"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexNameTwo"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexPatternThree"
                    },
                    {
                        "isEditable": true,
                        "name": "grWordlistTwo"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexNameOne"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexNameThree"
                    },
                    {
                        "isEditable": true,
                        "name": "grName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicThreeDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexNameFour"
                    },
                    {
                        "isEditable": true,
                        "name": "grWordlistFive"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicEightName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicEightDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicFiveName"
                    },
                    {
                        "isEditable": true,
                        "name": "grWordlistFour"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicFourDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grBlockedInputMessaging"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexBehaviorList"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicNineExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicTenName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicThreeName"
                    },
                    {
                        "isEditable": true,
                        "name": "grInsultsFilters"
                    },
                    {
                        "isEditable": true,
                        "name": "grBlockedOutputsMessaging"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexPatternOne"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicFourName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicOneDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicOneExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicNineDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grPlaceholderFive"
                    },
                    {
                        "isEditable": true,
                        "name": "grProfanityEnabled"
                    },
                    {
                        "isEditable": true,
                        "name": "grViolenceFilters"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicTenExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicFourExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicTenDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grPlaceholderFour"
                    },
                    {
                        "isEditable": true,
                        "name": "grPlaceholderThree"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicTwoName"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexPatternTwo"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicSevenDescription"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "A reusable component for implementing safeguards on model outputs",
            "environmentBlueprintId": "bigfid01brmulj",
            "name": "Amazon Bedrock Guardrail"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "authKeyOneName"
                    },
                    {
                        "isEditable": true,
                        "name": "secretsAssociated"
                    },
                    {
                        "isEditable": true,
                        "name": "functionUpdatedTime"
                    },
                    {
                        "isEditable": true,
                        "name": "authKeyTwoName"
                    },
                    {
                        "isEditable": true,
                        "name": "resourceId"
                    },
                    {
                        "isEditable": true,
                        "name": "functionName"
                    },
                    {
                        "isEditable": true,
                        "name": "endpointUrl"
                    },
                    {
                        "isEditable": true,
                        "name": "authKeyTwoPassIn"
                    },
                    {
                        "isEditable": true,
                        "name": "authKeyOnePassIn"
                    },
                    {
                        "isEditable": true,
                        "name": "version"
                    },
                    {
                        "isEditable": true,
                        "name": "apiSchemaFile"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "A reusable component for including dynamic information in model outputs",
            "environmentBlueprintId": "6duduhcid2c7af",
            "name": "Amazon Bedrock Function"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "flowDefinitionS3BucketName"
                    },
                    {
                        "isEditable": true,
                        "name": "flowGuardrailArnList"
                    },
                    {
                        "isEditable": true,
                        "name": "flowLambdaArnList"
                    },
                    {
                        "isEditable": true,
                        "name": "flowAppDefinitionVersion"
                    },
                    {
                        "isEditable": true,
                        "name": "flowDefinitionS3Version"
                    },
                    {
                        "isEditable": true,
                        "name": "flowDefinitionS3KeyName"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "A configurable generative AI workflow",
            "environmentBlueprintId": "d533nz65rc9duv",
            "name": "Amazon Bedrock Flow"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "variant3BucketString"
                    },
                    {
                        "isEditable": true,
                        "name": "textPrompts"
                    },
                    {
                        "isEditable": true,
                        "name": "variantsName"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceTopP"
                    },
                    {
                        "isEditable": true,
                        "name": "variant1BucketString"
                    },
                    {
                        "isEditable": true,
                        "name": "variant2InputVariables"
                    },
                    {
                        "isEditable": true,
                        "name": "description"
                    },
                    {
                        "isEditable": true,
                        "name": "variant3InputVariables"
                    },
                    {
                        "isEditable": true,
                        "name": "variant2BucketString"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceProfileArns"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceMaxTokens"
                    },
                    {
                        "isEditable": true,
                        "name": "modelIds"
                    },
                    {
                        "isEditable": true,
                        "name": "sharedPromptVersion"
                    },
                    {
                        "isEditable": true,
                        "name": "variant1InputVariables"
                    },
                    {
                        "isEditable": true,
                        "name": "sharedPromptS3DefinitionPath"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceTemperature"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceTopK"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "A reusable set of inputs that guide model outputs",
            "environmentBlueprintId": "ddjlv3h7kei31j",
            "name": "Amazon Bedrock Prompt"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "inputS3PathCount"
                    },
                    {
                        "isEditable": true,
                        "name": "jobName"
                    },
                    {
                        "isEditable": true,
                        "name": "outputS3Path"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceConfig"
                    },
                    {
                        "isEditable": true,
                        "name": "inputS3PathList"
                    },
                    {
                        "isEditable": true,
                        "name": "jobDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "evaluationConfig"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceProfileArnList"
                    },
                    {
                        "isEditable": true,
                        "name": "jobTags"
                    },
                    {
                        "isEditable": true,
                        "name": "outputDataConfig"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "Enables evaluation features to compare Bedrock models",
            "environmentBlueprintId": "dbtz60hvrb2s13",
            "name": "Amazon Bedrock Evaluation"
        }
    ],
    "name": "Generative AI application development",
    "status": "ENABLED"
},
{
    "description": "Govern generative AI models powered by Amazon Bedrock",
    "environmentConfigurations": [],
    "name": "Generative AI model governance",
    "status": "ENABLED"    
},
{
    "description": "Analyze your data in SageMaker Lakehouse using SQL",
    "environmentConfigurations": [
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": false,
                        "name": "enableSpaces",
                        "value": "false"
                    },
                    {
                        "isEditable": false,
                        "name": "maxEbsVolumeSize",
                        "value": 100
                    },
                    {
                        "isEditable": false,
                        "name": "idleTimeoutInMinutes",
                        "value": 60
                    },
                    {
                        "isEditable": false,
                        "name": "lifecycleManagement",
                        "value": "ENABLED"
                    },
                    {
                        "isEditable": false,
                        "name": "enableNetworkIsolation",
                        "value": "true"
                    }
                ],
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "gitFullRepositoryId",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "enableSageMakerMLWorkloadsPermissions",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "minIdleTimeoutInMinutes",
                        "value": "60"
                    },
                    {
                        "isEditable": false,
                        "name": "enableGlueWorkloadsPermissions",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "maxEbsVolumeSize",
                        "value": "100"
                    },
                    {
                        "isEditable": false,
                        "name": "idleTimeoutInMinutes",
                        "value": "60"
                    },
                    {
                        "isEditable": true,
                        "name": "workgroupName",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "enableAmazonBedrockIDEPermissions",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "enableNetworkIsolation",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "lifecycleManagement",
                        "value": "ENABLED"
                    },
                    {
                        "isEditable": true,
                        "name": "logGroupRetention",
                        "value": "731"
                    },
                    {
                        "isEditable": false,
                        "name": "sagemakerDomainNetworkType",
                        "value": "VpcOnly"
                    },
                    {
                        "isEditable": true,
                        "name": "enableAthena",
                        "value": "true"
                    },
                    {
                        "isEditable": true,
                        "name": "gitBranchName",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "maxIdleTimeoutInMinutes",
                        "value": "525600"
                    },
                    {
                        "isEditable": false,
                        "name": "gitConnectionArn",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "allowConnectionToUserGovernedEmrClusters",
                        "value": "false"
                    },
                    {
                        "isEditable": false,
                        "name": "enableSpaces",
                        "value": "false"
                    }
                ]
            },
            "deploymentMode": "ON_CREATE",
            "deploymentOrder": 0,
            "description": "Configuration for the Tooling",
            "environmentBlueprintId": "cjegf7f6kky6w7",
            "name": "Tooling"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": true,
                        "name": "glueDbName",
                        "value": "glue_db"
                    }
                ],
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "glueDbName",
                        "value": "glue_db"
                    },
                    {
                        "isEditable": true,
                        "name": "workgroupName",
                        "value": "workgroup"
                    }
                ]
            },
            "deploymentMode": "ON_CREATE",
            "deploymentOrder": "1",
            "description": "Creates databases in Amazon SageMaker Lakehouse for storing tables in S3 and Amazon Athena resources for your SQL workloads",
            "environmentBlueprintId": "d6y5smpdi8x9lz",
            "name": "Lakehouse Database"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": true,
                        "name": "redshiftDbName",
                        "value": "dev"
                    },
                    {
                        "isEditable": false,
                        "name": "connectToRMSCatalog",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftMaxCapacity",
                        "value": "512"
                    }
                ],
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "redshiftDbName",
                        "value": "dev"
                    },
                    {
                        "isEditable": false,
                        "name": "connectionDescription",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftMaxCapacity",
                        "value": "512"
                    },
                    {
                        "isEditable": false,
                        "name": "provisionManagedSecret",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftWorkgroupName",
                        "value": "redshift-serverless-workgroup"
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftBaseCapacity",
                        "value": "128"
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftProjectSchemaName",
                        "value": "project"
                    },
                    {
                        "isEditable": false,
                        "name": "connectToRMSCatalog",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "connectionName",
                        "value": "project.redshift"
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftWorkgroupNamespaceName",
                        "value": "redshift-serverless-namespace"
                    }
                ]
            },
            "deploymentMode": "ON_CREATE",
            "deploymentOrder": "1",
            "description": "Creates an Amazon Redshift Serverless workgroup for your SQL workloads",
            "environmentBlueprintId": "43h4jsps0h7baf",
            "name": "Redshift Serverless"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": true,
                        "name": "redshiftDbName",
                        "value": "dev"
                    },
                    {
                        "isEditable": true,
                        "name": "redshiftMaxCapacity",
                        "value": "512"
                    },
                    {
                        "isEditable": true,
                        "name": "redshiftWorkgroupName",
                        "value": "redshift-serverless-workgroup"
                    },
                    {
                        "isEditable": true,
                        "name": "redshiftBaseCapacity",
                        "value": "128"
                    },
                    {
                        "isEditable": true,
                        "name": "connectionName",
                        "value": "redshift.serverless"
                    },
                    {
                        "isEditable": false,
                        "name": "connectToRMSCatalog",
                        "value": "false"
                    }
                ],
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "redshiftDbName",
                        "value": "dev"
                    },
                    {
                        "isEditable": false,
                        "name": "connectionDescription",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "redshiftMaxCapacity",
                        "value": "512"
                    },
                    {
                        "isEditable": false,
                        "name": "provisionManagedSecret",
                        "value": "true"
                    },
                    {
                        "isEditable": true,
                        "name": "redshiftWorkgroupName",
                        "value": "redshift-serverless-workgroup"
                    },
                    {
                        "isEditable": true,
                        "name": "redshiftBaseCapacity",
                        "value": "128"
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftProjectSchemaName",
                        "value": "project"
                    },
                    {
                        "isEditable": false,
                        "name": "connectToRMSCatalog",
                        "value": "false"
                    },
                    {
                        "isEditable": true,
                        "name": "connectionName",
                        "value": "redshift.serverless"
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftWorkgroupNamespaceName",
                        "value": "redshift-serverless-namespace"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "Enables you to create an additional Amazon Redshift Serverless workgroup for your SQL workloads",
            "environmentBlueprintId": "43h4jsps0h7baf",
            "name": "OnDemand RedshiftServerless"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": true,
                        "name": "catalogName"
                    },
                    {
                        "isEditable": true,
                        "name": "catalogDescription",
                        "value": "RMS catalog"
                    }
                ],
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "catalogName",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "catalogDescription",
                        "value": "RMS catalog"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "Enables you to create additional catalogs in Amazon SageMaker Lakehouse for storing data in Redshift Managed Storage",
            "environmentBlueprintId": "3hmvwtz507a6zr",
            "name": "OnDemand Catalog for Redshift Managed Storage"
        }
    ],
    "name": "SQL analytics",
    "status": "ENABLED"
},
{
    "description": "Analyze data and build machine learning and generative AI models and applications powered by Amazon Bedrock, Amazon EMR, AWS Glue, Amazon Athena, Amazon SageMaker AI and Amazon SageMaker Lakehouse",
    "environmentConfigurations": [
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": false,
                        "name": "enableSpaces",
                        "value": "true"
                    },
                    # {
                    #     "isEditable": false,
                    #     "name": "maxEbsVolumeSize"
                    # },
                    # {
                    #     "isEditable": false,
                    #     "name": "idleTimeoutInMinutes"
                    # },
                    # {
                    #     "isEditable": false,
                    #     "name": "lifecycleManagement"
                    # },
                    # {
                    #     "isEditable": false,
                    #     "name": "enableNetworkIsolation"
                    # },
                    # {
                    #     "isEditable": false,
                    #     "name": "enableAmazonBedrockPermissions",
                    #     "value": "true"
                    # }                    
                ],
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "gitFullRepositoryId",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "enableSageMakerMLWorkloadsPermissions",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "minIdleTimeoutInMinutes",
                        "value": "60"
                    },
                    {
                        "isEditable": false,
                        "name": "enableGlueWorkloadsPermissions",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "maxEbsVolumeSize",
                        "value": "100"
                    },
                    {
                        "isEditable": false,
                        "name": "idleTimeoutInMinutes",
                        "value": "60"
                    },
                    {
                        "isEditable": true,
                        "name": "workgroupName",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "enableAmazonBedrockIDEPermissions",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "enableNetworkIsolation",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "lifecycleManagement",
                        "value": "ENABLED"
                    },
                    {
                        "isEditable": true,
                        "name": "logGroupRetention",
                        "value": "731"
                    },
                    {
                        "isEditable": false,
                        "name": "sagemakerDomainNetworkType",
                        "value": "VpcOnly"
                    },
                    {
                        "isEditable": true,
                        "name": "enableAthena",
                        "value": "true"
                    },
                    {
                        "isEditable": true,
                        "name": "gitBranchName",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "maxIdleTimeoutInMinutes",
                        "value": "525600"
                    },
                    {
                        "isEditable": false,
                        "name": "gitConnectionArn",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "allowConnectionToUserGovernedEmrClusters",
                        "value": "false"
                    },
                    {
                        "isEditable": false,
                        "name": "enableSpaces",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "enableAmazonBedrockPermissions",
                        "value": "true"
                    }                       
                ]
            },
            "deploymentMode": "ON_CREATE",
            "deploymentOrder": 0,
            "description": "Configuration for the Tooling",
            "environmentBlueprintId": "cjegf7f6kky6w7",
            "name": "Tooling"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": true,
                        "name": "glueDbName",
                        "value": "glue_db"
                    }
                ],
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "glueDbName",
                        "value": "glue_db"
                    },
                    {
                        "isEditable": true,
                        "name": "workgroupName",
                        "value": "workgroup"
                    }
                ]
            },
            "deploymentMode": "ON_CREATE",
            "deploymentOrder": 1,
            "description": "Creates databases in Amazon SageMaker Lakehouse for storing tables in S3 and Amazon Athena resources for your SQL workloads",
            "environmentBlueprintId": "d6y5smpdi8x9lz",
            "name": "Lakehouse Database"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": true,
                        "name": "redshiftDbName",
                        "value": "dev"
                    },
                    {
                        "isEditable": false,
                        "name": "connectToRMSCatalog",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftMaxCapacity",
                        "value": "512"
                    }
                ],
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "redshiftDbName",
                        "value": "dev"
                    },
                    {
                        "isEditable": false,
                        "name": "connectionDescription",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftMaxCapacity",
                        "value": "512"
                    },
                    {
                        "isEditable": false,
                        "name": "provisionManagedSecret",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftWorkgroupName",
                        "value": "redshift-serverless-workgroup"
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftBaseCapacity",
                        "value": "128"
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftProjectSchemaName",
                        "value": "project"
                    },
                    {
                        "isEditable": false,
                        "name": "connectToRMSCatalog",
                        "value": "true"
                    },
                    {
                        "isEditable": false,
                        "name": "connectionName",
                        "value": "project.redshift"
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftWorkgroupNamespaceName",
                        "value": "redshift-serverless-namespace"
                    }
                ]
            },
            "deploymentMode": "ON_CREATE",
            "deploymentOrder": 1,
            "description": "Creates an Amazon Redshift Serverless workgroup for your SQL workloads",
            "environmentBlueprintId": "43h4jsps0h7baf",
            "name": "RedshiftServerless"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": false,
                        "name": "environmentClass",
                        "value": "mw1.micro"
                    }
                ],
                "resolvedParameters": [
                    {
                        "isEditable": false,
                        "name": "schedulerMinFileProcessInterval",
                        "value": "30"
                    },
                    {
                        "isEditable": false,
                        "name": "smtpPort",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "taskLogLevel",
                        "value": "INFO"
                    },
                    {
                        "isEditable": false,
                        "name": "webserverLogLevel",
                        "value": "ERROR"
                    },
                    {
                        "isEditable": false,
                        "name": "schedulerLogLevel",
                        "value": "ERROR"
                    },
                    {
                        "isEditable": false,
                        "name": "secretsBackendKwargs",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "defaultTimezone",
                        "value": "utc"
                    },
                    {
                        "isEditable": false,
                        "name": "defaultTaskRetries",
                        "value": "0"
                    },
                    {
                        "isEditable": false,
                        "name": "maxWorkers",
                        "value": "1"
                    },
                    {
                        "isEditable": false,
                        "name": "endpointManagement",
                        "value": "SERVICE"
                    },
                    {
                        "isEditable": false,
                        "name": "schedulers",
                        "value": "1"
                    },
                    {
                        "isEditable": false,
                        "name": "smtpSsl",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "secretsBackend",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "catchupByDefault",
                        "value": "false"
                    },
                    {
                        "isEditable": false,
                        "name": "dagFileProcessorTimeout",
                        "value": "50"
                    },
                    {
                        "isEditable": false,
                        "name": "workerLogLevel",
                        "value": "ERROR"
                    },
                    {
                        "isEditable": false,
                        "name": "smtpMailFrom",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "dagProcessingLogLevel",
                        "value": "ERROR"
                    },
                    {
                        "isEditable": false,
                        "name": "dagbagImportTimeout",
                        "value": "30"
                    },
                    {
                        "isEditable": false,
                        "name": "smtpHost",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "smtpStarttls",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "webserverDefaultUiTimezone",
                        "value": "UTC"
                    },
                    {
                        "isEditable": false,
                        "name": "emailBackend",
                        "value": ""
                    },
                    {
                        "isEditable": false,
                        "name": "environmentClass",
                        "value": "mw1.micro"
                    },
                    {
                        "isEditable": false,
                        "name": "maxWebservers",
                        "value": "1"
                    },
                    {
                        "isEditable": false,
                        "name": "minWebservers",
                        "value": "1"
                    },
                    {
                        "isEditable": false,
                        "name": "minWorkers",
                        "value": "1"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "Enables you to create Airflow workflows to be executed on MWAA environments",
            "environmentBlueprintId": "bcbhfiwy67wrqf",
            "name": "OnDemand Workflows"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": true,
                        "name": "mlflowTrackingServerSize",
                        "value": "Small"
                    },
                    {
                        "isEditable": true,
                        "name": "mlflowTrackingServerName",
                        "value": "tracking-server"
                    }
                ],
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "mlflowTrackingServerSize",
                        "value": "Small"
                    },
                    {
                        "isEditable": true,
                        "name": "mlflowTrackingServerName",
                        "value": "tracking-server"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "Enables you to create Amazon Sagemaker mlflow in the project",
            "environmentBlueprintId": "b5u742v3kgqup3",
            "name": "OnDemand MLExperiments"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": true,
                        "name": "emrRelease",
                        "value": "emr-7.5.0"
                    },
                    {
                        "isEditable": true,
                        "name": "connectionDescription",
                        "value": "Spark connection for EMR EC2 cluster"
                    },
                    {
                        "isEditable": true,
                        "name": "clusterName",
                        "value": "emr-ec2-cluster"
                    },
                    {
                        "isEditable": true,
                        "name": "primaryInstanceType",
                        "value": "r6g.xlarge"
                    },
                    {
                        "isEditable": true,
                        "name": "coreInstanceType",
                        "value": "r6g.xlarge"
                    },
                    {
                        "isEditable": true,
                        "name": "taskInstanceType",
                        "value": "r6g.xlarge"
                    }
                ],
                "resolvedParameters": [
                    {
                        "isEditable": false,
                        "name": "maximumClusterSize",
                        "value": "20"
                    },
                    {
                        "isEditable": true,
                        "name": "primaryInstanceType",
                        "value": "r6g.xlarge"
                    },
                    {
                        "isEditable": true,
                        "name": "taskInstanceType",
                        "value": "r6g.xlarge"
                    },
                    {
                        "isEditable": true,
                        "name": "emrRelease",
                        "value": "emr-7.5.0"
                    },
                    {
                        "isEditable": true,
                        "name": "connectionDescription",
                        "value": "Spark connection for EMR EC2 cluster"
                    },
                    {
                        "isEditable": false,
                        "name": "ebsRootVolumeSize",
                        "value": "64"
                    },
                    {
                        "isEditable": true,
                        "name": "clusterName",
                        "value": "emr-ec2-cluster"
                    },
                    {
                        "isEditable": false,
                        "name": "certificateLocation",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "coreInstanceType",
                        "value": "r6g.xlarge"
                    },
                    {
                        "isEditable": false,
                        "name": "minimumClusterSize",
                        "value": "2"
                    },
                    {
                        "isEditable": false,
                        "name": "maximumCoreNodesInCluster",
                        "value": "20"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "Enables you to create an additional memory optimized Amazon EMR on Amazon EC2",
            "environmentBlueprintId": "4y8ipsp95vr0mf",
            "name": "OnDemand EMR on EC2 Memory-Optimized"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": true,
                        "name": "emrRelease",
                        "value": "emr-7.5.0"
                    },
                    {
                        "isEditable": true,
                        "name": "connectionDescription",
                        "value": "Spark connection for EMR EC2 cluster"
                    },
                    {
                        "isEditable": true,
                        "name": "clusterName",
                        "value": "emr-ec2-cluster"
                    },
                    {
                        "isEditable": true,
                        "name": "primaryInstanceType",
                        "value": "m6g.xlarge"
                    },
                    {
                        "isEditable": true,
                        "name": "coreInstanceType",
                        "value": "m6g.xlarge"
                    },
                    {
                        "isEditable": true,
                        "name": "taskInstanceType",
                        "value": "m6g.xlarge"
                    }
                ],
                "resolvedParameters": [
                    {
                        "isEditable": false,
                        "name": "maximumClusterSize",
                        "value": "20"
                    },
                    {
                        "isEditable": true,
                        "name": "primaryInstanceType",
                        "value": "m6g.xlarge"
                    },
                    {
                        "isEditable": true,
                        "name": "taskInstanceType",
                        "value": "m6g.xlarge"
                    },
                    {
                        "isEditable": true,
                        "name": "emrRelease",
                        "value": "emr-7.5.0"
                    },
                    {
                        "isEditable": true,
                        "name": "connectionDescription",
                        "value": "Spark connection for EMR EC2 cluster"
                    },
                    {
                        "isEditable": false,
                        "name": "ebsRootVolumeSize",
                        "value": "64"
                    },
                    {
                        "isEditable": true,
                        "name": "clusterName",
                        "value": "emr-ec2-cluster"
                    },
                    {
                        "isEditable": false,
                        "name": "certificateLocation",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "coreInstanceType",
                        "value": "m6g.xlarge"
                    },
                    {
                        "isEditable": false,
                        "name": "minimumClusterSize",
                        "value": "2"
                    },
                    {
                        "isEditable": false,
                        "name": "maximumCoreNodesInCluster",
                        "value": "20"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "Enables you to create an additional general purpose Amazon EMR on Amazon EC2",
            "environmentBlueprintId": "4y8ipsp95vr0mf",
            "name": "OnDemand EMR on EC2 General-Purpose"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": true,
                        "name": "redshiftDbName",
                        "value": "dev"
                    },
                    {
                        "isEditable": true,
                        "name": "redshiftMaxCapacity",
                        "value": "512"
                    },
                    {
                        "isEditable": true,
                        "name": "redshiftWorkgroupName",
                        "value": "redshift-serverless-workgroup"
                    },
                    {
                        "isEditable": true,
                        "name": "redshiftBaseCapacity",
                        "value": "128"
                    },
                    {
                        "isEditable": true,
                        "name": "connectionName",
                        "value": "redshift.serverless"
                    },
                    {
                        "isEditable": false,
                        "name": "connectToRMSCatalog",
                        "value": "false"
                    }
                ],
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "redshiftDbName",
                        "value": "dev"
                    },
                    {
                        "isEditable": false,
                        "name": "connectionDescription",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "redshiftMaxCapacity",
                        "value": "512"
                    },
                    {
                        "isEditable": false,
                        "name": "provisionManagedSecret",
                        "value": "true"
                    },
                    {
                        "isEditable": true,
                        "name": "redshiftWorkgroupName",
                        "value": "redshift-serverless-workgroup"
                    },
                    {
                        "isEditable": true,
                        "name": "redshiftBaseCapacity",
                        "value": "128"
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftProjectSchemaName",
                        "value": "project"
                    },
                    {
                        "isEditable": false,
                        "name": "connectToRMSCatalog",
                        "value": "false"
                    },
                    {
                        "isEditable": true,
                        "name": "connectionName",
                        "value": "redshift.serverless"
                    },
                    {
                        "isEditable": false,
                        "name": "redshiftWorkgroupNamespaceName",
                        "value": "redshift-serverless-namespace"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "Enables you to create an additional Amazon Redshift Serverless workgroup for your SQL workloads",
            "environmentBlueprintId": "43h4jsps0h7baf",
            "name": "OnDemand RedshiftServerless"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": true,
                        "name": "catalogName"
                    },
                    {
                        "isEditable": true,
                        "name": "catalogDescription",
                        "value": "RMS catalog"
                    }
                ],
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "catalogName",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "catalogDescription",
                        "value": "RMS catalog"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "Enables you to create additional catalogs in Amazon SageMaker Lakehouse for storing data in Redshift Managed Storage",
            "environmentBlueprintId": "3hmvwtz507a6zr",
            "name": "OnDemand Catalog for Redshift Managed Storage"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "parameterOverrides": [
                    {
                        "isEditable": true,
                        "name": "connectionDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "connectionName"
                    },
                    {
                        "isEditable": true,
                        "name": "releaseLabel",
                        "value": "emr-7.5.0"
                    }
                ],
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "driverDisk",
                        "value": "20"
                    },
                    {
                        "isEditable": true,
                        "name": "driverMemory",
                        "value": "16"
                    },
                    {
                        "isEditable": true,
                        "name": "executorCpu",
                        "value": "4"
                    },
                    {
                        "isEditable": true,
                        "name": "executorMemory",
                        "value": "16"
                    },
                    {
                        "isEditable": true,
                        "name": "driverInitialCapacity",
                        "value": "1"
                    },
                    {
                        "isEditable": true,
                        "name": "executorInitialCapacity",
                        "value": "2"
                    },
                    {
                        "isEditable": true,
                        "name": "maximumDiskCapacity",
                        "value": "20000"
                    },
                    {
                        "isEditable": true,
                        "name": "releaseLabel",
                        "value": "emr-7.5.0"
                    },
                    {
                        "isEditable": true,
                        "name": "driverCpu",
                        "value": "4"
                    },
                    {
                        "isEditable": true,
                        "name": "connectionDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "executorDisk",
                        "value": "20"
                    },
                    {
                        "isEditable": true,
                        "name": "connectionName"
                    },
                    {
                        "isEditable": true,
                        "name": "maximumMemoryCapacity",
                        "value": "3000"
                    },
                    {
                        "isEditable": true,
                        "name": "maximumCpuCapacity",
                        "value": "400"
                    },
                    {
                        "isEditable": true,
                        "name": "managedPersistenceMonitoringEnabled",
                        "value": "true"
                    },
                    {
                        "isEditable": true,
                        "name": "architecture",
                        "value": "X86_64"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "Enables you to create an additional Amazon EMR Serverless application for running Spark workloads",
            "environmentBlueprintId": "5rd9qqcc5hdujr",
            "name": "OnDemand EMRServerless"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "reasoningType"
                    },
                    {
                        "isEditable": true,
                        "name": "knowledgeBaseDescriptions"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceTopP"
                    },
                    {
                        "isEditable": true,
                        "name": "stopSequences"
                    },
                    {
                        "isEditable": true,
                        "name": "description"
                    },
                    {
                        "isEditable": true,
                        "name": "grVersion"
                    },
                    {
                        "isEditable": true,
                        "name": "grId"
                    },
                    {
                        "isEditable": true,
                        "name": "reasoningBudget"
                    },
                    {
                        "isEditable": true,
                        "name": "appDefinitionS3Path"
                    },
                    {
                        "isEditable": true,
                        "name": "lastUpdatedTime"
                    },
                    {
                        "isEditable": true,
                        "name": "model"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceTopK"
                    },
                    {
                        "isEditable": true,
                        "name": "openAPISchemaS3Files"
                    },
                    {
                        "isEditable": true,
                        "name": "agentInstructionContinued"
                    },
                    {
                        "isEditable": true,
                        "name": "actionGroupDescriptions"
                    },
                    {
                        "isEditable": true,
                        "name": "actionGroupNames"
                    },
                    {
                        "isEditable": true,
                        "name": "version"
                    },
                    {
                        "isEditable": true,
                        "name": "agentInstruction"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceProfileArn"
                    },
                    {
                        "isEditable": true,
                        "name": "maximumLengthInferenceParam"
                    },
                    {
                        "isEditable": true,
                        "name": "knowledgeBaseIds"
                    },
                    {
                        "isEditable": true,
                        "name": "publishApp"
                    },
                    {
                        "isEditable": true,
                        "name": "documentDataSourceS3Path"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceTemperature"
                    },
                    {
                        "isEditable": true,
                        "name": "featuresEnabled"
                    },
                    {
                        "isEditable": true,
                        "name": "promptTemplate"
                    },
                    {
                        "isEditable": true,
                        "name": "actionExecutorIds"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "A configurable generative AI app with a conversational interface",
            "environmentBlueprintId": "bly43tfzfsqq93",
            "name": "Amazon Bedrock Chat Agent"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "kbDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "parsingPromptText",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "resourceId"
                    },
                    {
                        "isEditable": true,
                        "name": "chunkingOverlapPercentage"
                    },
                    {
                        "isEditable": true,
                        "name": "embeddingModelId"
                    },
                    {
                        "isEditable": true,
                        "name": "metadataField"
                    },
                    {
                        "isEditable": true,
                        "name": "parsingInferenceProfileArn"
                    },
                    {
                        "isEditable": true,
                        "name": "collectionName"
                    },
                    {
                        "isEditable": true,
                        "name": "textField"
                    },
                    {
                        "isEditable": true,
                        "name": "vectorSearchMethodConfiguration"
                    },
                    {
                        "isEditable": true,
                        "name": "parsingModelId",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "webCrawlerInclusionFilters",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "lastUploadTime"
                    },
                    {
                        "isEditable": true,
                        "name": "embeddingModelArn"
                    },
                    {
                        "isEditable": true,
                        "name": "kbName"
                    },
                    {
                        "isEditable": true,
                        "name": "webCrawlerSeedUrls",
                        "value": ",,,,,,,,"
                    },
                    {
                        "isEditable": true,
                        "name": "webCrawlerScope",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "chunkingStrategy"
                    },
                    {
                        "isEditable": true,
                        "name": "s3Prefixes"
                    },
                    {
                        "isEditable": true,
                        "name": "version"
                    },
                    {
                        "isEditable": true,
                        "name": "dataSourceName",
                        "value": ""
                    },
                    {
                        "isEditable": true,
                        "name": "chunkingNumberOfTokens"
                    },
                    {
                        "isEditable": true,
                        "name": "dataSourceIds"
                    },
                    {
                        "isEditable": true,
                        "name": "vectorField"
                    },
                    {
                        "isEditable": true,
                        "name": "webCrawlerRateLimit",
                        "value": "300"
                    },
                    {
                        "isEditable": true,
                        "name": "webCrawlerExclusionFilters",
                        "value": ""
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "A reusable component for providing your own data to apps",
            "environmentBlueprintId": "3tysjf9i90fa7b",
            "name": "Amazon Bedrock Knowledge Base"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "grPlaceholderTwo"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicSixName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicThreeExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grPromptAttackFilters"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicFiveExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicSevenName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicTwoExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grPlaceholderOne"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexPatternFive"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicSixDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grPIIList"
                    },
                    {
                        "isEditable": true,
                        "name": "grWordlistOne"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicFiveDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicSevenExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grMisconductFilters"
                    },
                    {
                        "isEditable": true,
                        "name": "grHateFilters"
                    },
                    {
                        "isEditable": true,
                        "name": "grSexualFilters"
                    },
                    {
                        "isEditable": true,
                        "name": "grWordlistThree"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicSixExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicOneName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicNineName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicEightExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicTwoDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexNameFive"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexPatternFour"
                    },
                    {
                        "isEditable": true,
                        "name": "version"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexNameTwo"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexPatternThree"
                    },
                    {
                        "isEditable": true,
                        "name": "grWordlistTwo"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexNameOne"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexNameThree"
                    },
                    {
                        "isEditable": true,
                        "name": "grName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicThreeDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexNameFour"
                    },
                    {
                        "isEditable": true,
                        "name": "grWordlistFive"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicEightName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicEightDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicFiveName"
                    },
                    {
                        "isEditable": true,
                        "name": "grWordlistFour"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicFourDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grBlockedInputMessaging"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexBehaviorList"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicNineExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicTenName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicThreeName"
                    },
                    {
                        "isEditable": true,
                        "name": "grInsultsFilters"
                    },
                    {
                        "isEditable": true,
                        "name": "grBlockedOutputsMessaging"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexPatternOne"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicFourName"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicOneDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicOneExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicNineDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grPlaceholderFive"
                    },
                    {
                        "isEditable": true,
                        "name": "grProfanityEnabled"
                    },
                    {
                        "isEditable": true,
                        "name": "grViolenceFilters"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicTenExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicFourExamples"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicTenDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "grPlaceholderFour"
                    },
                    {
                        "isEditable": true,
                        "name": "grPlaceholderThree"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicTwoName"
                    },
                    {
                        "isEditable": true,
                        "name": "grRegexPatternTwo"
                    },
                    {
                        "isEditable": true,
                        "name": "grTopicSevenDescription"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "A reusable component for implementing safeguards on model outputs",
            "environmentBlueprintId": "bigfid01brmulj",
            "name": "Amazon Bedrock Guardrail"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "authKeyOneName"
                    },
                    {
                        "isEditable": true,
                        "name": "secretsAssociated"
                    },
                    {
                        "isEditable": true,
                        "name": "functionUpdatedTime"
                    },
                    {
                        "isEditable": true,
                        "name": "authKeyTwoName"
                    },
                    {
                        "isEditable": true,
                        "name": "resourceId"
                    },
                    {
                        "isEditable": true,
                        "name": "functionName"
                    },
                    {
                        "isEditable": true,
                        "name": "endpointUrl"
                    },
                    {
                        "isEditable": true,
                        "name": "authKeyTwoPassIn"
                    },
                    {
                        "isEditable": true,
                        "name": "authKeyOnePassIn"
                    },
                    {
                        "isEditable": true,
                        "name": "version"
                    },
                    {
                        "isEditable": true,
                        "name": "apiSchemaFile"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "A reusable component for including dynamic information in model outputs",
            "environmentBlueprintId": "6duduhcid2c7af",
            "name": "Amazon Bedrock Function"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "flowDefinitionS3BucketName"
                    },
                    {
                        "isEditable": true,
                        "name": "flowGuardrailArnList"
                    },
                    {
                        "isEditable": true,
                        "name": "flowLambdaArnList"
                    },
                    {
                        "isEditable": true,
                        "name": "flowAppDefinitionVersion"
                    },
                    {
                        "isEditable": true,
                        "name": "flowDefinitionS3Version"
                    },
                    {
                        "isEditable": true,
                        "name": "flowDefinitionS3KeyName"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "A configurable generative AI workflow",
            "environmentBlueprintId": "d533nz65rc9duv",
            "name": "Amazon Bedrock Flow"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "reasoningType"
                    },
                    {
                        "isEditable": true,
                        "name": "variant3BucketString"
                    },
                    {
                        "isEditable": true,
                        "name": "textPrompts"
                    },
                    {
                        "isEditable": true,
                        "name": "variantsName"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceTopP"
                    },
                    {
                        "isEditable": true,
                        "name": "variant1BucketString"
                    },
                    {
                        "isEditable": true,
                        "name": "variant2InputVariables"
                    },
                    {
                        "isEditable": true,
                        "name": "description"
                    },
                    {
                        "isEditable": true,
                        "name": "variant3InputVariables"
                    },
                    {
                        "isEditable": true,
                        "name": "variant2BucketString"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceProfileArns"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceMaxTokens"
                    },
                    {
                        "isEditable": true,
                        "name": "modelIds"
                    },
                    {
                        "isEditable": true,
                        "name": "reasoningBudget"
                    },
                    {
                        "isEditable": true,
                        "name": "sharedPromptVersion"
                    },
                    {
                        "isEditable": true,
                        "name": "variant1InputVariables"
                    },
                    {
                        "isEditable": true,
                        "name": "sharedPromptS3DefinitionPath"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceTemperature"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceTopK"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "A reusable set of inputs that guide model outputs",
            "environmentBlueprintId": "ddjlv3h7kei31j",
            "name": "Amazon Bedrock Prompt"
        },
        {
            "awsAccount": {
                "awsAccountId": ""
            },
            "awsRegion": {
                "regionName": ""
            },
            "configurationParameters": {
                "resolvedParameters": [
                    {
                        "isEditable": true,
                        "name": "inputS3PathCount"
                    },
                    {
                        "isEditable": true,
                        "name": "jobName"
                    },
                    {
                        "isEditable": true,
                        "name": "outputS3Path"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceConfig"
                    },
                    {
                        "isEditable": true,
                        "name": "inputS3PathList"
                    },
                    {
                        "isEditable": true,
                        "name": "jobDescription"
                    },
                    {
                        "isEditable": true,
                        "name": "evaluationConfig"
                    },
                    {
                        "isEditable": true,
                        "name": "inferenceProfileArnList"
                    },
                    {
                        "isEditable": true,
                        "name": "jobTags"
                    },
                    {
                        "isEditable": true,
                        "name": "outputDataConfig"
                    }
                ]
            },
            "deploymentMode": "ON_DEMAND",
            "description": "Enables evaluation features to compare Bedrock models",
            "environmentBlueprintId": "dbtz60hvrb2s13",
            "name": "Amazon Bedrock Evaluation"
        }              
    ],
    "name": "All capabilities",
    "status": "ENABLED"
}

]
