#!/bin/bash
#run from $HOME/factory
export BASE=$PWD
export ts="$(date +%Y-%m-%d_%H-%M-%S)"
export ROOT="demo-$ts"
mkdir $ROOT
cd $ROOT
echo "Timestamp=$ts"
echo "BASE=$BASE"
echo "ROOT=$ROOT"
echo "Directory=$PWD"

tee <<EOF  | tee cmd.sh && chmod 755 cmd.sh
git clone git@github.com:boozallen/software-factory.git
cd ./software-factory/terragrunt/us-east-1/dev 
echo "Directory=$PWD"
./single-touch.sh
EOF
asciinema rec -i 1.0 -c $BASE/$ROOT/cmd.sh factory.cast

termsvg export factory.cast
#docker run --rm -v $PWD:/data asciinema/asciicast2gif [options and arguments...]

#cd $BASE
