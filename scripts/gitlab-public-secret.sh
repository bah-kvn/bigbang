

kubectl delete -n gitlab secret github
cat<<EOF >  ./provider.yaml
name: github
label: github
app_id: '724b6aa134a8df16502c'
app_secret: '6a2483fa78ad13cf9ea6781beb48876c0d5b6219'
args:
  scope: "user,read:org"
EOF

kubectl create secret generic -n gitlab github --from-file=provider=provider.yaml
