----  hr exhausted --
bigbang     bigbang          False   upgrade retries exhausted          27h

flux suspend hr bigbang -n bigbang
► suspending helmrelease bigbang in bigbang namespace
✔ helmrelease suspended

===> remove terminating namespace  RKE2 version!

flux resume hr bigbang -n bigbang
► resuming helmrelease bigbang in bigbang namespace
✔ helmrelease resumed
◎ waiting for HelmRelease reconciliation
✔ HelmRelease reconciliation completed
✔ applied revision 1.31.0

------ RKE2 version ---
export NS='argocd'; export YOURFQDN='rancher.bahsoftwarefactory.com'; export YOURCLUSTER='c-m-prb4vjth';

kubectl get ns ${NS} -o json | jq '.spec.finalizers=[]' | \
curl -X PUT https://${YOURFQDN}/k8s/clusters/${YOURCLUSTER}/api/v1/namespaces/${NS}/finalize \
-H "Accept: application/json" \
-H "Authorization: Bearer token-blah-blah-YOURTOKEN----qf" \
-H "Content-Type: application/json" --data @-
