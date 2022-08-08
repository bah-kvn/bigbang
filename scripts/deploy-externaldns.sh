#!/bin/sh

# Instructions: Set the environment variables below - save, then run this script.
# Verify the Deployment is running
#

export CLUSTER="sls"
export DOMAIN="bahsoftwarefactory.com"
ZONE=$(\
  aws route53 list-hosted-zones-by-name --dns-name "$CLUSTER.$DOMAIN" \
  | jq '.HostedZones[0].Id' \
  | cut -d'/' -f3\
)
export ZONE
export DIR=/tmp
export FILE=$DIR/external-dns.yaml
export EXTERNALDNS_NS="kube-system"

#
# End of environment variables
#

tee "$FILE" <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
  # If you're using Amazon EKS with IAM Roles for Service Accounts, specify the following annotation.
  # Otherwise, you may safely omit it.
  annotations:
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
rules:
  - apiGroups: ['']
    resources: ['endpoints', 'pods', 'services']
    verbs: ['get', 'watch', 'list']
  - apiGroups: ['extensions']
    resources: ['ingresses']
    verbs: ['get', 'watch', 'list']
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get","watch","list"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
- kind: ServiceAccount
  name: external-dns
  namespace: default
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: k8s.gcr.io/external-dns/external-dns:v0.7.6
        args:
        - --source=service
        - --domain-filter=$DOMAIN
        - --provider=aws
        - --aws-zone-type=public
        - --registry=txt
        - --txt-owner-id=$ZONE
        - --log-level=debug
      securityContext:
        fsGroup: 65534 # For ExternalDNS to be able to read Kubernetes and AWS token files
EOF

echo
echo "Cluster = $CLUSTER"
echo " Domain = $DOMAIN"
echo "   Zone = $ZONE"
echo

envsubst < "$FILE" | kubectl create --namespace "${EXTERNALDNS_NS:-'default'}" -f -

echo "May take up to 3 minutes for DNS to be propagated - can be verified via the console"
