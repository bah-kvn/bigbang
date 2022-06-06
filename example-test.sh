https://dzone.com/articles/using-hashicorp-vault-on-kubernetes

A Service Account for Kubernetes
In Kubernetes, a service account provides an identity for processes that run in a pod so that processes can contact the API server.

$ cat vault-auth-service-account.yml
  ---
  apiVersion: rbac.authorization.k8s.io/v1beta1
  kind: ClusterRoleBinding
  metadata:
    name: role-tokenreview-binding
    namespace: default
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: system:auth-delegator
  subjects:
  - kind: ServiceAccount
    name: vault-auth
    namespace: default

###
# Create the 'vault-auth' service account
$ kubectl apply --filename vault-auth-service-account.yml


Vault Policy
Next, we need to set a read-only policy for our secrets as we don’t want any apps to be able to write or rewrite them.



# Create a policy file, myapp-kv-ro.hcl
$ tee myapp-kv-ro.hcl <<EOF
path "secret/data/myapp/*" {
    capabilities = ["read", "list"]
}
EOF

###
# Create a policy named myapp-kv-ro
$ vault policy write myapp-kv-ro myapp-kv-ro.hcl


$ vault kv put secret/myapp/config username='appuser' \
        password='suP3rsec(et!' \
        ttl='30s'




Kubernetes Configuration
Set the environment variables to point to the running Minikube environment, enable the Kubernetes authentication method, and then validate it from a temporal pod.



# Set VAULT_SA_NAME to the service account you created earlier
$ export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
# Set SA_JWT_TOKEN value to the service account JWT used to access the TokenReview API
$ export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
# Set SA_CA_CRT to the PEM encoded CA cert used to talk to Kubernetes API
$ export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

# Set K8S_HOST to minikube IP address
$ export K8S_HOST=$(minikube ip)
# Enable the Kubernetes auth method at the default path ("auth/kubernetes")
$ vault auth enable kubernetes
# Tell Vault how to communicate with the Kubernetes (Minikube) cluster
$ vault write auth/kubernetes/config \
        token_reviewer_jwt="$SA_JWT_TOKEN" \
        kubernetes_host="https://$K8S_HOST:8443" \
        kubernetes_ca_cert="$SA_CA_CRT"
# Create a role named, 'example' to map Kubernetes Service Account to
# Vault policies and default token TTL
$ vault write auth/kubernetes/role/example \
        bound_service_account_names=vault-auth \
        bound_service_account_namespaces=default \
        policies=myapp-kv-ro \
        ttl=24h
# Run a temp pod to test that we can reach vault
$ kubectl run --generator=run-pod/v1 tmp --rm -i --tty --serviceaccount=vault-auth --image alpine:3.7
$ apk add curl jq
$ curl -k https://vault/v1/sys/health | jq
{
  "initialized": true,
  "sealed": false,
  "standby": false,
  "performance_standby": false,
  "replication_performance_mode": "disabled",
  "replication_dr_mode": "disabled",
  "server_time_utc": 1556488210,
  "version": "1.1.1",
  "cluster_name": "vault-cluster-1677ba10",
  "cluster_id": "fa706969-085b-91ac-36de-de6fcf2328c5"
}
# Then we can test the login
$ export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
$ curl --request POST \
        --data '{"jwt": "'"$KUBE_TOKEN"'", "role": "example"}' \
        https://vault:8200/v1/auth/kubernetes/login | jq
{
  ...
  "auth": {
    "client_token": "s.7cH83AFIdmXXYKsPsSbeESpp",
    "accessor": "8bmYWFW5HtwDHLAoxSiuMZRh",
    "policies": [
      "default",
      "myapp-kv-ro"
    ],
    "token_policies": [
      "default",
      "myapp-kv-ro"
    ],
    "metadata": {
      "role": "example",
      "service_account_name": "vault-auth",
      "service_account_namespace": "default",
      "service_account_secret_name": "vault-auth-token-vqqlp",
      "service_account_uid": "adaca842-f2a7-11e8-831e-080027b85b6a"
    },
    "lease_duration": 86400,
    "renewable": true,
    "entity_id": "2c4624f1-29d6-972a-fb27-729b50dd05e2",
    "token_type": "service"
  }
}

