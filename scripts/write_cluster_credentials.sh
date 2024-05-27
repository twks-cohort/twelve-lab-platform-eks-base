#!/usr/bin/env bash
export CLUSTER=$1
export AWS_DEFAULT_REGION=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_region)
export AWS_ASSUME_ROLE=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_assume_role)
export AWS_ACCOUNT_ID=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_account_id)

aws sts assume-role --output json --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/$AWS_ASSUME_ROLE --role-session-name twelve-lab-platform-eks-base >credentials

export AWS_ACCESS_KEY_ID=$(cat credentials | jq -r ".Credentials.AccessKeyId")
export AWS_SECRET_ACCESS_KEY=$(cat credentials | jq -r ".Credentials.SecretAccessKey")
export AWS_SESSION_TOKEN=$(cat credentials | jq -r ".Credentials.SessionToken")

op item delete "twelve-platform-${CLUSTER}" --vault cohorts

kube_config=$(cat kubeconfig_${CLUSTER})
op item create --category="API Credential" --title="twelve-platform-${CLUSTER}" --vault cohorts "kubeconfig[password]=$kube_config"

# terraform-aws-eks module v18 method
# terraform output kubeconfig | grep -v "EOT" | opw write platform-${CLUSTER} kubeconfig -

# write cluster url and pubic certificate to 1password
cluster_endpoint=$(terraform output cluster_endpoint | tr -d \\n | sed 's/"//g')
base64_certificate_authority_data=$(terraform output cluster_certificate_authority_data | tr -d \\n | sed 's/"//g')
op item edit "twelve-platform-${CLUSTER}" --vault cohorts cluster-endpoint[password]=$cluster_endpoint base64-certificate-authority-data[password]=$base64_certificate_authority_data

# platform-nonprod-ap-southeast-2
# platform-prod-us-east-1
# terraform output DPSNonprodServiceAccount_encrypted_aws_secret_access_key | sed 's/"//g' | base64 -d | gpg -dq --passphrase ${GPG_KEY_PASSPHRASE} |  opw write twelve-aws DPSNonprodServiceAccount-aws-secret-access-key -
# terraform output DPSNonprodServiceAccount_aws_access_key_id | tr -d \\n | sed 's/"//g' | opw write twelve-aws DPSNonprodServiceAccount-aws-access-key-id -
