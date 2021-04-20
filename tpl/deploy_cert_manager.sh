#!/usr/bin/env bash
set -e

# parameters
# $1 = cluster config to use
export CLUSTER=${1}

cat <<EOF > cert-manager-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager
  labels:
    cert-manager.io/disable-validation: "true"
EOF

export AWS_ACCOUNT_ID=$(cat ${CLUSTER}.auto.tfvars.json | jq -r '.account_id')
export CERT_MANAGER_VERSION=$(cat ${CLUSTER}.auto.tfvars.json | jq -r '.cert_manager_version')
export DOMAIN=$(cat ${CLUSTER}.auto.tfvars.json | jq -r '.domain')
export AWS_DEFAULT_REGION=$(cat ${CLUSTER}.auto.tfvars.json | jq -r '.aws_region')
export EMAIL=$(cat ${CLUSTER}.auto.tfvars.json | jq -r '.cert_manager_issuer_email')
export ISSUER_ENDPOINT=$(cat ${CLUSTER}.auto.tfvars.json | jq -r '.cert_manager_issuer_endpoint')


kubectl apply -f cert-manager-namespace.yaml

helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --wait -i cert-manager jetstack/cert-manager --namespace cert-manager --version v${CERT_MANAGER_VERSION} --set installCRDs=true --set securityContext.enabled=true --set securityContext.fsGroup=1001 --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER}-cert-manager
sleep 15

aws sts assume-role --output json --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/DPSTerraformRole --role-session-name deploy-cert-manager-session > credentials
export AWS_ACCESS_KEY_ID=$(cat credentials | jq -r ".Credentials.AccessKeyId")
export AWS_SECRET_ACCESS_KEY=$(cat credentials | jq -r ".Credentials.SecretAccessKey")
export AWS_SESSION_TOKEN=$(cat credentials | jq -r ".Credentials.SessionToken")
export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name $CLUSTER.$DOMAIN | jq -r --arg DNS $CLUSTER.$DOMAIN '.HostedZones[] | select( .Name | startswith($DNS)) | .Id')

cat <<EOF > cluster_domain_certificate_issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-$CLUSTER-issuer
  namespace: cert-manager
spec:
  acme:
    server: $ISSUER_ENDPOINT
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-$CLUSTER
    solvers:
    - selector:
        dnsZones:
          - "$CLUSTER.$DOMAIN"
      dns01:
        route53:
          region: $AWS_DEFAULT_REGION
          hostedZoneID: $HOSTED_ZONE_ID
          # role: arn:aws:iam::$AWS_ACCOUNT_ID:role/$CLUSTER-cert-manager
EOF

kubectl apply -f cluster_domain_certificate_issuer.yaml
