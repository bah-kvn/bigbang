
secret="$(kubectl get serviceaccount vault-auth -n vault -o go-template='{{ (index .secrets 0).name }}')"
echo "secret=$secret"
token="$(kubectl get secret ${secret} -n vault -o go-template='{{ .data.token }}' | base64 --decode)"
echo "token=$token"
vault write auth/kubernetes/login role=example jwt=$token

