#!/bin/bash

SRV_HOST=${SRV_HOST:-proxy}
SRV_PORT=${SRV_PORT:-443}

# grab SSL TTL from our running service
SRV_TTL=`echo | openssl s_client -servername ${SRV_HOST} -connect ${SRV_HOST}:${SRV_PORT} 2>/dev/null |\
  openssl x509 -noout -dates 2>/dev/null | grep ^notAfter | cut -d= -f2`

# grab SSL TTL from Certbot for our service
CERTBOT_TTL=`wget --user=${CERTBOT_USER} --password=${CERTBOT_PASS} --no-check-certificate -q -O- ${CERTBOT_CRT_URL} |\
  openssl x509 -noout -dates 2>/dev/null | grep ^notAfter | cut -d= -f2`

echo -n >/tmp/nginx.renew.log

# compare...
if [ -z "$CERTBOT_TTL" -o -z "$SRV_TTL" ]; then
  echo "Error fetching certs from ${SRV_HOST}:${SRV_PORT} or ${CERTBOT_CRT_URL}" >>/tmp/nginx.renew.log

  exit 2
elif [ "$CERTBOT_TTL" != "$SRV_TTL" ]; then
  # TODO: use real integer comparison (>) instead of equal strings...
  echo "Installing renewed cert..." >>/tmp/nginx.renew.log
  echo "Certbot TTL: $CERTBOT_TTL" >>/tmp/nginx.renew.log
  echo "Service TTL: $SRV_TTL" >>/tmp/nginx.renew.log

  # install the renewed cert into our service
  # REVIEW: dangerous... in case of wget failure.
  wget --user=${CERTBOT_USER} --password=${CERTBOT_PASS} \
    --no-check-certificate -q -O- ${CERTBOT_CRT_URL} > /etc/nginx/fullchain.pem
  wget --user=${CERTBOT_USER} --password=${CERTBOT_PASS} \
    --no-check-certificate -q -O- ${CERTBOT_KEY_URL} > /etc/nginx/privkey.pem

  # restart/reload our service...
  kill -s SIGHUP 1

  exit 1
else
  echo "Nothing to do..." >>/tmp/nginx.renew.log
  echo "Certbot TTL: $CERTBOT_TTL" >>/tmp/nginx.renew.log
  echo "Service TTL: $SRV_TTL" >>/tmp/nginx.renew.log

  exit 0
fi
