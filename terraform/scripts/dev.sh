#!/bin/bash

mkdir -p $HOME/factory
cd $HOME/factory

BRANCH="$(basename $0 | cut -d'.' -f1)"
BASE=$PWD
TS="$(date +%Y-%m-%d_%H-%M-%S)"
ROOT="$BASE/$BRANCH-$TS"
echo "Root = $ROOT"

mkdir $ROOT
cd $ROOT
rm -rf $HOME/factory/latest
ln -s $ROOT $HOME/factory/latest
#tee <<EOF  | tee cmd.sh && chmod 755 cmd.sh

git clone git@github.com:boozallen/bigbang.git && \
cd bigbang && \
git checkout $BRANCH && \
git status && \
cd $BASE

export ADDITIONAL_RESOURCE_TAGS="kubernetes.io/cluster/$CLUSTER_NAME=owned,ingress-type=public"
cluster_slugs="ptc rmc wl0"
for cs in $cluster_slugs; do
  ADDITIONAL_RESOURCE_TAGS="kubernetes.io/cluster/$BRANCH-$csE=owned,ingress-type=public"
  DOMAIN=$(cat $ROOT/bigbang/terraform/$AWS_REGION/dev/env.yaml | yq '.domain')
  SUB_DOMAIN="$BRANCH-$cs.$DOMAIN"
  yq e ".cluster.name = \"$BRANCH-$cs\"" -i $ROOT/bigbang/terraform/$AWS_REGION/dev/$cs/cluster.yaml
  yq e ".factory.bigbang.branch = \"$BRANCH\"" -i $ROOT/bigbang/terraform/$AWS_REGION/dev/$cs/cluster.yaml
  yq e '.domain = strenv($SUB_DOMAIN)' $ROOT/bigbang/$cs/configmap.yaml
  yq e '.istio.ingressGateways.public-ingressgateway.kubernetesResourceSpec.serviceAnnotations."service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = strenv(ADDITIONAL_RESOURCE_TAGS)' $ROOT/bigbang/$cs/configmap.yaml
done

cd $ROOT/bigbang/terraform/$AWS_REGION/dev

echo "terragrunt run-all apply  --terragrunt-debug --terragrunt-non-interactive | tee $ROOT/$BRANCH-deploy.log"

#EOF

#asciinema rec -i 1.0 -c $BASE/$ROOT/cmd.sh factory.cast

