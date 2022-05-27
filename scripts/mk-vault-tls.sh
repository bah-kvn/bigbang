

kubectl create secret tls vault-server-tls \
  --namespace='vault' \
  --cert=$HOME/certs/vault.stg.bahsoftwarefactory.com/fullchain.pem \
  --key=$HOME/certs/vault.stg.bahsoftwarefactory.com/privkey.pem
