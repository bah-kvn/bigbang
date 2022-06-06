#!/bin/bash

secret="$(kubectl get serviceaccount internal-app -n vault -o go-template='{{ (index .secrets 0).name }}')"
token="$(kubectl get secret ${secret} -n vault -o go-template='{{ .data.token }}' | base64 --decode)"

vault write auth/kubernetes/login role=internal-app jwt=$token

