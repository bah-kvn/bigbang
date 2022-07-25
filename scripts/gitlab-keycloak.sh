

kubectl delete secret -n gitlab gitlab-keycloak
cat<<EOF > ./gitlab-keycloak.yaml
name: saml
label: 'Keycloak'
args:
  assertion_consumer_service_url: 'https://gitlab.$DOMAIN/users/auth/saml/callback'
  idp_cert: ''
  idp_sso_target_url: 'https://keycloak.$DOMAIN/auth/realms/bsf/protocol/saml/clients/gitlab.$DOMAIN'
  issuer: 'https://gitlab.$DOMAIN'
  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid_format:persistent'
EOF

kubectl create secret generic -n gitlab gitlab-keycloak --from-file=provider=gitlab-keycloak.yaml
