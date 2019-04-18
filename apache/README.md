# `apache` - web server

<img src="https://www.apache.org/foundation/press/kit/asf_logo_url.png" width="256"> 

Provides a base service for an [Apache](https://httpd.apache.org/) web server.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.apache.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.apache "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.apache.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.apache "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.apache
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.apache.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.apache.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.apache "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.apache.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.apache "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.apache
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.apache.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.apache.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.apache "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.apache.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.apache "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.apache
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.apache.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `dcmartin@us.ibm.com`
+ `url` - `com.github.dcmartin.open-horizon.apache`
+ `version` - `0.0.1`

## Variables
+ `APACHE_CONF` - location of configuration file; default: /etc/apache2/httpd.conf
+ `APACHE_HTDOCS` - location of HTML files; default: /var/www/localhost/htdocs
+ `APACHE_CGIBIN` - location of CGI scripts; default: /var/www/localhost/cgi-bin
+ `APACHE_HOST` - hostname; default: localhost
+ `APACHE_PORT` - port; default 8000
+ `APACHE_ADMIN` - administrative email; default root@localhost
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - default: `false`

## How To Use
Copy this [repository][repository], change to the `apache` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/apache
% make
...
```

The `apache` value will initially be incomplete until the service completes its initial execution.  Subsequent tests should return a completed payload, see below:

```
% curl -sSL http://localhost:8082
```

should result in a partial service payload:

```
```

When deployed as a pattern, additional information is provided:

```
```

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/apache/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/apache/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/apache/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/apache/Dockerfile


[dcmartin]: https://github.com/dcmartin
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md
