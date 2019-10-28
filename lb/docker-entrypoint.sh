#!/bin/bash
set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
#  (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#   "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
function file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

# envs=(
#   XYZ_API_TOKEN
# )
# haveConfig=
# for e in "${envs[@]}"; do
#   file_env "$e"
#   if [ -z "$haveConfig" ] && [ -n "${!e}" ]; then
#     haveConfig=1
#   fi
# done

echo Running: "$@"

# CERTBOT=certbot:80
CERTBOT_CRT_URL=${CERTBOT_CRT_URL:-http://certbot/localhost/cert.pem}
CERTBOT_KEY_URL=${CERTBOT_KEY_URL:-http://certbot/localhost/privkey.pem}
CERTBOT_USER=${CERTBOT_USER:-admin}
CERTBOT_PASS=${CERTBOT_PASS:-foobar}
DSC_MASTERS=(${DSC_MASTERS})
DSC_SLAVES=(${DSC_SLAVES})

. /mo

# Avoid destroying bootstrapping by simple start/stop
if [[ ! -e /.bootstrapped ]]; then
  ### list none idempotent code blocks, here...

  if [[ -n ${CERTBOT} ]]; then
    /wait-for-it.sh -t 30 -s ${CERTBOT} -- \
      wget --user=${CERTBOT_USER} --password=${CERTBOT_PASS} \
           --no-check-certificate -q -O- \
        ${CERTBOT_CRT_URL} > /etc/nginx/fullchain.pem

    /wait-for-it.sh -t 30 -s ${CERTBOT} -- \
      wget --user=${CERTBOT_USER} --password=${CERTBOT_PASS} \
           --no-check-certificate -q -O- \
        ${CERTBOT_KEY_URL} > /etc/nginx/privkey.pem
  else
    echo "Generating certificates..."
    openssl req -x509 -newkey rsa:2048 -days 365 -subj '/CN=localhost' -nodes \
                -keyout /etc/nginx/privkey.pem \
                -out /etc/nginx/fullchain.pem >/dev/null 2>&1
  fi

  touch /.bootstrapped
fi

cat /etc/nginx/nginx.mustache | mo -e >/etc/nginx/nginx.conf

###
### Start cron...
###

if [[ -n ${CERTBOT} ]]; then
  crond -L/dev/null
fi

###
### Start nginx...
###

if [[ `basename ${1}` == "nginx" ]]; then # prod
  exec "$@" </dev/null #>/dev/null 2>&1
else # dev
  nginx || true
fi

# fallthrough...
exec "$@"
