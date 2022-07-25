

kubectl delete secret -n gitlab gitlab-keycloak
cat<<EOF > ./gitlab-keycloak.yaml
name: saml
label: 'Keycloak'
args:
  assertion_consumer_service_url: 'https://gitlab.stg.bahsoftwarefactory.com/users/auth/saml/callback'
  idp_cert: 'MIIClTCCAX0CBgGCNZJ+2jANBgkqhkiG9w0BAQsFADAOMQwwCgYDVQQDDANic2YwHhcNMjIwNzI1MTMzNDI5WhcNMzIwNzI1MTMzNjA5WjAOMQwwCgYDVQQDDANic2YwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC0KCIcdfpLyPdo7mfjlds6TljEfE7eSqMqlDC7GujhdQ+xdlAj8qftBwgVYD2Hu2frfwXx65CIWSy3BIviQtqDudfyyxgwCN5LTCmML0Pcc5S/dbA4B1+Rve8o9I7TDt00Lk3oVFq+kpfPu5ZoN/H53Qi+ttCQdMoLFpLoPNy/KY9H6wz468KvlgGuPioleqTyHhk1OdCSqDVzmP/NX2XjuwTqOP6Xj804/CG1Ypwfn4nwI97LUrf9enAkzcKbs9EGWtDcNMxX043vC2NTh2edttqmzRSOnY6K4nz2KBw3gjUpmJjW9SRchGjerJttyPiBUWJAHudWQmfeWLHvjls5AgMBAAEwDQYJKoZIhvcNAQELBQADggEBAI666IxuPeT4BT/r1Q8tYRFiXKYWxCEA/D3eEzJtIaqlKTzBWW3J++Bu2f8dJgeaiinniobHyDd6kIL8IWEgINXZarN6wAHAsLTDuE4S6/WXg2nwa5Rj8jhqSJpv0pT2Z+nikQ/5GuhGjLMTUJnz+2Ui5jdfSqDRorH1YADBwn/+J4Lw4XTf3NJfqPAQdZ1cq9y56trQm7tkQS4j52pZN58Ai6btbHho/ZIvYZn9bNUtRSr1x3JXOZpfBSfDwOVPlIdyh/T7cUXLQKmuWOqMDI+eGCJWOxcRzuEQMvw2ShhlJXkhYWkCJW0CwihIfVl/p8FgmbnHmEiFJnjtn5gejkA='
  idp_sso_target_url: 'https://keycloak.stg.bahsoftwarefactory.com/auth/realms/bsf/protocol/saml/clients/gitlab.stg.bahsoftwarefactory.com'
  issuer: 'https://gitlab.stg.bahsoftwarefactory.com'
  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid_format:persistent'
EOF

kubectl create secret generic -n gitlab gitlab-keycloak --from-file=provider=gitlab-keycloak.yaml --dry-run=client -o yaml
