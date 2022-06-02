cmd="$@"

kubectl -n vault exec vault-vault-0 -i -t -- sh -c "export VAULT_TOKEN=$VAULT_ROOT_TOKEN; /bin/vault $cmd"

