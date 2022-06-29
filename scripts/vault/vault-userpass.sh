vault login $VAULT_TOKEN
#cat bsf-admin.hcl | vault policy write vault_admin -
vault auth enable userpass
vault write auth/userpass/users/root password=$VAULT_PASS policies=vault_admin
vault auth list

