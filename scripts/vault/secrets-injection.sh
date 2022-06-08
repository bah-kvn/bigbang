#!/bin/bash
kubectl delete deploy mshell -n mynamespace 
kubectl delete sa internal-app -n mynamespace
kubectl delete ns mynamespace

token=$(echo "export VAULT_TOKEN=\"$VAULT_TOKEN\"")
echo "token=$token"
cmd='''
echo "vault auth enable kubernetes"
vault auth enable kubernetes

echo "vault write auth/kubernetes/config"
vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  issuer="https://kubernetes.default.svc.cluster.local"

echo "vault secrets" 
vault secrets disable kv-v2/
vault secrets enable -path=bigbang kv-v2

vault kv delete bigbang/gitlab/testsecret
vault kv put bigbang/gitlab/testsecret username="bbuser1" password="password1"
vault kv get bigbang/gitlab/testsecret

echo "create a policy for a secret"
vault policy write internal-app - <<EOF
path "bigbang/data/gitlab/testsecret" {
  capabilities = ["read"]
}
EOF

echo "bind the policy to a k8s service account and namespace"
vault write auth/kubernetes/role/internal-app \
    bound_service_account_names=internal-app \
    bound_service_account_namespaces=mynamespace \
    policies=internal-app \
    ttl=24h

'''
export cmd="$token; $cmd"
#echo "cmd=$cmd"
kubectl -n vault exec vault-vault-0 -i -t -- bash -c " $cmd "

echo "create ns, sa, pod " 
kubectl create ns mynamespace
kubectl -n mynamespace create sa internal-app
kubectl apply -n mynamespace -f ./pod-auth-verify.yaml
kubectl wait --for=condition=ready pod -l app=mshell -n mynamespace
kubectl exec -i -t $(kubectl get po -n mynamespace -o name ) -n mynamespace -c mshell -- cat /vault/secrets/testsecret

