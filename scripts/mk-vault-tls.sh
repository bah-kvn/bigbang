

kubectl create secret tls vault-server-tls \
  --namespace='vault' \
  --cert=$HOME/certs/vault.bahsoftwarefactory.com/fullchain.pem \
  --key=$HOME/certs/vault.bahsoftwarefactory.com/privkey.pem
