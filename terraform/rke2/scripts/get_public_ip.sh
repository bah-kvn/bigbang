#!/bin/bash

# Exit if any of the intermediate steps fail
set -e -x

PUBLIC_IP=$(curl ifconfig.me)

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg public_ip "$PUBLIC_IP" '{"public_ip":$public_ip}'
