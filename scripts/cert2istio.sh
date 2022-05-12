

export CERTS="/Users/keithhansen/certs/dev.bahsoftwarefactory.com"

export ISTIO_KEY=$(cat $CERTS/privkey.pem | sed "s/^/              /g")
export ISTIO_CERT=$(cat $CERTS/cert.pem | sed "s/^/              /g")
export ISTIO_CHAIN=$(cat $CERTS/fullchain.pem | sed "s/^/              /g")
(
echo """
apiVersion: v1
kind: Secret
metadata:
  name: common-bb
stringData:
  values.yaml: |-
    istio:
      gateways:
        public:
          tls:
            key: |-
${ISTIO_KEY}
            cert: |-
${ISTIO_CERT}
${ISTIO_CHAIN}"""
) | egrep -v "^  *subject=|^  *issuer=|^  *$" |   tee $CERTS/istio-$CLUSTER.yaml

