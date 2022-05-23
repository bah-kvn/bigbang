#!/bin/bash

###############
## Variables ##
###############
. variables.conf

##############
## Pre reqs ##
##############

# Getting your public ip
YOUR_IP=$(curl ifconfig.me)

## Loading creds
export AWS_PROFILE=$AWSAML_PROFILE
export AWS_DEFAULT_PROFILE=$AWSAML_PROFILE

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

FP=$(gpg --list-keys --fingerprint | grep "bigbang-dev-environment" -B 1 | grep -v "bigbang-dev-environment" | tr -d ' ' | tr -d 'Keyfingerprint=')

# Run the following to set the encryption key
# sed: stream editor is like a cli version of find and replace
# This ensures your secrets are only decryptable by your key

## On MacOS
sed -i '' 's|pgp: FALSE_KEY_HERE|pgp: '$FP'|g' .sops.yaml

#########################
## SSL cert generation ##
#########################

mkdir -p $HOME/letsencrypt

docker run -it --rm --name certbot \
      -v "$HOME/letsencrypt:/tmp/letsencrypt" \
      -v "${HOME}/.aws/credentials:/root/.aws/credentials" \
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

KEY=$(cat $HOME/letsencrypt/live/$YOUR_SUBDOMAIN.bahsoftwarefactory.com/privkey.pem | sed -e 's/^/              /')
CERT=$(cat $HOME/letsencrypt/live/$YOUR_SUBDOMAIN.bahsoftwarefactory.com/fullchain.pem | sed -e 's/^/              /')

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

# Change Configmap
sed -i '' 's|bigbang.dev|'$YOUR_SUBDOMAIN.bahsoftwarefactory.com'|g' dev/configmap.yaml

###########################
## Git repository config ##
###########################
sed -i '' 's|https://replace-with-your-git-repo.git|'$YOUR_GIT_REPOSITORY'|g' dev/bigbang.yaml 
sed -i '' 's|replace-with-your-branch|'$YOUR_GIT_BRANCH'|g' dev/bigbang.yaml 

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
SG_ID=$(aws ec2 create-security-group \
    --group-name "$YOURNAME-rancher-nodes" \
    --description "$YOURNAME-rancher-nodes" \
    --vpc-id vpc-023a468241eea5b0b \
    --region us-east-1 \
    --no-cli-pager | jq '.GroupId' | sed 's/"//g')

## Adding IP to your cluster SG
aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --ip-permissions IpProtocol=all,FromPort=-1,ToPort=-1,IpRanges='[{CidrIp='"$YOUR_IP"/32',Description='"$SG_DESCRIPTION"'}]' \
    --region us-east-1 \
    --no-cli-pager

## Adding rule to cluster communication
aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --ip-permissions IpProtocol=all,FromPort=-1,ToPort=-1,UserIdGroupPairs='[{GroupId='$SG_ID',Description="Allow Cluster Communication"}]' \
    --region us-east-1 \
    --no-cli-pager

########################
## git add and commit ##
########################
git checkout -b $YOUR_GIT_BRANCH

git add .sops.yaml
git commit -m "chore: update default encryption key"
git add base/secrets.enc.yaml
git commit -m "chore: add tls certificate and iron bank pull credentials"
git add dev/bigbang.yaml
git commit -m "chore: updated git repo"

git push -u origin $YOUR_GIT_BRANCH


############
## Output ##
############

echo "
Proceed to https://rancher.bahsoftwarefactory.com/dashboard/c/_/manager/provisioning.cattle.io.cluster/create
and use the following values to deploy yout dev cluster:
1 - Security group:
  name: '$YOURNAME-rancher-nodes'
  id: '$SG_ID'
2 - Use the following subnets:
  AZ A - subnet-08942469f925d9b66 (10.40.7.0/24)
  AZ B - subnet-04987f9522e27a836 (10.40.8.0/24)
  AZ C - subnet-069fd7685cca4018a (10.40.9.0/24)
3 - Use the EC2 Instance role:
  BSF_RKE2_ControlPlane_Role
4 - Use the AMI:
  ami-0017560e0ce9d6fbf
5 - Select Cloud Provider - Amazon
6 - UN-Select NGINX Ingress
"
