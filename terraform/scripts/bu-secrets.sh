#!/bin/bash
#
mkdir $HOME/certificates
secrets=$(kubectl get secrets -n istio-system | grep '\-cert' | cut -d ' ' -f1)

for s in $secrets; do
  kubectl -n istio-system get secret $s -o yaml | kubectl neat | tee $HOME/certificates/$s.secret
done
