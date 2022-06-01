


sops -d base/secrets.enc.yaml | yq '.stringData."values.yaml"' | yq '.istio.vault.tls.cert' > /tmp/istio_vault_tls_cert.cert
sops -d base/secrets.enc.yaml | yq '.stringData."values.yaml"' | yq '.istio.gateways.public.tls.cert' > /tmp/istio_gateways_tls_cert.cert
sops -d base/secrets.enc.yaml | yq '.stringData."values.yaml"' | yq '.addons.vault.ingress.cert' > /tmp/addons_vault_ingress_cert.cert 
echo istio.vault.tls.cert
openssl x509 -in /tmp/istio_vault_tls_cert.cert -text | grep 'Subject: CN='
echo
echo istio.gateways.tls.cert
openssl x509 -in /tmp/istio_gateways_tls_cert.cert -text | grep 'Subject: CN='
echo
echo addons.vault.ingress.cert
openssl x509 -in /tmp/addons_vault_ingress_cert.cert -text | grep 'Subject: CN='
echo


echo verify vault config
echo "https://repo1.dso.mil/platform-one/big-bang/apps/sandbox/vault/-/blob/main/docs/production-ha.md"
sops -d base/secrets.enc.yaml | yq '.stringData."values.yaml"' | yq '.addons.vault.ingress'
