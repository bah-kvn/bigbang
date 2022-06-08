#!/bin/bash

# Exit if any of the intermediate steps fail
set -e -x

eval "$(jq -r '@sh "KEYPATH=\(.keypath) IP=\(.hostip)"')"

NODE_TOKEN=$(until ssh -o IdentitiesOnly=yes -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' -i $KEYPATH ubuntu@$IP sudo cat /var/lib/rancher/rke2/server/node-token; do sleep 5; done)

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg node_token "$NODE_TOKEN" '{"node_token":$node_token}'
