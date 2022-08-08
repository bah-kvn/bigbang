#!/usr/bin/env bash
set -e

kubectl ctx -h &> /dev/null || (echo "install scripts/krew-ctx.sh" && exit)

kubectl create namespace bigbang
kubectl create namespace flux-system

# see notes/sops-kms.config
# gpg --export-secret-key --armor "$fp" \
#   | kubectl create secret generic sops-gpg \
#     --namespace bigbang \
#     --from-file=bigbangkey.asc=/dev/stdin

kubectl create secret docker-registry private-registry \
  --namespace flux-system \
  --docker-server=registry1.dso.mil \
  --docker-username="$REGISTRY1_USERNAME" \
  --docker-password="$REGISTRY1_PASSWORD"

kubectl create secret generic private-git \
  --namespace bigbang \
  --from-literal="username='$GHCSN_USERNAME'" \
  --from-literal="password='$GHCSN_PASSWORD'"

kustomize build "https://repo1.dso.mil/platform-one/big-bang/bigbang.git//base/flux?ref=1.38.0" \
  | kubectl apply -f -

kubectl get deploy -o name -n flux-system | xargs -n1 -t kubectl rollout status -n flux-system

kubectl apply -f "$(kubectl ctx -c)/bigbang.yaml"

watch kubectl get gitrepositories,kustomizations,hr,po -A

kubectl get virtualservice -A

kubectl get service/public-ingressgateway -o yaml | yq '.status.loadBalancer.ingress[].hostname'
