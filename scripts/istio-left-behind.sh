resources=$(kubectl get mutatingwebhookconfigurations,validatingwebhookconfigurations,wasmplugins,istiooperators,destinationrules,envoyfilters,gateways,proxyconfigs,serviceentries,sidecars,virtualservices,workloadentries,workloadgroups,authorizationpolicies,peerauthentications,requestauthentications,telemetries -A | cut -d' ' -f1 )

echo "$resources"
