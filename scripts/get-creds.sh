KIALI_PASSWORD=$(kubectl get secret -n kiali -o go-template='{{range $secret := .items}}{{with $secret.metadata.annotations}}{{with (index . "kubernetes.io/service-account.name")}}{{if eq . "kiali-service-account"}}{{$secret.data.token | base64decode}}{{end}}{{end}}{{end}}{{end}}')
echo "KIALI=$KIALI_PASSWORD"
