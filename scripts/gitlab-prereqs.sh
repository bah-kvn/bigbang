#!/bin/sh

# gitlab-csn-secret.sh
./gitlab-public-secret.sh

#gitlab-keycloak.sh
kubectl delete secret -n gitlab gitlab-keycloak

cat <<EOF > ./gitlab-keycloak.yaml
name: saml
label: 'Keycloak'
args:
  assertion_consumer_service_url: 'https://gitlab.stg.bahsoftwarefactory.com/users/auth/saml/callback'
  idp_cert: ''
  idp_sso_target_url: 'https://keycloak.stg.bahsoftwarefactory.com/auth/realms/bsf/protocol/saml/clients/gitlab.stg.bahsoftwarefactory.com'
  issuer: 'https://gitlab.stg.bahsoftwarefactory.com'
  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid_format:persistent'
EOF
kubectl create secret generic -n gitlab gitlab-keycloak --from-file=provider=gitlab-keycloak.yaml

#gitlab-storage-secrets.sh
kubectl delete secret  -n gitlab gitlab-registry-storage
kubectl delete secret  -n gitlab gitlab-rails-storage
kubectl delete secret  -n gitlab gitlab-storage-config

tee /tmp/gitlab-rails-storage.yaml <<EOF
provider: AWS
region: us-east-1
EOF

tee /tmp/storage.config <<EOF
[default]
bucket_location = us-east-1
multipart_chunk_size_mb = 128
EOF

tee /tmp/registry-storage.yaml <<EOF
s3:
  bucket: gitlab-registry-storage
  region: us-east-1
  v4auth: true
EOF

kubectl create secret generic -n gitlab gitlab-registry-storage --from-file=config=/tmp/registry-storage.yaml
kubectl create secret generic -n gitlab gitlab-rails-storage --from-file=connection=/tmp/gitlab-rails-storage.yaml
kubectl create secret generic -n gitlab gitlab-storage-config --from-file=config=/tmp/storage.config
