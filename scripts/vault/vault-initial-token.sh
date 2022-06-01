
rm -rf ./vault.env
echo "export VAULT_ADDR=\"https://vault.dev.bahsoftwarefactory.com\"" >> ./vault.env

export VAULT_TOKEN="$(kubectl get secrets vault-token -o yaml | yq '.data."init.out"' | base64 -d | grep '^Initial Root' | cut -d':' -f2 | tr -d ' ')"
echo "export VAULT_TOKEN='$VAULT_TOKEN'" >> ./vault.env
source ./vault.env
chmod 700 ./vault.env
