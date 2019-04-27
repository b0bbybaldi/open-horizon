# &#9968; Open Horizon example _services_ and _patterns_

This [repository][repository] contains a set of examples to demonstrate a [CI/CD][cicd-md] process for services and patterns.

Please see the ["hello world"](https://github.com/dcmartin/open-horizon/blob/master/doc/HELLO_WORLD.md) example for an introduction to developing for [Open Horizon](http://github.com/open-horizon)

[design-md]: https://github.com/dcmartin/open-horizon/tree/master/doc/DESIGN.md

# 1. [Status][status-md] ([_beta_][beta-md])

![](https://img.shields.io/github/license/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/release/dcmartin/open-horizon.svg?style=flat)
[![Build Status](https://travis-ci.org/dcmartin/open-horizon.svg?branch=master)](https://travis-ci.org/dcmartin/open-horizon)
[![Coverage Status](https://coveralls.io/repos/github/dcmartin/open-horizon/badge.svg?branch=master)](https://coveralls.io/github/dcmartin/open-horizon?branch=master)

![](https://img.shields.io/github/repo-size/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/last-commit/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/commit-activity/w/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/contributors/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/issues/dcmartin/open-horizon.svg?style=flat)
![](https://img.shields.io/github/tag/dcmartin/open-horizon.svg?style=flat)

![Supports amd64 Architecture][amd64-shield]
![Supports aarch64 Architecture][arm64-shield]
![Supports armhf Architecture][arm-shield]

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## 1. Introduction

These services and patterns are built and pushed to designated Docker registry & namespace as well as Open Horizon exchange and organization.  The default build configuration is:

+ `HZN_EXCHANGE_URL` defaults to `https://alpha.edge-fabric.com/v1`
+ `HZN_ORG_ID` is **unspecified** (e.g. `dcmartin@us.ibm.com`)
+ `DOCKER_NAMESPACE` is **unspecified** (e.g. [`dcmartin`][docker-dcmartin])
+ `DOCKER_REGISTRY` is **unset** and defaults to `docker.io`

[docker-dcmartin]: https://hub.docker.com/?namespace=dcmartin

This repository works best on a &#63743; macOS computer.  However, macOS need some additional software install the [HomeBrew](http://brew.sh) package manager and install the necessary software:

```
% brew install gettext
% cd /usr/local/bin && ln -s ../Cellar/gettext/0.19.8.1/bin/envsubst .
```

### 1.1 Variables
The `HZN_ORG_ID` and `DOCKER_NAMESPACE` should be specified appropriately prior to any build; substitute values appropriately, for example:

```
% export HZN_ORG_ID="dcmartin@us.ibm.com"
% export DOCKER_NAMESPACE="dcmartin"
```

To make those environment variables persistent, copy them into files with the same names:

```
% echo "${HZN_ORG_ID}" > HZN_ORG_ID
% echo "${DOCKER_NAMESPACE}" > DOCKER_NAMESPACE
```

An IBM Cloud Platform API key is required to publish any service or pattern; please refer to the IBM [IAM](http://cloud.ibm.com/iam/) service to download a JSON API key file.  Then copy that file into the top-level directory of the forked or cloned repository; for example:

```
% cp ~/Downloads/apiKey.json ~/gitdir/open-horizon/
```

The API key will be automatically extracted and saved in a local `APIKEY` file for use in the build process.

### 1.2 Dependencies
Docker provides for build dependencies through the `FROM ` directive in the `Dockerfile`; most services depend on the base service containers for `base-ubuntu` or `base-alpine`.

Build all services and containers from the top-level using the following command:

```
% make service-build
```


# 2. Services & Patterns

Services are defined within a directory hierarchy of this [repository][repository]. All services in this repository share a common [design][design-md].

Patterns include:

+ `yolo2msghub` - Pattern of `yolo2msghub` with `yolo`,`hal`,`wan`, and `cpu`
+ `motion2mqtt` - Pattern of `motion2mqtt`,`yolo4motion` and `mqtt2kafka` with `mqtt`,`hal`,`wan`, and `cpu`

Services include:

+ [`cpu`][cpu-service] - provide CPU usage as percentage (0-100)
+ [`wan`][wan-service] - provide Wide-Area-Network information
+ [`hal`][hal-service] - provide Hardware-Abstraction-Layer information
+ [`yolo`][yolo-service] - recognize entities from USB camera
+ [`mqtt`][mqtt-service] - MQTT message broker service
+ [`hzncli`][hzncli] - service container with `hzn` command-line-interface installed
+ [`herald`][herald-service] - multi-cast data received from other heralds on local-area-network
+ [`yolo2msghub`][yolo2msghub-service] - transmit `yolo`, `hal`, `cpu`, and `wan` information to Kafka
+ [`motion2mqtt`][motion2mqtt-service] - transmit motion detected images to MQTT
+ [`yolo4motion`][yolo4motion-service] - subscribe to MQTT _topics_ from `motion2mqtt`,  recognize entities, and publish results
+ [`mqtt2kafka`][mqtt2kafka-service] - relay MQTT traffic to Kafka
+ [`jetson-caffe`][jetson-caffe-service] - BVLC Caffe with CUDA and OpenCV for nVidia Jetson TX
+ [`jetson-yolo`][jetson-yolo-service] - Darknet YOLO with CUDA and OpenCV for nVidia Jetson TX
+ [`jetson-digits`][jetson-digits] - nVidia DIGITS with CUDA

There are also _base_ containers that are used by the other services:

+ [`base-alpine`][base-alpine] - base container for Alpine LINUX
+ [`base-ubuntu`][base-ubuntu] - base container for Ubuntu LINUX
+ [`jetson-jetpack`][jetson-jetpack] - base container for Jetson devices
+ [`jetson-cuda`][jetson-cuda] - base container for Jetson devices with CUDA
+ [`jetson-opencv`][jetson-opencv] - base container for Jetson devices with CUDA & OpenCV

[yolo-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo/README.md
[hal-service]: https://github.com/dcmartin/open-horizon/tree/master/hal/README.md
[cpu-service]: https://github.com/dcmartin/open-horizon/tree/master/cpu/README.md
[wan-service]: https://github.com/dcmartin/open-horizon/tree/master/wan/README.md
[base-alpine]: https://github.com/dcmartin/open-horizon/tree/master/base-alpine/README.md
[base-ubuntu]: https://github.com/dcmartin/open-horizon/tree/master/base-ubuntu/README.md
[hzncli]: https://github.com/dcmartin/open-horizon/tree/master/hzncli/README.md

[herald-service]: https://github.com/dcmartin/open-horizon/tree/master/herald/README.md
[mqtt-service]: https://github.com/dcmartin/open-horizon/tree/master/mqtt/README.md

[yolo2msghub-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo2msghub/README.md
[yolo4motion-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo4motion/README.md
[motion2mqtt-service]: https://github.com/dcmartin/open-horizon/tree/master/motion2mqtt/README.md
[mqtt2kafka-service]: https://github.com/dcmartin/open-horizon/tree/master/mqtt2kafka/README.md
[jetson-caffe-service]: https://github.com/dcmartin/open-horizon/tree/master/jetson-caffe/README.md
[jetson-yolo-service]: https://github.com/dcmartin/open-horizon/tree/master/jetson-yolo/README.md

[jetson-digits]: https://github.com/dcmartin/open-horizon/tree/master/jetson-digits/README.md
[jetson-jetpack]: https://github.com/dcmartin/open-horizon/tree/master/jetson-jetpack/README.md
[jetson-cuda]: https://github.com/dcmartin/open-horizon/tree/master/jetson-cuda/README.md
[jetson-opencv]: https://github.com/dcmartin/open-horizon/tree/master/jetson-opencv/README.md

#  Further Information 

See [`SERVICE.md`][service-md] and [`PATTERN.md`][pattern-md] for more information on building services and patterns.
Refer to the following for more information on [getting started][edge-fabric] and [installation][edge-install].

# Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

David C Martin (github@dcmartin.com)

[commits]: https://github.com/dcmartin/open-horizon/commits/master
[contributors]: https://github.com/dcmartin/open-horizon/graphs/contributors
[dcmartin]: https://github.com/dcmartin
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[edge-slack]: https://ibm-cloudplatform.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup-readme-md]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md
[service-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/SERVICE.md
[cicd-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/CICD.md
[pattern-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/PATTERN.md
[status-md]: https://github.com/dcmartin/open-horizon/blob/master/STATUS.md
[beta-md]: https://github.com/dcmartin/open-horizon/blob/master/BETA.md

## [`CLOC.md`][cloc-md]

[cloc-md]: https://github.com/dcmartin/open-horizon/blob/master/CLOC.md

Language|files|blank|comment|code
:-------|-------:|-------:|-------:|-------:
Markdown|49|1986|0|12122
JSON|130|1|0|11538
Bourne Shell|105|1144|1335|7096
Dockerfile|26|311|191|1182
Bourne Again Shell|5|83|103|441
make|2|96|66|304
Python|6|84|108|293
YAML|1|0|39|148
awk|1|4|0|16
Expect|1|0|0|5
--------|--------|--------|--------|--------
SUM:|326|3709|1842|33145

## MAP

![map](http://clustrmaps.com/map_v2.png?cl=ada6a6&w=1024&t=n&d=b6TnAROswVvp8u4K3_6FHn9fu7NGlN6T_Rt3dSYwPqI&co=ffffff&ct=050505)

