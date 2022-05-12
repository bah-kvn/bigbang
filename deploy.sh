#!/usr/bin/env bash
#set -e

# Variables
export fp="CD3D3528CE1671DC7236312999A4AC740D06AD5C"

# Config
kubectl create namespace bigbang
kubectl create namespace flux-system
gpg --export-secret-key --armor ${fp} | kubectl -n bigbang create secret generic sops-gpg --from-file=bigbangkey.asc=/dev/stdin
kubectl -n flux-system \
  create secret docker-registry private-registry \
  --docker-server=registry1.dso.mil \
  --docker-username=${REGISTRY1_USERNAME} \
  --docker-password=${REGISTRY1_PASSWORD} 
kubectl create secret generic private-git --from-literal=username=$GHCSN_USERNAME --from-literal=password=$GHCSN_PASSWORD --namespace bigbang

kustomize build "https://repo1.dso.mil/platform-one/big-bang/bigbang.git//base/flux?ref=1.31.0" | kubectl apply -f -
kubectl get -n flux-system deployment.apps/helm-controller
kubectl get -n flux-system deployment.apps/kustomize-controller
kubectl get -n flux-system deployment.apps/notification-controller
kubectl get -n flux-system deployment.apps/source-controller

kubectl apply -f dev/bigbang.yaml

watch kubectl get gitrepositories,kustomizations,hr,po -A

kubectl get virtualservice -A

kubectl get service/public-ingressgateway -o yaml | yq '.status.loadBalancer.ingress[].hostname'
