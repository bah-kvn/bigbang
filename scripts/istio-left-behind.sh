resources=$(kubectl get mutatingwebhookconfigurations,validatingwebhookconfigurations,wasmplugins,istiooperators,destinationrules,envoyfilters,gateways,proxyconfigs,serviceentries,sidecars,virtualservices,workloadentries,workloadgroups,authorizationpolicies,peerauthentications,requestauthentications,telemetries -A | cut -d' ' -f1  | egrep -v "^NAME|^$")



terminating=$(kubectl get ns | grep Terminating | cut -d ' ' -f1)
for n in $terminating;
do
  resources="$resources $n"
done


echo "$resources"
