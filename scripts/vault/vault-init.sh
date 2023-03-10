

#kubectl create secret tls vault-server-tls \
#  --namespace='vault' \
#  --cert=$HOME/certs/vault.stg.bahsoftwarefactory.com/fullchain.pem \
#  --key=$HOME/certs/vault.stg.bahsoftwarefactory.com/privkey.pem

( kubectl exec -i -t vault-vault-0 -- vault operator init ) | tee init


cat init | grep ':' | sed 's/Initial Root Token: /export VAULT_ROOT_TOKEN=/g' | grep export | tee set_root_token.sh && chmod 755 set_root_token.sh
#cp set_root_token.sh $SCRIPTS/env/
cat init | grep "Recovery" | cut -d':' -f2 | sed "s/^/kubectl exec -i -t vault-vault-0 -- vault operator unseal /g" | head -n3 | tee unseal.sh ; chmod 755 unseal.sh


