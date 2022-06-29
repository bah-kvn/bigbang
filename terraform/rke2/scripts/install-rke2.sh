#!/usr/bin/env bash
set -e
mkdir -p /etc/rancher/rke2

#cloud-config
#install requirement
# snap install helm --classic

# install the following packages required for Longhorn
apt-get update
apt-get install -y curl grep gawk util-linux open-iscsi nfs-common

## Preparing the config file
echo 'cloud-provider-name: aws' > /etc/rancher/rke2/config.yaml
echo 'write-kubeconfig-mode: "0644"' >> /etc/rancher/rke2/config.yaml
echo 'tls-san:' >> /etc/rancher/rke2/config.yaml
echo '  - ${kube_url}' >> /etc/rancher/rke2/config.yaml
echo 'disable: rke2-ingress-nginx' >> /etc/rancher/rke2/config.yaml

# install rke2
echo "Installing rke2..."
curl -sfL https://get.rke2.io | \
	INSTALL_RKE2_VERSION=${rke2_version} \
	sh -	
echo "Installing rke2... Complete"

## BB Host level configuration
sudo modprobe xt_REDIRECT
sudo modprobe xt_owner
sudo modprobe xt_statistic
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192

echo "enabling and starting rke2-server.service..."
systemctl enable rke2-server.service
systemctl start rke2-server.service
echo "enabling and starting rke2-server.service...Complete"

echo "PATH=$PATH:/var/lib/rancher/rke2/bin" > /etc/environment
echo "KUBECONFIG=/etc/rancher/rke2/rke2.yaml" >> /etc/environment
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export PATH=$PATH:/var/lib/rancher/rke2/bin

echo "Waiting for kubernetes and deployments to become ready..."
# wait for all the kube system deployments to be ready
sleep 30 # Seem to need to wait a few seconds before we can run kubectl

set +e
COUNTER=0
ERROR_MSG="The connection to the server 127.0.0.1:6443 was refused - did you specify the right host or port?"
RESP=$(kubectl get nodes 2>&1)
while [ "$RESP" = "$ERROR_MSG" ] && [ "$COUNTER" -lt 240 ]; do
  echo "Waiting for kubectl connection..."
  sleep 1
  COUNTER=$(($COUNTER + 1))
  RESP=$(kubectl get nodes 2>&1)
done

COUNTER=0
ERROR_MSG="Error from server (NotFound): deployments.apps \"rke2-metrics-server\" not found"
RESP=$(kubectl -n kube-system get deployment rke2-metrics-server 2>&1)
echo "Test for rke2-metrics-server: " $RESP
while [ "$RESP" = "$ERROR_MSG" ] && [ "$COUNTER" -lt 240 ]; do  
  echo "Waiting for rke2-metrics-server deployment to be registered"
  sleep 1
  COUNTER=$(($COUNTER + 1))
  RESP=$(kubectl -n kube-system get deployment rke2-metrics-server 2>&1)
done

CHECK=$(kubectl wait --namespace kube-system \
  --for=condition=available \
  --timeout=300s \
  deployment/rke2-metrics-server)

echo $CHECK

COUNTER=0
ERROR_MSG="Error from server (NotFound): deployments.apps \"rke2-coredns-rke2-coredns\" not found"
RESP=$(kubectl -n kube-system get deployment rke2-coredns-rke2-coredns 2>&1)
echo "Test for rke2-coredns-rke2-coredns: " $RESP
while [ "$RESP" = "$ERROR_MSG" ] && [ "$COUNTER" -lt 240 ]; do  
  echo "Waiting for rke2-coredns-rke2-coredns deployment to be registered"
  sleep 1
  COUNTER=$(($COUNTER + 1))
  RESP=$(kubectl -n kube-system get deployment rke2-coredns-rke2-coredns 2>&1)
done

CHECK=$(kubectl wait --namespace kube-system \
  --for=condition=available \
  --timeout=300s \
  deployment/rke2-coredns-rke2-coredns)

echo $CHECK

echo "Waiting for kubernetes and deployments to become ready...Complete"
set -e

