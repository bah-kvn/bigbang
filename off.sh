

yq e '.istiooperator.enabled = false' -i dev/configmap.yaml
yq e '.istio.enabled = false' -i dev/configmap.yaml
yq e '.kiali.enabled = false' -i dev/configmap.yaml
yq e '.jaeger.enabled = false' -i dev/configmap.yaml
yq e '.addons.vault.enabled = false' -i dev/configmap.yaml

push.sh "all off" 

