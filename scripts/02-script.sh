#!/bin/bash

###############
## Variables ##
###############
. variables.conf

## Loading creds
export AWS_PROFILE=$AWSAML_PROFILE
export AWS_DEFAULT_PROFILE=$AWSAML_PROFILE
export KUBECONFIG=$KUBECONFIG

#######################
## Resources tagging ##
#######################

aws resourcegroupstaggingapi tag-resources \
    --resource-arn-list arn:aws:ec2:us-east-1:729651203190:security-group/$YOUR_SG_ID \
    --tags kubernetes.io/cluster/$YOUR_CLUSTER_VALUE=owned \
    --region us-east-1 \
    --no-cli-pager

aws resourcegroupstaggingapi tag-resources \
    --resource-arn-list arn:aws:ec2:us-east-1:729651203190:vpc/vpc-023a468241eea5b0b \
    --tags kubernetes.io/cluster/$YOUR_CLUSTER_VALUE=shared \
    --region us-east-1 \
    --no-cli-pager

aws resourcegroupstaggingapi tag-resources \
    --resource-arn-list arn:aws:ec2:us-east-1:729651203190:subnet/subnet-069fd7685cca4018a \
    --tags kubernetes.io/cluster/$YOUR_CLUSTER_VALUE=shared \
    --region us-east-1 \
    --no-cli-pager
  
aws resourcegroupstaggingapi tag-resources \
    --resource-arn-list arn:aws:ec2:us-east-1:729651203190:subnet/subnet-08942469f925d9b66 \
    --tags kubernetes.io/cluster/$YOUR_CLUSTER_VALUE=shared \
    --region us-east-1 \
    --no-cli-pager
  
aws resourcegroupstaggingapi tag-resources \
    --resource-arn-list arn:aws:ec2:us-east-1:729651203190:subnet/subnet-04987f9522e27a836 \
    --tags kubernetes.io/cluster/$YOUR_CLUSTER_VALUE=shared \
    --region us-east-1 \
    --no-cli-pager

##################
## PSP settings ##
##################

kubectl patch psp system-unrestricted-psp -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'
kubectl patch psp global-unrestricted-psp -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'
kubectl patch psp global-restricted-psp -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'

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
gpg --export-secret-key --armor $GPG_KEY | kubectl create secret generic sops-gpg -n bigbang --from-file=bigbangkey.asc=/dev/stdin

# Image pull secrets for Iron Bank are required to install flux.  After that, it uses the pull credentials we installed above
kubectl create namespace flux-system

# Adding a space before this command keeps our PAT out of our history
kubectl create secret docker-registry private-registry --docker-server=registry1.dso.mil --docker-username=$IRONBANK_USER --docker-password=$IRONBANK_PAT -n flux-system

# Flux needs the Git credentials to access your Git repository holding your environment
# Adding a space before this command keeps our PAT out of our history
kubectl create secret generic private-git --from-literal=username=$YOUR_GIT_USER --from-literal=password=$YOUR_GIT_PAT -n bigbang

###################################
## Deploy Flux to handle syncing ##
###################################

# Flux is used to sync Git with the the cluster configuration
# If you are using a different version of Big Bang, make sure to update the `?ref=1.31.0` to the correct tag or branch.
kustomize build "$FLUX_KUSTOMIZATION" | sed "s/registry1.dso.mil/${REGISTRY_URL}/g" | kubectl apply -f -

# Wait for flux to complete
kubectl get deploy -o name -n flux-system | xargs -n1 -t kubectl rollout status -n flux-system

#####################
## Deploy Big Bang ##
#####################
kubectl apply -f dev/bigbang.yaml

