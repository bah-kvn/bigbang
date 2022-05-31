

kubectl get secret/gitlab-rails-secret -n gitlab -o yaml > gitlab-rails-custom-secret.yaml

echo " may need to update regex in .sops.yaml"
echo "- encrypted_regex: '^(data|stringData|secrets.yml)$'"
echo 'export SOPS_KMS_ARN="arn:aws:kms:rest_of_arn"'
sops -e gitlab-rails-custom-secret.yaml

