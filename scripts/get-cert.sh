
#7296
 docker run -it --rm --name certbot \
      -v "/etc/letsencrypt:/etc/letsencrypt" \
      -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
      -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
      -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
      -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
      certbot/dns-route53 certonly \
                            --dns-route53 \
                            --dns-route53-propagation-seconds 30 \
                            --non-interactive \
                            --agree-tos \
                            --email hansen_kevin@bah.com \
                              -d "*.dev.bahsoftwarefactory.com" \
                              --work-dir /tmp/certbot \
                              --config-dir /tmp/certbot

