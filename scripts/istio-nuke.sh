#!/bin/sh

istioctl x uninstall --purge --verbose -y
istioctl experimental precheck --verbose

kubectl get jobs.batch -A | grep istio
kubectl get hpa,iop,dr,gw,se,vs,we,wg,pa,ra,telemetry -A
kubectl get mutatingwebhookconfigurations,validatingwebhookconfigurations,envoyfilters,sidecars,authorizationpolicies -A
kubectl get ns
