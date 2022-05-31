

kubectl delete -n gitlab secret github
cat<<EOF >  ./provider.yaml
name: github
label: github
app_id: 'ace7f939b8f8bd8248af'
app_secret: '3d257c8caa3e496ae433705681d1c2161e1baaac'
args:
  scope: "user,read:org"
EOF

kubectl create secret generic -n gitlab github --from-file=provider=provider.yaml
