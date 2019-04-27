# &#128483; `hotword` - listen for commands

Processes sound and recognizes hotwords from a specified model. This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.hotword.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.hotword "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.hotword.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.hotword "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.hotword
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.hotword.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.hotword.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.hotword "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.hotword.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.hotword "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.hotword
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.hotword.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.hotword.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.hotword "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.hotword.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.hotword "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.hotword
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.hotword.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `dcmartin@us.ibm.com`
+ `url` - `com.github.dcmartin.open-horizon.hotword`
+ `version` - `0.0.1`

## Service variables
+ `HOTWORD_GROUP` - group name (aka top-level topic); defaults to `"hotword"`
+ `HOTWORD_CLIENT` - client name; default: `""`; set to `HZN_DEVICE_ID` or `hostname`
+ `HOTWORD_EVENT` - topic for sound event detected; default: `"+/+/+/event/start"`
+ `HOTWORD_PAYLOAD` - extension to event topic to collect payload; default: `"sound"`
+ `HOTWORD_MODEL` - default: `"alexa"`
+ `HOTWORD_INCLUDE_WAV` - include audio as base64 encoded WAV; default: `false`
+ `LOGTO` - specify place to log; default: `"/dev/stderr"`; use `""` for `${TMPDIR}/${0##*/}.log`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`; currently ignored)
+ `DEBUG` - default: `false`

## Required Services

### [`mqtt`](https://github.com/dcmartin/open-horizon/blob/master/mqtt/README.md)
+ `MQTT_PORT` - port number; defaults to `1883`
+ `MQTT_USERNAME` - MQTT username; defaults to ""
+ `MQTT_PASSWORD` - MQTT password; defaults to ""

## How To Use
Copy this [repository][repository], change to the `hotword` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/hotword
% make
...
```

The `hotword` value will initially be incomplete until the service completes its initial execution.  Subsequent tests should return a completed payload, see below:

```
% make check
```

```
```

**EXAMPLE**

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/hotword/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/hotword/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/hotword/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/hotword/Dockerfile


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
