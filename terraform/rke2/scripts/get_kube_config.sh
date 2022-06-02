#!/bin/bash

# Exit if any of the intermediate steps fail
set -e -x

eval "$(jq -r '@sh "KEYPATH=\(.keypath) IP=\(.hostip) DNS_NAME=\(.dns_name) CLUSTER_NAME=\(.cluster_name)"')"

KUBECONFIG_TEXT=$(until ssh -o IdentitiesOnly=yes -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' -i $KEYPATH ubuntu@$IP kubectl config view --flatten | sed -e 's|127.0.0.1|'$DNS_NAME'|g' -e 's|default|'$CLUSTER_NAME'|g'; do sleep 5; done)

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg kubeconfig "$KUBECONFIG_TEXT" '{"kubeconfig":$kubeconfig}'
