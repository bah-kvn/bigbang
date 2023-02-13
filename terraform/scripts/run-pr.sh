
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
cd software-factory
gh pr checkout 16
cd ./terragrunt/us-east-1/dev 
echo "Directory=$PWD"
./single-touch.sh
EOF
asciinema rec -i 1.0 -c $BASE/$ROOT/cmd.sh factory.cast

