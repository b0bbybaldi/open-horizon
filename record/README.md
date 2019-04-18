# &#128249; `record` - record sound periodically

Monitors attached microphone and provides `arecord` functionality as micro-service, providing WAV data.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.record.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.record "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.record.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.record "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.record
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.record.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.record.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.record "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.record.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.record "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.record
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.record.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.record.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.record "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.record.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.record "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.record
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.record.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `dcmartin@us.ibm.com`
+ `url` - `com.github.dcmartin.open-horizon.record`
+ `version` - `0.0.1`

## Variables
+ `RECORD_DEVICE` - device to record sound; default: `PS3 Eye camera microphone identifier`
+ `RECORD_PERIOD` - interval to poll audio device; default: `10` seconds
+ `RECORD_SECONDS` - amount of time to record; default: `5` seconds
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
+ `DEBUG` - default: `false`

## How To Use
Copy this [repository][repository], change to the `record` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/record
% make
...
```

The `record` value will initially be incomplete until the service completes its initial execution.  Subsequent tests should return a completed payload, see below:

```
% make check
```

**EXAMPLE**

```
{   
  "date": 1555192656,
  "hzn": { "agreementid": "ca200f9e5620cde9ad9d36384de52c0fcd307e8f0b22428a2f55da71ef4ac403", "arch": "arm", "cpus": 1, "device_id": "test-cpu-2", "exchange_url": "https://alpha.edge-fabric.com/v1/", "host_ips": [ "127.0.0.1", "192.168.1.52", "172.17.0.1", "172.18.0.1", "169.254.179.194" ], "organization": "dcmartin@us.ibm.com", "ram": 0, "pattern": "record" },
  "service": { "label": "record", "version": "0.0.1", "port": "9192" },
  "config": {
    "log_level": "info",
    "debug": true,
    "device": "/dev/video0",
    "period": 10,
    "seconds": 5,
    "sample_rate": 19200,
    "services": null
  },  
  "record": {
    "type": "WAV",
    "start": 1555541712,
    "finish": 1555541717,
    "id": "test-cpu-1-20190417225512",
    "audio": "<redacted>",
  }
}
```

When deployed as a pattern, additional information is provided (n.b. `base64` encoded JPEG and GIF images have been redacted):

```
{
  "hzn": {
    "agreementid": "2cc1007a8a285e4075d58ee7bc31d2b24750aea8bb15a715f159fc93bc74b5a9",
    "arch": "arm",
    "cpus": 1,
    "device_id": "test-sdr-4",
    "exchange_url": "https://alpha.edge-fabric.com/v1/",
    "host_ips": [ "127.0.0.1", "169.254.184.120", "192.168.0.1", "192.168.1.47", "172.17.0.1" ],
    "organization": "dcmartin@us.ibm.com",
    "pattern": "dcmartin@us.ibm.com/record",
    "ram": 0
  },
  "date": 1550451493,
  "service": "record",
  "pattern": {
    "key": "dcmartin@us.ibm.com/record",
    "value": {
      "owner": "dcmartin@us.ibm.com/dcmartin@us.ibm.com",
      "label": "record",
      "description": "record as a pattern",
      "public": true,
      "services": [
        { "serviceUrl": "com.github.dcmartin.open-horizon.record", "serviceOrgid": "dcmartin@us.ibm.com", "serviceArch": "amd64", "serviceVersions": [ { "version": "0.0.1", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } },
        { "serviceUrl": "com.github.dcmartin.open-horizon.record", "serviceOrgid": "dcmartin@us.ibm.com", "serviceArch": "arm", "serviceVersions": [ { "version": "0.0.1", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } },
        { "serviceUrl": "com.github.dcmartin.open-horizon.record", "serviceOrgid": "dcmartin@us.ibm.com", "serviceArch": "arm64", "serviceVersions": [ { "version": "0.0.1", "deployment_overrides": "", "deployment_overrides_signature": "", "priority": {}, "upgradePolicy": {} } ], "dataVerification": { "metering": {} }, "nodeHealth": { "missing_heartbeat_interval": 600, "check_agreement_status": 120 } } ],
      "agreementProtocols": [ { "name": "Basic" } ],
      "lastUpdated": "2019-02-16T15:34:16.133Z[UTC]"
    }
  },
  "pid": 18,
  "record": {
    "date": 1550508626,
    "log_level": "info",
    "debug": false,
    "db": "newman",
    "name": "test-sdr-4",
    "timezone": "GMT",
    "mqtt": { "host": "horizon.dcmartin.com", "port": "1883", "username": "", "password": "" },
    "motion": {
      "post": "best",
      "event": {
        "device": "test-sdr-4",
        "camera": "default",
        "event": "59",
        "start": 1550508445,
        "image": { "device": "test-sdr-4", "camera": "default", "type": "jpeg", "date": 1550508446, "seqno": "03", "event": "59", "id": "20190218164726-59-03", "center": { "x": 600, "y": 262 }, "width": 64, "height": 120, "size": 5362, "noise": 17 },
        "elapsed": 3,
        "end": 1550508448,
        "date": 1550508574,
        "images": [ "20190218164725-59-00", "20190218164725-59-01", "20190218164725-59-02", "20190218164725-59-03", "20190218164726-59-00", "20190218164726-59-01", "20190218164726-59-02", "20190218164726-59-03", "20190218164727-59-00", "20190218164727-59-01", "20190218164728-59-00" ],
        "base64": "<redacted>"
      },
      "image": { "device": "test-sdr-4", "camera": "default", "type": "jpeg", "date": 1550508446, "seqno": "03", "event": "59", "id": "20190218164726-59-03", "center": { "x": 600, "y": 262 }, "width": 64, "height": 120, "size": 5362, "noise": 17, "base64": "<redacted>" }
    },
    "period": 300,
    "services": [ "cpu" ],
    "pid": 37,
    "cpu": { "date": 1550508327, "log_level": "info", "debug": false, "period": 60, "interval": 1, "percent": 58.32 }
  }
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

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/record/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/record/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/record/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/record/Dockerfile


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
