FROM nginx:stable-alpine
MAINTAINER Andreas Schulze <asl@iaean.net>

LABEL org.opencontainers.image.authors="Andreas Schulze <asl@iaean.net>" \
                            maintainer="Andreas Schulze <asl@iaean.net>" \
        org.opencontainers.image.title="NGINX DSC ingress controller" \
  org.opencontainers.image.description="The all-in-one load balancer, web server, .." \
       org.opencontainers.image.source="https://github.com/iaean/.." \
                 org.label-schema.name="NGINX DSC ingress controller" \
          org.label-schema.description="The all-in-one load balancer, web server, .." \
              org.label-schema.vcs-url="https://github.com/iaean/.."

RUN apk --update upgrade && \
    apk add --no-cache \
        ca-certificates coreutils curl less bash busybox-extras \
        sudo wget dcron openssl bind-tools

ENV MO_VERSION="2.1.0"
RUN curl -fsSL https://github.com/tests-always-included/mo/archive/$MO_VERSION.tar.gz | \
      tar -xO -zf- mo-$MO_VERSION/mo > /mo && \
    chmod a+x /mo

COPY nginx.conf /etc/nginx/nginx.mustache
COPY wait-for-it.sh /wait-for-it.sh
COPY nginx.renew.sh /etc/periodic/daily/nginx-renew
COPY docker-entrypoint.sh /entrypoint.sh

EXPOSE 636
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
