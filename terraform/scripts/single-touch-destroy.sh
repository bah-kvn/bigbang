#!/bin/bash

#deploy factory - skip the ptc cluster and the ssc cluster (rmc & wl0 deploy)
cd ../$AWS_REGION/dev && terragrunt run-all destroy --terragrunt-non-interactive --terragrunt-ignore-dependency-errors 
