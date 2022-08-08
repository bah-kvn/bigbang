#!/bin/bash

###############
## Variables ##
###############

#shellcheck disable=SC1091
PROJECT_DIR=$(git rev-parse --show-toplevel)
SCRIPTS_DIR="$PROJECT_DIR/scripts"
if [[ -e "$PROJECT_DIR/00-variables.conf" ]]; then
  source "$PROJECT_DIR/00-variables.conf"
elif [[ -e "$SCRIPTS_DIR/00-variables.conf" ]]; then
  source "$SCRIPTS_DIR/00-variables.conf"
fi

##############
## Pre-reqs ##
##############

# Getting your public ip
YOUR_IP=$(curl -s ifconfig.me)

## Loading creds
export AWS_PROFILE="$AWSAML_PROFILE"
export AWS_DEFAULT_PROFILE="$AWSAML_PROFILE"

########################
## Generating PGP KEY ##
########################

#### Using this multiline command to generate the key makes it work in all cases.
gpg --batch --full-generate-key --rfc4880 --digest-algo sha512 --cert-digest-algo sha512 <<EOF
    %no-protection
    # %no-protection: means the private key won't be password protected
    # (no password is a fluxcd requirement, it might also be true for argo & sops)
    Key-Type: RSA
    Key-Length: 4096
    Subkey-Type: RSA
    Subkey-Length: 4096
    Expire-Date: 0
    Name-Real: bigbang-dev-environment
    Name-Comment: bigbang-dev-environment
EOF

FP=$(\
  gpg --list-keys --fingerprint \
  | grep "bigbang-dev-environment" -B 1 \
  | grep -v "bigbang-dev-environment" \
  | tr -d ' ' \
  | sed -e 's/Keyfingerprint=//g'\
)

# Run the following to set the encryption key
# sed: stream editor is like a cli version of find and replace
# This ensures your secrets are only decryptable by your key

## On MacOS
if [ -f "$PROJECT_DIR/.sops.yaml" ]; then
  sed -i '' 's|pgp: FALSE_KEY_HERE|pgp: '"$FP"'|g' "$PROJECT_DIR/.sops.yaml"
else
  echo "No Sops yaml file, or wrong key (bad clean-up)"; exit 1
fi

#########################
## SSL cert generation ##
#########################

mkdir -p "$HOME/letsencrypt"

docker run -it --rm --name certbot \
  -v "$HOME/letsencrypt:/tmp/letsencrypt" \
  -v "$HOME/.aws/credentials:/root/.aws/credentials" \
  -e AWS_PROFILE=awsaml-729651203190-BAHSSO_Admin_Role \
  -e AWS_DEFAULT_PROFILE=awsaml-729651203190-BAHSSO_Admin_Role \
  certbot/dns-route53 certonly \
    --dns-route53 \
    --dns-route53-propagation-seconds 30 \
    --non-interactive \
    --agree-tos \
    --email "$YOUR_EMAIL" \
    -d "*.$YOUR_SUBDOMAIN.bahsoftwarefactory.com" \
    --work-dir /tmp/letsencrypt \
    --config-dir /tmp/letsencrypt

KEY=$(\
  sed -e 's/^/              /' \
  <"$HOME/letsencrypt/live/$YOUR_SUBDOMAIN.bahsoftwarefactory.com/privkey.pem" \
)
CERT=$(\
  sed -e 's/^/              /'\
  <"$HOME/letsencrypt/live/$YOUR_SUBDOMAIN.bahsoftwarefactory.com/fullchain.pem" \
)

cat > base/secrets.enc.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: common-bb
stringData:
  values.yaml: |-
    registryCredentials:
    - registry: registry1.dso.mil
      username: $IRONBANK_USER
      password: $IRONBANK_PAT
    istio:
      gateways:
        public:
          tls:
            key: |-
$KEY
            cert: |-
$CERT
EOF

# Encrypt the existing certificate and Ironbank creds
sops -e -i base/secrets.enc.yaml

if grep -q "PRIVATE KEY" "$PROJECT_DIR/base/secrets.enc.yaml"; then
  echo "Secrets not encrypted"; exit 1
fi

# Change Configmap
sed -i '' 's|bigbang.dev|'"$YOUR_SUBDOMAIN.bahsoftwarefactory.com"'|g' "$PROJECT_DIR/dev/configmap.yaml"

###########################
## Git repository config ##
###########################
sed -i '' 's|https://replace-with-your-git-repo.git|'"$YOUR_GIT_REPOSITORY"'|g' "$PROJECT_DIR/dev/bigbang.yaml"
sed -i '' 's|replace-with-your-branch|'"$YOUR_GIT_BRANCH"'|g' "$PROJECT_DIR/dev/bigbang.yaml"

##############################
## Security groups creation ##
##############################

## Adding IP to Rancher SG - ok
aws ec2 authorize-security-group-ingress \
  --group-id sg-0da90bd41542ff271 \
  --ip-permissions IpProtocol=all,FromPort=-1,ToPort=-1,IpRanges='[{CidrIp='"$YOUR_IP"/32',Description='"$SG_DESCRIPTION"'}]' \
  --region us-east-1 \
  --no-cli-pager

## Create your Security group
aws ec2 create-security-group \
  --group-name "$YOUR_NAME-rancher-nodes" \
  --description "$YOUR_NAME-rancher-nodes" \
  --vpc-id vpc-023a468241eea5b0b \
  --region us-east-1 \
  --no-cli-pager

SG_ID=$(\
  aws ec2 describe-security-groups \
  --filters \
    Name=vpc-id,Values=vpc-023a468241eea5b0b \
    Name=group-name,Values="$YOUR_NAME-rancher-nodes" \
  --query 'SecurityGroups[*].[GroupId]' \
  --output text\
)

## Adding IP to your cluster SG
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --ip-permissions IpProtocol=all,FromPort=-1,ToPort=-1,IpRanges='[{CidrIp='"$YOUR_IP"/32',Description='"$SG_DESCRIPTION"'}]' \
  --region us-east-1 \
  --no-cli-pager

## Adding rule to cluster communication
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --ip-permissions IpProtocol=all,FromPort=-1,ToPort=-1,UserIdGroupPairs='[{GroupId='"$SG_ID"',Description="Allow Cluster Communication"}]' \
  --region us-east-1 \
  --no-cli-pager

########################
## git add and commit ##
########################
git checkout -b "$YOUR_GIT_BRANCH"

git add .sops.yaml
git commit -m "chore: update default encryption key"

git add base/secrets.enc.yaml
git commit -m "chore: add tls certificate and iron bank pull credentials"

git add dev/bigbang.yaml
git add dev/configmap.yaml
git commit -m "chore: updated git repo"

git push -u origin "$YOUR_GIT_BRANCH"


############
## Output ##
############

echo "
Proceed to https://rancher.bahsoftwarefactory.com/dashboard/c/_/manager/provisioning.cattle.io.cluster/create
and use the following values to deploy your dev cluster:
1 - Add a Cluster Name
2 - Security group:
  name: '$YOUR_NAME-rancher-nodes'
  id: '$SG_ID'
3 - Use the following subnets:
  AZ A - subnet-08942469f925d9b66 (10.40.7.0/24)
  AZ B - subnet-04987f9522e27a836 (10.40.8.0/24)
  AZ C - subnet-069fd7685cca4018a (10.40.9.0/24)
4 - Use the EC2 Instance role:
  BSF_RKE2_ControlPlane_Role
5 - Use the AMI:
  ami-0017560e0ce9d6fbf
6 - Select Cloud Provider - Amazon
7 - Unselect NGINX Ingress
8 - Update variables.conf
  YOUR_SG_ID='$SG_ID'
  YOUR_CLUSTER_VALUE='< value from Mgmt Cluster in Related Resources tab of your new cluster >'
"
