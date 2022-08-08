#!/usr/bin/env bash
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

## Loading creds
export KUBECONFIG=/tmp/files/$KUBECONFIG

#########################
## SSL cert generation ##
#########################
mkdir -p /tmp/creds/files

certbot certonly \
  --dns-route53 \
  --dns-route53-propagation-seconds 30 \
  --non-interactive \
  --agree-tos \
  --email "$YOUR_EMAIL" \
  -d "*.$YOUR_SUBDOMAIN.bahsoftwarefactory.com" \
  --work-dir /tmp/creds/files/letsencrypt \
  --config-dir /tmp/creds/files/letsencrypt

KEY=$(\
  sed -e 's/^/              /' \
  <"$HOME/letsencrypt/live/$YOUR_SUBDOMAIN.bahsoftwarefactory.com/privkey.pem" \
)
CERT=$(\
  sed -e 's/^/              /'\
  <"$HOME/letsencrypt/live/$YOUR_SUBDOMAIN.bahsoftwarefactory.com/fullchain.pem" \
)

## Backup Certs to S3
aws s3 cp \
  /tmp/creds/files/letsencrypt/ \
  "s3://bsf-dev-deployments/$YOUR_CLUSTER_VALUE/files/letsencrypt" \
  --recursive

cat > /tmp/bigbang/base/secrets.enc.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: common-bb
stringData:
  values.yaml: |-
    registryCredentials:
    - registry: $REGISTRY_URL
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

# Change Configmap
sed -i 's|bigbang.dev|'"$YOUR_SUBDOMAIN"'.bahsoftwarefactory.com|g' /tmp/bigbang/dev/configmap.yaml

########################
## Generating PGP KEY ##
########################

#### Using this multiline command to generate the key makes it work in all cases.
if ! gpg --list-keys --fingerprint | grep -q 'bigbang-dev-environment'; then
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
fi

FP=$(\
  gpg --list-keys --fingerprint \
  | grep "bigbang-dev-environment" -B 1 \
  | grep -v "bigbang-dev-environment" \
  | tr -d ' ' \
  | sed -e 's/Keyfingerprint=//g'\
)

## Backup GPG Key to S3
aws s3 cp /root/.gnupg/ "s3://bsf-dev-deployments/$YOUR_CLUSTER_VALUE/files/.gnupg" --recursive
# cp -R /root/.gnupg/ /tmp/creds/files

# Run the following to set the encryption key
# sed: stream editor is like a cli version of find and replace
# This ensures your secrets are only decryptable by your key

## On linux
sed -i "s/pgp: FALSE_KEY_HERE/pgp: $FP/" /tmp/bigbang/.sops.yaml

# if [ $? -ne "0" ]; then
#   echo "No Sops yaml file, or wrong key (bad clean-up)"; exit 1
# fi

# Encrypt the existing certificate and Ironbank creds
cd "$PROJECT_DIR/bigbang" || exit 1
sops -e -i /tmp/bigbang/base/secrets.enc.yaml

# grep "PRIVATE KEY" /tmp/bigbang/base/secrets.enc.yaml
# if [ $? -eq "0" ]; then
#   echo "Secrets not encrypted"; exit 1
# fi

###########################
## Git repository config ##
###########################
sed -i 's|https://replace-with-your-git-repo.git|'"$YOUR_GIT_REPOSITORY"'|g' /tmp/bigbang/dev/bigbang.yaml
sed -i 's|replace-with-your-branch|'"$YOUR_GIT_BRANCH"'|g' /tmp/bigbang/dev/bigbang.yaml

########################
## git add and commit ##
########################

git config --global user.email "$YOUR_EMAIL"
git config --global user.name "$YOUR_GIT_USER"

git checkout -b "$YOUR_GIT_BRANCH"

git add .sops.yaml
git commit -m "chore: update default encryption key"
git add base/secrets.enc.yaml
git commit -m "chore: add tls certificate and iron bank pull credentials"
git add dev/bigbang.yaml
git add dev/configmap.yaml
git commit -m "chore: updated git repo"

# git push -u origin "$YOUR_GIT_BRANCH"

# Pushes the mirror to the new repository on GitHub.com
GIT_REPO=$(echo "$YOUR_GIT_REPOSITORY" | sed 's/https:\/\///g')
git push --mirror "https://$YOUR_GIT_PAT@$GIT_REPO"

##################
## PSP settings ##
##################

kubectl patch psp system-unrestricted-psp -p '{
  "metadata": {
    "annotations": {
      "seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"
    }
  }
}'
kubectl patch psp global-unrestricted-psp -p '{
  "metadata": {
    "annotations": {
      "seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"
    }
  }
}'
kubectl patch psp global-restricted-psp -p '{
  "metadata": {
    "annotations": {
      "seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"
    }
  }
}'

######################
## Install longhorn ##
######################

helm repo add longhorn https://charts.longhorn.io

helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace

kubectl -n longhorn-system rollout status deployment/longhorn-driver-deployer

########################
## Pre reqs to Deploy ##
########################
# The private key is not stored in Git (and should NEVER be stored there).  We deploy it manually by exporting the key into a secret.
kubectl create namespace bigbang
gpg --export-secret-key --armor "$FP" \
  | kubectl create secret generic sops-gpg \
    --namespace bigbang \
    --from-file=bigbangkey.asc=/dev/stdin

# Image pull secrets for Iron Bank are required to install flux.  After that, it uses the pull credentials we installed above
kubectl create namespace flux-system

# Adding a space before this command keeps our PAT out of our history
kubectl create secret docker-registry private-registry \
  --namespace flux-system \
  --docker-server=registry1.dso.mil \
  --docker-username="$IRONBANK_USER" \
  --docker-password="$IRONBANK_PAT"

# Flux needs the Git credentials to access your Git repository holding your environment
# Adding a space before this command keeps our PAT out of our history
kubectl create secret generic private-git \
  --namespace bigbang \
  --from-literal="username='$YOUR_GIT_USER'" \
  --from-literal="password='$YOUR_GIT_PAT'" \

###################################
## Deploy Flux to handle syncing ##
###################################

# Flux is used to sync Git with the the cluster configuration
# If you are using a different version of Big Bang, make sure to update the `?ref=1.31.0` to the correct tag or branch.
kustomize build "$FLUX_KUSTOMIZATION" | sed "s/registry1.dso.mil/$REGISTRY_URL/g" | kubectl apply -f -

# Wait for flux to complete
kubectl get deploy -o name -n flux-system | xargs -n1 -t kubectl rollout status -n flux-system

#####################
## Deploy Big Bang ##
#####################
kubectl apply -f dev/bigbang.yaml

until kubectl get svc -n istio-system public-ingressgateway -o json \
  | jq '.status[].ingress[].hostname' \
  | grep "amazonaws.com"; do sleep 5; done

# Create route53 entry

## LB ARN for ELBv2 (network load balancer)
# LB_ARN=$(\
#   aws resourcegroupstaggingapi get-resources \
#     --tag-filters Key=kubernetes.io/cluster/"$YOUR_CLUSTER_VALUE",Values=owned \
#     --resource-type-filters elasticloadbalancing:loadbalancer \
#     --tags-per-page 100 \
#     --region us-east-1 \
#     --no-cli-pager \
#   | jq '.ResourceTagMappingList[0].ResourceARN' \
#   | sed 's/"//g'\
# )

LB_ARN=$(\
  aws resourcegroupstaggingapi get-resources \
    --tag-filters Key=kubernetes.io/cluster/"$YOUR_CLUSTER_VALUE",Values=owned \
    --resource-type-filters elasticloadbalancing:loadbalancer \
    --tags-per-page 100 \
    --region us-east-1 \
    --no-cli-pager \
  | jq '.ResourceTagMappingList[0].ResourceARN' \
  | sed 's/arn:aws:elasticloadbalancing:us-east-1:729651203190:loadbalancer\///g' \
  | sed 's/"//g'\
)

## LB DNS NAME for ELBv2 (network load balancer)
# LB_DNS_NAME=$(aws elbv2 describe-load-balancers \
#   --load-balancer-arns $LB_ARN \
#   --region us-east-1 \
#   --no-cli-pager | \
#   jq '.LoadBalancers[0].DNSName' | \
#   sed 's/"//g')

LB_DNS_NAME=$(\
  aws elb describe-load-balancers \
    --load-balancer-name "$LB_ARN" \
    --region us-east-1 \
    --no-cli-pager \
  | jq '.LoadBalancerDescriptions[0].DNSName' \
  | sed 's/"//g'\
)

## Register DNSName

aws route53 change-resource-record-sets --hosted-zone-id Z035959739Z0LUKSAJZYX --change-batch '
{
  "Comment": "CREATE a record ",
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "*.'"$YOUR_SUBDOMAIN"'.bahsoftwarefactory.com",
      "Type": "CNAME",
      "TTL": 60,
      "ResourceRecords": [{
        "Value": "'"$LB_DNS_NAME"'"
      }]
    }
  }]
}' --no-cli-pager

## Adding IP to Loadbalancer SG - ok if Classic LB then uncomment.
LB_SG=$(\
  aws elb describe-load-balancers \
    --load-balancer-name "$LB_ARN" \
    --region us-east-1 \
    --no-cli-pager \
  | jq '.LoadBalancerDescriptions[0].SecurityGroups[0]' \
  | sed 's/"//g'\
)

YOUR_IP=$(curl checkip.amazonaws.com)

aws ec2 authorize-security-group-ingress \
  --group-id "$LB_SG" \
  --ip-permissions IpProtocol=all,FromPort=-1,ToPort=-1,IpRanges='[{CidrIp='"$YOUR_IP"/32',Description='"$SG_DESCRIPTION"'}]' \
  --region us-east-1 \
  --no-cli-pager

############
## Output ##
############

echo "
Useful Commands now are:
kubectl get nodes
kubectl get po -A
kubectl get hr -A
After a few minutes:
kubectl get gitrepo -A
After a few more minutes:
kubectl get vs -A
Troubleshooting:
kubectl api-resources
"
