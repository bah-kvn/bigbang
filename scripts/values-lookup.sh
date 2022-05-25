
echo
echo "from dev/config.yaml"
(
echo "  .Values.addons.vault.ingress.cert     = $( cat dev/configmap.yaml | yq '.addons.vault.ingress.cert' )"
echo "  .Values.addons.vault.ingress.key      = $( cat dev/configmap.yaml | yq '.addons.vault.ingress.key' )"
echo "  .Values.addons.vault.ingress.gateway  = $(cat dev/configmap.yaml | yq '.addons.vault.ingress.gateway' )"
) |  tee config.yaml.results

helm get values bigbang -n bigbang | tee bigbang.values
echo
echo "from bigbang-values.yaml"
(
echo "  .Values.addons.vault.ingress.cert     = $( cat bigbang.values | yq '.addons.vault.ingress.cert' )"
echo "  .Values.addons.vault.ingress.key      = $( cat bigbang.values | yq '.addons.vault.ingress.key' )"
echo "  .Values.addons.vault.ingress.gateway  = $( cat bigbang.values | yq '.addons.vault.ingress.gateway' )"
) | tee bigbang-values.results

sdiff ./config.yaml.results ./bigbang-values.results




echo
