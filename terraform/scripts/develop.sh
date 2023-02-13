#!/bin/bash
set -euo pipefail

mkdir -p $HOME/factory
cd $HOME/factory

# run from the develop branch , and use the bigbang config in the develop branch of the bigbang repo 
export BRANCH="develop"
echo "Branch = $BRANCH"

export BASE=$PWD
export ts="$(date +%Y-%m-%d_%H-%M-%S)"
export ROOT="$BRANCH-$ts"
mkdir $ROOT
cd $ROOT
echo "Timestamp=$ts"
echo "BASE=$BASE"
echo "ROOT=$ROOT"
echo "Directory=$PWD"

tee <<EOF  | tee cmd.sh && chmod 755 cmd.sh

git clone git@github.com:boozallen/software-factory.git && \
cd software-factory && \
git checkout $BRANCH && \
git status && \
cd $BASE

yq e ".cluster.name = \"rmc\"" -i $ROOT/software-factory/terragrunt/$AWS_REGION/dev/rmc/cluster.yaml
yq e ".factory.bigbang.branch = \"$BRANCH\"" -i $ROOT/software-factory/terragrunt/$AWS_REGION/dev/rmc/cluster.yaml

yq e ".cluster.name = \"ptc\"" -i $ROOT/software-factory/terragrunt/$AWS_REGION/dev/ptc/cluster.yaml
yq e ".factory.bigbang.branch = \"$BRANCH\"" -i $ROOT/software-factory/terragrunt/$AWS_REGION/dev/ptc/cluster.yaml

cd $ROOT/software-factory/terragrunt/$AWS_REGION/dev
echo "Directory=$PWD ROOT=$ROOT " 

# Don't deploy the wl0 and ssc clusters, and dont ask any questions
/usr/local/bin/terragrunt run-all apply  --terragrunt-debug  --terragrunt-exclude-dir="wl0/*" --terragrunt-exclude-dir="ssc/*" --terragrunt-non-interactive | tee /tmp/apply.log

EOF

$ROOT/software-factory/terragrunt/scripts/hosts.sh

asciinema rec -i 1.0 -c $BASE/$ROOT/cmd.sh factory.cast
cp $ROOT/software-factory/terragrunt/$AWS_REGION/dev/rmc/kubeconfig /tmp/rmc.kubeconfig
cp $ROOT/software-factory/terragrunt/$AWS_REGION/dev/rmc/kubeconfig $HOME/.kube/config
cp $ROOT/software-factory/terragrunt/$AWS_REGION/dev/ptc/kubeconfig /tmp/ptc.kubeconfig

$ROOT/software-factory/terragrunt/hosts.sh
