#!/bin/bash

#get nodes, ingress, certs, and helm releases
clusters=$( find .. -name cluster.yaml | sed "s/cluster.yaml/kubeconfig/g" )
for c in $clusters;
do
  export cluster=$(echo $c | cut -d '/' -f4)" 
  echo "Cluster=$cluster
  kubectl --kubeconfig=$c get svc public-ingressgateway -n istio-system
  kubectl --kubeconfig=$c get nodes,hr,certs -A 
  kubectl get --all-namespaces -oyaml issuer,clusterissuer,cert | tee $HOME/certificates/$cluster-cert-backup.yaml
  secrets=$(kubectl get secrets -n istio-system | grep '\-cert' | cut -d ' ' -f1)

  for s in $secrets; do
    kubectl -n istio-system get secret $s -o yaml | kubectl neat | tee $HOME/certificates/$cluster-$s.secret
  done

  echo -e "\n\n"
done


files=$(find ../ -name kubeconfig)
for f in $files; do
  cp $f /tmp/$(basename $(dirname $f)).kubeconfig
done
