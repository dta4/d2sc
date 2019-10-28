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

DSC_AUTOFLUSH=${DSC_AUTOFLUSH:-false}

DSC_ROOT_PASS=${DSC_ROOT_PASS:-root}
DSC_ROOT_PASS_CLEAR=${DSC_ROOT_PASS}
DSC_ROOT_PASS=`slappasswd -s ${DSC_ROOT_PASS} -n`
DSC_ADMIN_PASS=${DSC_ADMIN_PASS:-admin}
DSC_ADMIN_PASS=`slappasswd -s ${DSC_ADMIN_PASS} -n`
DSC_READ_PASS=${DSC_READ_PASS:-read}
DSC_READ_PASS=`slappasswd -s ${DSC_READ_PASS} -n`
DSC_SYNC_PASS=${DSC_SYNC_PASS:-sync}
DSC_SYNC_PASS_CLEAR=${DSC_SYNC_PASS}
DSC_SYNC_PASS=`slappasswd -s ${DSC_SYNC_PASS} -n`
DSC_RAND_PASS=`slappasswd -g -n`
DSC_RAND_PASS=`slappasswd -s ${DSC_RAND_PASS} -n`

DSC_NEXUS=${DSC_NEXUS:-yes}
DSC_SERVER_ID=${DSC_SERVER_ID:-1}
DSC_DB_SUFFIX=${DSC_DB_SUFFIX:-o=example}
DSC_SYNC_DN=${DSC_SYNC_DN:-cn=sync,ou=admins,${DSC_DB_SUFFIX}}
DSC_MASTERS=${DSC_MASTERS:-ldap://localhost}
DSC_MASTERS=(${DSC_MASTERS})
DSC_config_MASTERS=()
DSC_db_MASTERS=()
DSC_SERVER_IDS=()
for m in "${DSC_MASTERS[@]}"; do
  DSC_SERVER_IDS+=("$((++k)) ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2F$k")
  DSC_config_MASTERS+=("rid=$((++i)) provider=$m")
  DSC_db_MASTERS+=("rid=$((++i)) provider=$m")
done
if [[ -n ${DSC_SLAVE} ]]; then
  DSC_SERVER_ID=
fi

. /mo

if [[ "${DSC_NEXUS}" != "yes" ]]; then
  echo -n "Waiting for nexus... "
  /wait-for-it.sh -q -t 30 -s ${DSC_NEXUS} -- echo "done"
fi

# Avoid destroying bootstrapping by simple start/stop
if [[ ! -e /.bootstrapped ]]; then
  ### list none idempotent configuration code blocks, here...

  echo "Generating certificates..."
  openssl req -x509 -newkey rsa:2048 -days 365 -subj '/CN=localhost' -nodes \
              -keyout /var/lib/openldap/key.pem \
              -out /var/lib/openldap/cert.pem >/dev/null 2>&1
  openssl dhparam 512 >/var/lib/openldap/dh.pem 2>&1

  # TODO: protect db #2 against flushing
  #       modify passwords instead...
  if [[ $DSC_AUTOFLUSH == "true" ]]; then
    rm -rf /var/lib/openldap/slapd.d/*
    rm -rf /var/lib/openldap/db/*
  fi
  if [[ -z `ls -1A /var/lib/openldap/slapd.d` && \
        -z `ls -1A /var/lib/openldap/db` ]]; then ### REVIEW
    if [[ "${DSC_NEXUS}" == "yes" ]]; then
      echo "Bootstraping... nexus"
      cat /etc/openldap/slapd.nexus.ldif | mo -e | \
        slapadd -vn0 -S ${DSC_SERVER_ID} -F /var/lib/openldap/slapd.d/ >/dev/null 2>&1
      cat /etc/openldap/slapd.db.ldif | mo -e | \
        slapadd -vn2 -S ${DSC_SERVER_ID} -F /var/lib/openldap/slapd.d/ >/dev/null 2>&1
    elif [[ -n ${DSC_SLAVE} ]]; then
      echo "Bootstraping... slave"
      cat /etc/openldap/slapd.slave.ldif | mo -e | \
        slapadd -vn0 -F /var/lib/openldap/slapd.d/ >/dev/null 2>&1
      echo ""
    else
      echo "Bootstraping... master"
      cat /etc/openldap/slapd.master.ldif | mo -e | \
        slapadd -vn0 -S ${DSC_SERVER_ID} -F /var/lib/openldap/slapd.d/ >/dev/null 2>&1
    fi
    chown -R ldap:ldap /var/lib/openldap/*
  else
    : # nop
  fi

  touch /.bootstrapped
fi

# TODO: ldapmodify passwords
#       drawback: needs a running slapd
# REVIEW: generate TLS certs

if [[ `basename ${1}` == "slapd" ]]; then # prod
  prog=${1}
  shift
  if [[ -z ${DSC_SLAVE}  ]]; then
    exec $prog -h "ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2F${DSC_SERVER_ID} ldap:/// ldaps:///" "$@" #</dev/null #>/dev/null 2>&1
  else
    exec $prog -h "ldap:/// ldaps:///" "$@" #</dev/null #>/dev/null 2>&1
  fi
else # dev
  : # nop
  /usr/sbin/slapd -h "ldapi:/// ldap:/// ldaps:///" -u ldap -F /var/lib/openldap/slapd.d || true
fi

# fallthrough...
exec "$@"
