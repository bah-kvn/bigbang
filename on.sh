

yq e '.istiooperator.enabled = true' -i dev/configmap.yaml
yq e '.istio.enabled = true' -i dev/configmap.yaml
yq e '.kiali.enabled = true' -i dev/configmap.yaml
yq e '.jaeger.enabled = true' -i dev/configmap.yaml
yq e '.addons.vault.enabled = true' -i dev/configmap.yaml

push.sh "all on" 

