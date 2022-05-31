
echo 'export SOPS_KMS_ARN="arn:aws:kms:rest_of_arn"'
source $SCRIPTS/env/sops-kms.sh
kubectl get secret/gitlab-rails-secret -n gitlab -o yaml > gitlab-rails-custom-secret.yaml

echo " may need to update regex in .sops.yaml"
echo "- encrypted_regex: '^(data|stringData|secrets.yml)$'"

sops -e gitlab-backup-rails-custom-secret.yaml

