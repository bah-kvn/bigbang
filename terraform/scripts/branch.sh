#!/bin/bash

mkdir -p $HOME/factory
cd $HOME/factory

export BRANCH="${VARIABLE:=develop}"
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

yq e ".cluster.name = \"$BRANCH-rmc\"" -i $ROOT/software-factory/terragrunt/$AWS_REGION/dev/rmc/cluster.yaml
yq e ".factory.bigbang.branch = \"$BRANCH\"" -i $ROOT/software-factory/terragrunt/$AWS_REGION/dev/rmc/cluster.yaml

yq e ".cluster.name = \"$BRANCH-ssc\"" -i $ROOT/software-factory/terragrunt/$AWS_REGION/dev/ssc/cluster.yaml
yq e ".factory.bigbang.branch = \"$BRANCH\"" -i $ROOT/software-factory/terragrunt/$AWS_REGION/dev/ssc/cluster.yaml

yq e ".cluster.name = \"$BRANCH-wl0\"" -i $ROOT/software-factory/terragrunt/$AWS_REGION/dev/wl0/cluster.yaml
yq e ".factory.bigbang.branch = \"$BRANCH\"" -i $ROOT/software-factory/terragrunt/$AWS_REGION/dev/wl0/cluster.yaml

cd $ROOT/software-factory/terragrunt/$AWS_REGION/dev
echo "Directory=$PWD ROOT=$ROOT " && ls
/usr/local/bin/terragrunt run-all apply  --terragrunt-debug --terragrunt-non-interactive | tee /tmp/apply.log



/usr/local/bin/terragrunt run-all apply  --terragrunt-exclude-dir "factory" --terragrunt-debug --terragrunt-non-interactive
EOF
asciinema rec -i 1.0 -c $BASE/$ROOT/cmd.sh factory.cast



