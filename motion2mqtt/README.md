# `motion2mqtt` - [motion-project.github.io][motion-project-io] transmitting output to [MQTT][mqtt-org]

[mqtt-org]: http://mqtt.org/
[motion-project-io]: https://motion-project.github.io/

Monitors attached camera and provides motion detection as micro-service, transmitting _events_ and _images_ to a designated MQTT host.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_motion2mqtt-beta.svg)](https://microbadger.com/images/dcmartin/amd64_motion2mqtt-beta "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_motion2mqtt-beta.svg)](https://microbadger.com/images/dcmartin/amd64_motion2mqtt-beta "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_motion2mqtt-beta
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_motion2mqtt-beta.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_motion2mqtt-beta.svg)](https://microbadger.com/images/dcmartin/arm_motion2mqtt-beta "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_motion2mqtt-beta.svg)](https://microbadger.com/images/dcmartin/arm_motion2mqtt-beta "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_motion2mqtt-beta
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_motion2mqtt-beta.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_motion2mqtt-beta.svg)](https://microbadger.com/images/dcmartin/arm64_motion2mqtt-beta "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_motion2mqtt-beta.svg)](https://microbadger.com/images/dcmartin/arm64_motion2mqtt-beta "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_motion2mqtt-beta
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_motion2mqtt-beta.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `dcmartin@us.ibm.com`
+ `url` - `com.github.dcmartin.open-horizon.motion2mqtt`
+ `version` - `0.0.1`

## How To Use

Copy this [repository][repository], change to the `motion2mqtt` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/motion2mqtt
% make
...
{
  "hostname": "544720549bbf-172017000003",
  "org": "dcmartin@us.ibm.com",
  "pattern": "motion2mqtt",
  "device": "test-camera-1",
  "pid": 8,
  "motion2mqtt": {
    "log_level": "info",
    "debug": "true",
    "date": 1548700891,
    "db": "debug",
    "name": "test",
    "timezone": "America/Los_Angeles",
    "post": "center",
    "mqtt": {
      "host": "mqtt",
      "port": "1883",
      "username": "<username>",
      "password": "<password>"
    }
  }
}

```
The `motion2mqtt` value will initially be incomplete until the service completes its initial execution.  Subsequent tests should return a completed payload, see below:
```
% curl -sSL http://localhost:8583
{
}
```

# Open Horizon

This service may be published to an Open Horizon exchange for an organization.  Please see the documentation for additional details.

## User Input (options)
Nodes should _register_ using a derivative of the template `userinput.json` [file][userinput].  Options include:
+ `MOTION_DEVICE_DB` - device group name (aka database)
+ `MOTION_DEVICE_NAME` - device name (aka hostname)
+ `MOTION_MQTT_HOST` - FQDN or IP address of MQTT server; defaults to `127.0.0.1`
+ `MOTION_MQTT_HOST` - FQDN or IP address of MQTT server; defaults to `127.0.0.1`
+ `MOTION_MQTT_PORT` - port #; defaults to `1883`
+ `MOTION_MQTT_USERNAME` - MQTT username; no default; required; ignored if no security
+ `MOTION_MQTT_PASSWORD` - MQTT password; no default; required; ignored if no security
+ `MOTION_POST_PICTURES` - post pictures; default `off`; options include `on`, `best`, and `center`
+ `MOTION_LOG_LEVEL` - level of logging for motion2mqtt; default `2`
+ `MOTION_LOG_TYPE` - type of logging for motion2mqtt; default `all`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
### Example registration
```
% hzn register -u {org}/iamapikey:{apikey} -n {nodeid}:{token} -e {org} -f userinput.json
```
## Exchange

The **make** targets for `publish` and `verify` make the service and its container available on the exchange.  Prior to _publishing_ the `service.json` [file][service-json] must be modified for your organization.
```
% make publish
...
Using 'dcmartin/amd64_cpu@sha256:b1d9c38fee292f895ed7c1631ed75fc352545737d1cd58f762a19e53d9144124' in 'deployment' field instead of 'dcmartin/amd64_cpu:0.0.1'
Creating com.github.dcmartin.open-horizon.cpu_0.0.1_amd64 in the exchange...
Storing IBM-6d570b1519a1030ea94879bbe827db0616b9f554-public.pem with the service in the exchange...
```
```
% make verify
# should return 'true'
hzn exchange service list -o {org} -u iamapikey:{apikey} | jq '.|to_entries[]|select(.value=="'"{org}/{url}_{version}_{arch}"'")!=null'
true
# should return 'All signatures verified'
hzn exchange service verify --public-key-file ../IBM-..-public.pem -o {org} -u iamapikey:{apikey} "{org}/{url}_{version}_{arch}"
All signatures verified
```
## About Open Horizon

Open Horizon is a distributed, decentralized, automated system for the orchestration of workloads at the _edge_ of the *cloud*.  More information is available on [Github][open-horizon].  Devices with Horizon installed may _register_ for patterns using services provided by the IBM Cloud.

## Credentials

**Note:** _You will need an IBM Cloud [account][ibm-registration]_

Credentials are required to participate; request access on the IBM Applied Sciences [Slack][edge-slack] by providing an IBM Cloud Platform API key, which can be [created][ibm-apikeys] using your IBMid.  An API key will be provided for an IBM sponsored Kafka service during the alpha phase.  The same API key is used for both the CPU and SDR addon-patterns.

# Setup

Refer to these [instructions][setup].  Installation package for macOS is also [available][macos-install]

# Further Information

Refer to the following for more information on [getting started][edge-fabric] and [installation][edge-install].

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/motion2mqtt/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/motion2mqtt/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/motion2mqtt/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/motion2mqtt/Dockerfile


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
