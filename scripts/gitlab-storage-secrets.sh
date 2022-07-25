


#aws resourcegroupstaggingapi get-resources --tag-filters Key="kubernetes.io/cluster/c-m-n6rc24wl",Values="owned" 
kubectl delete secret  -n gitlab gitlab-registry-storage
kubectl delete secret  -n gitlab gitlab-rails-storage
kubectl delete secret  -n gitlab gitlab-storage-config

tee /tmp/gitlab-rails-storage.yaml <<EOF
provider: AWS
region: us-east-1
EOF

tee /tmp/storage.config <<EOF
[default]
bucket_location = us-east-1
multipart_chunk_size_mb = 128
EOF

tee /tmp/registry-storage.yaml <<EOF
s3:
  bucket: gitlab-registry-storage
  region: us-east-1
  v4auth: true
EOF

kubectl create secret generic -n gitlab gitlab-registry-storage --from-file=config=/tmp/registry-storage.yaml
kubectl create secret generic -n gitlab gitlab-rails-storage --from-file=connection=/tmp/gitlab-rails-storage.yaml
kubectl create secret generic -n gitlab gitlab-storage-config --from-file=config=/tmp/storage.config
