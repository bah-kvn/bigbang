#!/bin/sh
#shellcheck disable=all

echo " Kiali token: >$(kubectl get secret -n kiali -o go-template='{{range $secret := .items}}{{with $secret.metadata.annotations}}{{with (index . "kubernetes.io/service-account.name")}}{{if eq . "kiali-service-account"}}{{$secret.data.token | base64decode}}{{end}}{{end}}{{end}}{{end}}')<"
echo
echo 'gitlab'
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o yaml | yq '.data.password' | base64 -d

# Packages With Built in Authentication
# The applications in the table below provide both SSO and built in auth. The table gives default credentials and ways to access and/or override those.
#
#
#
# Package (Application)
# Default Username
# Default Password
# Additional Notes
#
#
#
#
# Kiali
# N/A
# (randomly generated)
# Use kubectl get secret -n kiali -o go-template='{{range $secret := .items}}{{with $secret.metadata.annotations}}{{with (index . "kubernetes.io/service-account.name")}}{{if eq . "kiali-service-account"}}{{$secret.data.token | base64decode}}{{end}}{{end}}{{end}}{{end}}' to get the token
#
#
# Logging (Kibana)
# elastic
# (randomly generated)
# Use kubectl get secrets -n logging logging-ek-es-elastic-user -o go-template='{{.data.elastic | base64decode}}' to get the password
#
#
# Monitoring (Grafana)
# admin
# prom-operator
# Default password can be overridden with Helm values monitoring.values.grafana.adminPassword
#
#
#
# Twistlock
# N/A
# N/A
# Prompted to setup an admin account when you first hit the virtual service, no default user
#
#
# ArgoCD
# admin
# (randomly generated)
# Use kubectl -n argocd get secret argocd-initial-admin-secret -o go-template='{{.data.password | base64decode}}' to get the password. Note: If the argocd-initial-admin-secret does not exist, you will need to reset the admin password.
#
#
# Minio
# minio
# minio123
# Access and secret key can be overridden with Helm values addons.minio.accesskey and addons.minio.secretkey respectively
#
#
# Gitlab
# root
# (randomly generated)
# Use kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o go-template='{{.data.password | base64decode}}' to get the password
#
#
# Nexus
# admin
# (randomly generated)
# Use kubectl get secret -n nexus-repository-manager nexus-repository-manager-secret -o go-template='{{index .data "admin.password" | base64decode}}' to get the password
#
#
# Sonarqube
# admin
# admin
# Default password can be overridden with Helm values addons.sonarqube.values.account.adminPassword
#
#
#
# Anchore
# admin
# (randomly generated)
# Use kubectl get secrets -n anchore anchore-anchore-engine-admin-pass -o go-template='{{.data.ANCHORE_ADMIN_PASSWORD | base64decode}}' to get the password, or override with Helm values addons.anchore.values.anchoreGlobal.defaultAdminPassword
#
#
#
# Mattermost
# N/A
# N/A
# Prompted to setup an account when you first hit the virtual service - this user becomes admin, no default user
#
#
# Keycloak
# admin
# password
# Default username and password can be overridden with Helm values addons.keycloak.values.secrets.credentials.stringData.adminuser and addons.keycloak.values.secrets.credentials.stringData.password respectively
#
#
# KIALI_PASSWORD=$(kubectl get secret -n kiali -o go-template='{{range $secret := .items}}{{with $secret.metadata.annotations}}{{with (index . "kubernetes.io/service-account.name")}}{{if eq . "kiali-service-account"}}{{$secret.data.token | base64decode}}{{end}}{{end}}{{end}}{{end}}')
# echo "KIALI=$KIALI_PASSWORD"
