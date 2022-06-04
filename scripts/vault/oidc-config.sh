source $SCRIPTS/env/stg-vault-env.sh

cat <<EOF > ./oidc.hcl
path "sys/auth/oidc" {
  capabilities = [ "create", "read", "update", "delete", "sudo" ]
}
path "auth/oidc/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}
path "sys/policies/acl/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}
path "sys/mounts" {
  capabilities = [ "read" ]
}
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF

vault login $VAULT_TOKEN
cat ./oidc.hcl | vault policy write oidc -
vault auth enable oidc
vault write auth/oidc/config \
    oidc_discovery_url="https://gitlab.stg.bahsoftwarefactory.com" \
    oidc_client_id="$VAULT_GITLAB_OIDC_ID" \
    oidc_client_secret="$VAULT_GITLAB_OIDC_SECRET" \
    default_role="oidc-auth"
vault write auth/oidc/role/oidc-auth \
    bound_audiences="$VAULT_GITLAB_OIDC_ID" \
    allowed_redirect_uris="https://vault.stg.bahsoftwarefactory.com/oidc/callback" \
    allowed_redirect_uris="https://vault.stg.bahsoftwarefactory.com/ui/vault/auth/oidc/oidc/callback" \
    allowed_redirect_uris="http://127.0.0.1:8200/ui/vault/auth/oidc/oidc/callback" \
    user_claim="sub" \
    policies="oidc-auth"
vault auth list


