

kubectl create secret tls vault-server-tls \
  --namespace='vault' \
  --cert=$HOME/certs/vault.stg.bahsoftwarefactory.com/fullchain.pem \
  --key=$HOME/certs/vault.stg.bahsoftwarefactory.com/privkey.pem

( kubectl exec -i -t vault-vault-0 -- vault operator init ) | tee init


cat init | grep ':' | sed 's/Initial Root Token: /export VAULT_ROOT_TOKEN=/g' | grep export | tee set_root_token.sh
