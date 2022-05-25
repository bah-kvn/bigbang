
metadata:
  annotations:
    meta.helm.sh/release-name: bigbang
    meta.helm.sh/release-namespace: bigbang
  creationTimestamp: "2022-05-24T17:54:03Z"
  labels:
    app.kubernetes.io/managed-by: Helm
    helm.toolkit.fluxcd.io/name: bigbang
    helm.toolkit.fluxcd.io/namespace: bigbang
  name: bigbang-keycloak-values
  namespace: bigbang
  resourceVersion: "1146619"
  uid: fec1c686-ba92-404e-a036-5b000fa629ef
type: generic



apiVersion: v1
kind: Secret
metadata:
  name: vault-tls
  namespace: vault
  labels:
    app.kubernetes.io/name: "vault-tls"
type: kubernetes.io/tls
data:
  tls.crt: {{ .Values.istio.vault.tls.cert | b64enc }}
  tls.key: {{ .Values.istio.vault.tls.key | b64enc }}

