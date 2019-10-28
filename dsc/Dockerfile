FROM alpine:latest  

LABEL org.opencontainers.image.authors="Andreas Schulze <asl@iaean.net>" \
                            maintainer="Andreas Schulze <asl@iaean.net>" \
        org.opencontainers.image.title="OpenLDAP DSC Slave node" \
  org.opencontainers.image.description="OpenLDAP is the open source reference implementation of the LDAP Protocol." \
       org.opencontainers.image.source="https://github.com/iaean/.." \
                 org.label-schema.name="OpenLDAP DSC Slave node" \
          org.label-schema.description="OpenLDAP is the open source reference implementation of the LDAP Protocol." \
              org.label-schema.vcs-url="https://github.com/iaean/.."

RUN apk --no-cache add tini \
        bash less man busybox-extras joe \
        curl wget ca-certificates coreutils openssl \
        openldap-backend-all openldap-overlay-all openldap \
        openldap-clients openldap-doc && \
    rm -rf /var/cache/apk/* && \
    rm -rf /etc/openldap/slapd.* /var/lib/openldap/openldap-data && \
    mkdir /var/lib/openldap/slapd.d/ \
          /var/lib/openldap/run/ \
          /var/lib/openldap/db/ && \
    chown ldap:ldap /var/lib/openldap/slapd.d \
                    /var/lib/openldap/run \
                    /var/lib/openldap/db

ENV MO_VERSION="2.1.0"
RUN curl -fsSL https://github.com/tests-always-included/mo/archive/$MO_VERSION.tar.gz | \
      tar -xO -zf- mo-$MO_VERSION/mo > /mo && \
    chmod a+x /mo

WORKDIR /root/
VOLUME /var/lib/openldap

COPY wait-for-it.sh /wait-for-it.sh
COPY ldap.conf /etc/openldap/
COPY slapd.*.ldif /etc/openldap/
COPY schema/* /etc/openldap/schema/
COPY docker-entrypoint.sh /entrypoint.sh

EXPOSE 389/tcp 636/tcp

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
# Note: Do not spec slapd -h
#       Its injected via entrypoint
CMD ["/usr/sbin/slapd", "-u", "ldap", "-F", "/var/lib/openldap/slapd.d", "-d", "none"]
