

kubectl create secret tls vault-server-tls \
  --namespace='vault' \
  --cert=$HOME/certs/vault.dev.bahsoftwarefactory.com/fullchain.pem \
  --key=$HOME/certs/vault.dev.bahsoftwarefactory.com/privkey.pem
