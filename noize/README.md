# &#128249; `noize` - detect sound and send to MQTT

Monitors attached microphone and provides `sox` functionality as micro-service, transmitting WAV data and spectrogram visualization (PNG) a designated [MQTT][mqtt-org] host.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

[mqtt-org]: http://mqtt.org/
[motion-project-io]: https://motion-project.github.io/

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.noize.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.noize "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.noize.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.noize "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.noize
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.noize.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.noize.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.noize "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.noize.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.noize "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.noize
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.noize.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.noize.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.noize "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.noize.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.noize "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.noize
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.noize.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `dcmartin@us.ibm.com`
+ `url` - `com.github.dcmartin.open-horizon.noize`
+ `version` - `0.0.1`

## Variables
+ `NOIZE_GROUP` - group name (aka top-level topic); defaults to `noize`
+ `NOIZE_CLIENT` - client name; defaults to `HZN_DEVICE_ID` or `hostname`
+ `NOIZE_DEVICE` - device to record sound; default: `PS3 Eye camera microphone identifier`
+ `NOIZE_START_LEVEL` - default: `1` percent
+ `NOIZE_START_SECONDS` - default: `0.1` seconds
+ `NOIZE_FINISH_LEVEL` - default: `1` percent
+ `NOIZE_FINISH_SECONDS` - default: `5` seconds
+ `NOIZE_THRESHOLD` - default: `none`; specify KHz
+ `NOIZE_LEVEL_TUNE` - default: `false`
+ `NOIZE_THRESHOLD_TUNE` - default: `false`
+ `MQTT_HOST` - IP or FQDN for mqtt host; default `mqtt`
+ `MQTT_PORT` - port number; defaults to `1883`
+ `MQTT_USERNAME` - MQTT username; defaults to ""
+ `MQTT_PASSWORD` - MQTT password; defaults to ""
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - default: `false`

## How To Use
Copy this [repository][repository], change to the `noize` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/noize
% make
...
```

The `noize` value will initially be incomplete until the service completes its initial execution.  Subsequent tests should return a completed payload, see below:

```
% make check
```

should result in a partial service payload:

```
{   
  "date": 1555192656,
  "hzn": { "agreementid": "ca200f9e5620cde9ad9d36384de52c0fcd307e8f0b22428a2f55da71ef4ac403", "arch": "arm", "cpus": 1, "device_id": "test-cpu-2", "exchange_url": "https://alpha.edge-fabric.com/v1/", "host_ips": [ "127.0.0.1", "192.168.1.52", "172.17.0.1", "172.18.0.1", "169.254.179.194" ], "organization": "dcmartin@us.ibm.com", "ram": 0, "pattern": "noize" },
  "service": { "label": "noize", "version": "0.0.1", "port": "9191" },
  "config": {
    "log_level": "info",
    "debug": true,
    "group": "noize",
    "client": "test-cpu-2",
    "device": "/dev/video0",
    "start": { "level": 1.0, "seconds": 0.1 }.
    "finish": { "level": 1.0, "seconds": 5.0 }.
    "sample_rate": 19200,
    "threshold": "",
    "threshold_tune": false,
    "level_tune": false
    "mqtt": {
      "host": "mqtt",
      "port": 1883,
      "username": "<redacted>",
      "password": "<redacted>"
    },
    "services": [ { "name": "mqtt", "url": "http://mqtt" } ]
  },  
  "noize": {
    "group": "noize",
    "client": "test-cpu-1",
    "device": "/dev/video0",
    "type": "WAV",
    "start": 1555541712,
    "finish": 1555541715,
    "event": "86",
    "seqno": "01",
    "id": "20190417225512-86-01",
    "audio": "<redacted>",
    "spectrogram": "<redacted>"
  },
  "mqtt": { "date": 1555601623, "pid": 30, "version": "mosquitto version 1.4.15", "broker": { "bytes": { "received": 24280269, "sent": 15274671 }, "clients": { "connected": 2 }, "load": { "messages": { "sent": { "one": 131.78, "five": 132.14, "fifteen": 132.46 }, "received": { "one": 131.78, "five": 132.09, "fifteen": 132.44 } } }, "publish": { "messages": { "received": 0, "sent": 297015, "dropped": 0 } }, "subscriptions": { "count": 2 } } }
}
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

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/noize/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/noize/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/noize/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/noize/Dockerfile


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
