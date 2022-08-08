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

## Loading creds
export AWS_PROFILE="$AWSAML_PROFILE"
export AWS_DEFAULT_PROFILE="$AWSAML_PROFILE"
export KUBECONFIG="$KUBECONFIG"

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

if grep -q "PRIVATE KEY" base/secrets.enc.yaml; then
  echo "Secrets not encrypted"; exit 1
fi

# Change Configmap
sed -i '' 's|bigbang.dev|'"$YOUR_SUBDOMAIN.bahsoftwarefactory.com"'|g' dev/configmap.yaml

###########################
## Git repository config ##
###########################
sed -i '' 's|https://replace-with-your-git-repo.git|'"$YOUR_GIT_REPOSITORY"'|g' dev/bigbang.yaml
sed -i '' 's|replace-with-your-branch|'"$YOUR_GIT_BRANCH"'|g' dev/bigbang.yaml

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

##################
## PSP settings ##
##################

kubectl patch psp system-unrestricted-psp -p '{\
  "metadata": {\
    "annotations": {\
      "seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"\
    }\
  }\
}'
kubectl patch psp global-unrestricted-psp -p '{\
  "metadata": {\
    "annotations": {\
      "seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"\
    }\
  }\
}'
kubectl patch psp global-restricted-psp -p '{\
  "metadata": {\
    "annotations": {\
      "seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"\
    }\
  }\
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
# The private key is not stored in Git (and should NEVER be stored there).
# We deploy it manually by exporting the key into a secret.
kubectl create namespace bigbang
gpg --export-secret-key --armor "$GPG_KEY" \
  | kubectl create secret generic sops-gpg -n bigbang --from-file=bigbangkey.asc=/dev/stdin

# Image pull secrets for Iron Bank are required to install flux.
# After that, it uses the pull credentials we installed above
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
  --from-literal="password='$YOUR_GIT_PAT'"

###################################
## Deploy Flux to handle syncing ##
###################################

# Flux is used to sync Git with the the cluster configuration
# If you are using a different version of Big Bang, make sure to update the `?ref=1.31.0` to the correct tag or branch.
kustomize build "$FLUX_KUSTOMIZATION" \
  | sed "s/registry1.dso.mil/${REGISTRY_URL}/g" \
  | kubectl apply -f -

# Wait for flux to complete
kubectl get deploy -o name -n flux-system | xargs -n1 -t kubectl rollout status -n flux-system

#####################
## Deploy Big Bang ##
#####################
kubectl apply -f dev/bigbang.yaml

until kubectl --kubeconfig Downloads/sls.yaml get svc -n istio-system public-ingressgateway -o json \
  | jq '.status[].ingress[].hostname' \
  | grep "elb.us-east-1.amazonaws.com"; do sleep 5; done

# Create route53 entry
LB_ARN=$(aws resourcegroupstaggingapi get-resources \
    --tag-filters Key=kubernetes.io/cluster/"$YOUR_CLUSTER_VALUE",Values=owned \
    --resource-type-filters elasticloadbalancing:loadbalancer \
    --tags-per-page 100 \
    --region us-east-1 \
    --no-cli-pager | \
  jq '.ResourceTagMappingList[0].ResourceARN' | \
  sed 's/"//g')

LB_DNS_NAME=$(\
  aws elbv2 describe-load-balancers \
    --load-balancer-arns "$LB_ARN" \
    --region us-east-1 \
    --no-cli-pager \
  | jq '.LoadBalancers[0].DNSName' \
  | sed 's/"//g'\
)

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
