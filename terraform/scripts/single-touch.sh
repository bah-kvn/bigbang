#!/bin/bash

### deploy factory 
cd ../$AWS_REGION/dev && terragrunt run-all apply  --terragrunt-debug --terragrunt-non-interactive


### Examples:
###    deploy factory - skip the ptc cluster and the ssc cluster (rmc & wl0 deploy)
#      terragrunt run-all apply  --terragrunt-debug  --terragrunt-exclude-dir="ptc/*" --terragrunt-exclude-dir="ssc/*" --terragrunt-non-interactive

