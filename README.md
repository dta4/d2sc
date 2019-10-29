![](https://github.com/iaean/d2sc/workflows/Dockerization%20CI/badge.svg)

## d2sc - dockerized directory service cluster

**A docker image to run an OpenLDAP cluster.**

> OpenLDAP website : [www.openldap.org](http://www.openldap.org/)

Even if there are other popular open source alternatives for LDAP directory services like [389DS][1] or [ApacheDS][2], [OpenLDAP][3] still seems to be the quite stable and well-matured reference.

This is an OpenLDAP based Docker image that can be deployed as OpenLDAP (multi) [master][4] and/or [slave][5] and a `stack.yml` that showcases a cluster deployment as described in the picture.

![figure 1](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/dta4/d2sc/master/assets/figure1.dot)

We are providing it here, because we need a flexible centralized LDAP user management backend for our project and existing solutions like the cool stuff from [Osixia][6] doesn't fit perfectly for us.

[1]: https://directory.fedoraproject.org/
[2]: https://directory.apache.org/apacheds/
[3]: https://www.openldap.org/doc/admin24/
[4]: http://www.zytrax.com/books/ldap/ch7/#ol-syncrepl-mm
[5]: http://www.zytrax.com/books/ldap/ch7/#ol-syncrepl
[6]: https://github.com/osixia/docker-openldap

### Build 'n' Run

It's available via [Dockerhub][7].

You start and stop the stack as usual:
```bash
docker-compose -f stack.yml up -d [--build]
docker-compose -f stack.yml down
```

Access the LDAP slave frontends and master backends:
```bash
# frontend
ldapsearch -LLL -H ldaps://localhost -D 'cn=Configuration Manager,cn=config' -w root -b 'cn=config'
ldapsearch -LLL -H ldaps://localhost -D 'cn=Directory Manager,o=example' -w root -b 'o=example'

# backend
ldapsearch -LLL -H ldaps://localhost:42636 -D 'cn=Configuration Manager,cn=config' -w root -b 'cn=config'
ldapsearch -LLL -H ldaps://localhost:42636 -D 'cn=Directory Manager,o=example' -w root -b 'o=example'
```

[Eclipse Photon][8] with [Apache Directory Studio][9] 2.0.0.v20180908-M14 is known as working LDAP UI workhorse.

Of course, you can build by your own as usual:
```bash
docker build --tag=dsc dsc/
```

[7]: https://hub.docker.com/r/dta4/d2sc
[8]: https://www.eclipse.org/downloads/packages/release/photon/r
[9]: https://directory.apache.org/studio/

### Configuration

Basic configuration via:

| environment | default | |
| --- | --- | --- |
| DSC_SLAVE | no | master mode is the default |
| DSC_SERVER_ID | 1 | unique server id for masters |
| DSC_DB_SUFFIX | o=example | |
| DSC_MASTERS | ldap://localhost | other masters to sync with |
| DSC_ROOT_PASS | root | `cn=Configuration Manager,cn=config`<br/>`cn=Directory Manager,{{DSC_DB_SUFFIX}}` |
| DSC_ADMIN_PASS | admin | `cn=admin,ou=admins,{{DSC_DB_SUFFIX}}` |
| DSC_READ_PASS | read | `cn=reader,ou=admins,{{DSC_DB_SUFFIX}}` |
| DSC_SYNC_PASS | sync | `cn=sync,ou=admins,{{DSC_DB_SUFFIX}}` |

Look to `docker-entrypoint.sh` for more details...  
...and to `stack.yml` for an example.

### Dependencies

We are using:
* [Alpine][10] as container OS
* Alpine [OpenLDAP][11] packages
* [Tini][12] as explicit `init` for containers instead of `--init`
* [mo][14] as [mustache][13] template engine
* [NGINX][15] as ingress TCP [loadbalancer][16] with TLS termination or bridging

[10]: https://alpinelinux.org/
[11]: https://pkgs.alpinelinux.org/package/edge/main/x86_64/openldap
[12]: https://github.com/krallin/tini
[13]: https://mustache.github.io/
[14]: https://github.com/tests-always-included/mo
[15]: https://www.nginx.com/
[16]: https://nginx.org/en/docs/stream/ngx_stream_core_module.html

### License

[Apache License Version 2.0](LICENSE)

### Todo

- [ ] add [self service][20] to the stack
- [ ] add SASL [pass-trough auth][21] to the stack
- [ ] provide a default [password policy][22]
- [ ] add [OpenID Connect provider][23] to the stack
- [ ] make TLS and sync replication more configurable
- [ ] streamline ACL
- [ ] document pre-defined DIT model
- [ ] provide Helm K8s example deployment

[20]: https://github.com/ltb-project/self-service-password
[21]: https://ltb-project.org/documentation/general/sasl_delegation
[22]: https://tobru.ch/openldap-password-policy-overlay/
[23]: https://github.com/dexidp/dex

> Written with [StackEdit](https://stackedit.io/).
