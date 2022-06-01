#!/bin/bash


vault secrets disable internal
vault auth disable kubernetes

vault auth enable kubernetes
vault secrets enable -path=bigbang kv-v2

source $SCRIPTS/env/stg-vault-env.sh
kubectl -n vault exec vault-vault-0 -i -t -- sh -c "export VAULT_TOKEN=$VAULT_ROOT_TOKEN; \
  vault write auth/kubernetes/config \
    token_reviewer_jwt=\"\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)\" \
    kubernetes_host=\"https://\$KUBERNETES_PORT_443_TCP_ADDR:443\" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt "

vault kv put bigbang/gitlab/testsecret username="bbuser1" password="password1"
vault kv get bigbang/gitlab/testsecret
vault policy write internal-app - <<EOF
path "bigbang/data/gitlab/testsecret" {
  capabilities = ["read"]
}
EOF
vault write auth/kubernetes/role/internal-app bound_service_account_names=internal-app bound_service_account_namespaces=mynamespace policies=internal-app ttl=24h

kubectl create ns mynamespace
kubectl -n mynamespace create sa internal-app
kubectl get secret -n flux-system private-registry -o yaml | kubectl neat | yq '.metadata.namespace = "mynamespace"' | kubectl apply -n mynamespace -f -

tee /tmp/full_deploy.yaml <<EOF 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mshell
  labels:
    app: mshell
spec:
  selector:
    matchLabels:
      app: mshell
  template:
    metadata:
      labels:
        app: mshell
        vault-ingress: "true"
      annotations:
        vault.hashicorp.com/agent-inject: 'true'
        vault.hashicorp.com/agent-init-first: 'true'
        vault.hashicorp.com/role: 'internal-app'
        vault.hashicorp.com/agent-inject-secret-testsecret: 'bigbang/data/gitlab/testsecret'
    spec:
      serviceAccountName: internal-app
      imagePullSecrets:
        - name: private-registry
      containers:
      - name: mshell
        image: registry1.dso.mil/ironbank/redhat/ubi/ubi8-minimal:8.4
        imagePullPolicy: IfNotPresent
        command: ["bash"]
        args: ["-c", "sleep 3600"]
EOF

kubectl apply -n mynamespace -f /tmp/full_deploy.yaml
kubectl exec -i -t $(kubectl  get po -n mynamespace -o name) -n mynamespace -- cat /vault/secrets/testsecret
kubectl logs -n vault -l app.kubernetes.io/name=vault-agent-injector