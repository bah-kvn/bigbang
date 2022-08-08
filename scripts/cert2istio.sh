#!/bin/sh

export CERTS="$HOME/certs/stg.bahsoftwarefactory.com"

ISTIO_KEY=$(sed "s/^/              /g" <"$CERTS/privkey.pem")
export ISTIO_KEY

ISTIO_CERT=$(sed "s/^/              /g" <"$CERTS/cert.pem")
export ISTIO_CERT

ISTIO_CHAIN=$(sed "s/^/              /g" <"$CERTS/fullchain.pem")
export ISTIO_CHAIN

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
) | grep -E -v "^  *subject=|^  *issuer=|^  *$" | tee "$CERTS/istio-$CLUSTER.yaml"
