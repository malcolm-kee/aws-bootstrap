#!/bin/bash -e

GH_ACCESS_TOKEN=$(cat ~/.github/aws-bootstrap-access-token)
GH_OWNER=$(cat ~/.github/aws-bootstrap-owner)
GH_REPO=$(cat ~/.github/aws-bootstrap-repo)
GH_BRANCH=master

STACK_NAME=awsbootstrap
REGION=ap-southeast-1
CLI_PROFILE=awsbootstrap
EC2_INSTANCE_TYPE=t2.micro

AWS_ACCOUNT_ID=`aws sts get-caller-identity --profile awsbootstrap --query Account --output text`
CODEPIPELINE_BUCKET="$STACK_NAME-$REGION-codepipeline-$AWS_ACCOUNT_ID"
TEXTRACT_BUCKET="$STACK_NAME-$REGION-textract-$AWS_ACCOUNT_ID"
LAMBDA_CODE_BUCKET="$STACK_NAME-lambda-code-bucket"
LAMBDA_CODE_KEY="$STACK_NAME-lambda-code"

echo -e "\n\n=============Building and Deploying Lambda Code============="
rm -f dist.zip;
rm -rf dist;
npm run build:lambda;
7z a dist.zip ./dist/*;
aws s3api put-object \
    --region $REGION \
    --profile $CLI_PROFILE \
    --bucket $LAMBDA_CODE_BUCKET \
    --key $LAMBDA_CODE_KEY \
    --body ./dist.zip

echo -e "\n\n=====================Deploying setup.yml===================="
aws cloudformation deploy \
    --region $REGION \
    --profile $CLI_PROFILE \
    --stack-name $STACK_NAME-setup \
    --template-file setup.yml \
    --no-fail-on-empty-changeset \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        CodePipelineBucket=$CODEPIPELINE_BUCKET \
        TextractBucket=$TEXTRACT_BUCKET


echo -e "\n\n=====================Deploying main.yml ====================="
aws cloudformation deploy \
    --region $REGION \
    --profile $CLI_PROFILE \
    --stack-name $STACK_NAME \
    --template-file main.yml \
    --no-fail-on-empty-changeset \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        EC2InstanceType=$EC2_INSTANCE_TYPE \
        GitHubOwner=$GH_OWNER \
        GitHubRepo=$GH_REPO \
        GitHubBranch=$GH_BRANCH \
        GitHubPersonalAccessToken=$GH_ACCESS_TOKEN \
        CodePipelineBucket=$CODEPIPELINE_BUCKET \
        TextractBucket=$TEXTRACT_BUCKET \
        LambdaCodeBucket=$LAMBDA_CODE_BUCKET \
        LambdaCodeKey=$LAMBDA_CODE_KEY

if [ $? -eq 0 ]; then
    aws cloudformation list-exports \
        --profile awsbootstrap \
        --query "Exports[?ends_with(Name, 'LBEndpoint')].Value"
fi