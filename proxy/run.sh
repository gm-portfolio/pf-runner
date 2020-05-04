#!/bin/bash

# use dev certificates is there are not any
if [ ! -d "/etc/letsencrypt/certificates" ]; then
  echo "Adding dev certificates"
  cp -r /etc/nginx/proxy/dev/letsencrypt /etc/
fi

echo "Running nginx"
envsubst "$${DOMAIN}" < /etc/nginx/proxy/nginx.conf > /etc/nginx/nginx.conf &&
nginx -g "daemon off;" &


# get certificates from LetsEncript and replace dev
if [ ${PRODUCTION} = 'true' ]; then

  if [ ! -d "/etc/letsencrypt/live/${DOMAIN}/" ]; then
    echo "Getting certificates from production"
    mkdir -p /var/www/letsencrypt
    certbot certonly --webroot --webroot-path /var/www/letsencrypt \
    --email ${EMAIL} --agree-tos --no-eff-email -d ${DOMAIN}  -d www.${DOMAIN} \
    --deploy-hook "cp -rL /etc/letsencrypt/live/${DOMAIN}/. /etc/letsencrypt/certificates" \
    --force-renewal
  fi &&

  nginx -s reload

  # reniew certificates every 12h
  while :; do
    sleep 12h & wait ${!}
    echo "Renewing certificates"
    certbot renew &&
    nginx -s reload
  done
fi &

wait
