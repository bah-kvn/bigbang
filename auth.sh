#!/bin/bash
#https://learn.hashicorp.com/tutorials/vault/agent-kubernetes
#rm -rf /tmp/learn-vault-agent

#git clone https://github.com/hashicorp/learn-vault-agent.git /tmp/learn-vault-agent
#echo; echo; echo https://learn.hashicorp.com/tutorials/vault/agent-kubernetes#create-a-service-account
#kubectl create serviceaccount vault-auth
#kubectl apply --filename /tmp/learn-vault-agent/vault-agent-k8s-demo/vault-auth-service-account.yaml

echo; echo; echo https://learn.hashicorp.com/tutorials/vault/agent-kubernetes#configure-kubernetes-auth-method
vault policy write myapp-kv-ro - <<EOF
path "secret/data/myapp/*" {
    capabilities = ["read", "list"]
}
EOF
vault kv delete secret/myapp/config
vault kv put secret/myapp/config username='appuser' password='suP3rsec(et!' ttl='30s'
export VAULT_SA_NAME=$(kubectl get sa vault-auth --output jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME --output 'go-template={{ .data.token }}' | base64 --decode)
export SA_CA_CRT=$(kubectl config view --raw --minify --flatten --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
export K8S_HOST=$(kubectl config view --raw --minify --flatten --output 'jsonpath={.clusters[].cluster.server}')
vault auth enable kubernetes
vault write auth/kubernetes/config token_reviewer_jwt="$SA_JWT_TOKEN" kubernetes_host="$K8S_HOST" kubernetes_ca_cert="$SA_CA_CRT" issuer="https://kubernetes.default.svc.cluster.local"
vault write auth/kubernetes/role/example bound_service_account_names=vault-auth bound_service_account_namespaces=default policies=myapp-kv-ro ttl=24h

#echo; echo; echo https://learn.hashicorp.com/tutorials/vault/agent-kubernetes#optional-verify-the-kubernetes-auth-method-configuration
tee <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: devwebapp
  labels:
    app: devwebapp
spec:
  serviceAccountName: vault-auth
  containers:
    - name: devwebapp
      image: burtlo/devwebapp-ruby:k8s
      env:
        - name: VAULT_ADDR
          value: "https://vault.stg.bahsoftwarefactory.com"
EOF

