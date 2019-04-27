# &#127919; `hznsetup` - new node configurator

Configure new devices into Open Horizon nodes in the specified _organization_ and _exchange_, with the specified _pattern_.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

[mqtt-org]: http://mqtt.org/
[motion-project-io]: https://motion-project.github.io/

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.hznsetup.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.hznsetup "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.hznsetup.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.hznsetup "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.hznsetup
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.hznsetup.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.hznsetup.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.hznsetup "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.hznsetup.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.hznsetup "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.hznsetup
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.hznsetup.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.hznsetup.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.hznsetup "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.hznsetup.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.hznsetup "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.hznsetup
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.hznsetup.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `dcmartin@us.ibm.com`
+ `url` - `com.github.dcmartin.open-horizon.hznsetup`
+ `version` - `0.0.1`

## Service variables

+ `HZN_SETUP_EXCHANGE` - URL of exchange in which to setup device; default: `${HZN_EXCHANGE_URL}`
+ `HZN_SETUP_ORG` - organization in which to setup device; default `${HZN_ORG_ID}`
+ `HZN_SETUP_APIKEY` - IBM Cloud platform API key; default `${HZN_EXCHANGE_APIKEY}`
+ `HZN_SETUP_APPROVE` - default `"auto"`; options: { `auto`, `serial`, `mac`, `both` }
+ `HZN_SETUP_VENDOR` - default `"any"`; optional *regexp* matching `nmap(1)` vendor string
+ `HZN_SETUP_DB` - noSQL service address; default: `"http://nosqldb"`
+ `HZN_SETUP_DB_USERNAME` - username for database; default: `""`
+ `HZN_SETUP_DB_PASSWORD` - password for database; default: `""`
+ `HZN_SETUP_BASENAME` - string prepended when approve is `"auto"`; default: `""`
+ `HZN_SETUP_PATTERN` - default pattern when non-specified; default: `""`
+ `HZN_SETUP_PORT` - port on which to listen for new devices; default: `3093` (aka **&#398;Dg&#398;**)
+ `HZN_SETUP_PERIOD` - seconds between watchdog checks; default: `30`
+ `LOGTO` - specify place to log; default: `"/dev/stderr"`; use `""` for `"${TMPDIR}/${0##*/}.log"`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`; currently ignored)
+ `DEBUG` - default: `false`

## Required Services

### [`nosqldb`](https://github.com/dcmartin/open-horizon/blob/master/nosqldb/README.md)
+ `NOSQLDB_PORT` - port number; defaults to `5984`
+ `NOSQLDB_USERNAME` - NOSQLDB username; defaults to ""
+ `NOSQLDB_PASSWORD` - NOSQLDB password; defaults to ""

## Description
This service listens for new devices which have installed the edge fabric using the auto-installation script.  These new devices will request their node identification and token from this service by providing their hardware serial # and Ethernet MAC address.  Devices which are approved by the service are given an unique identifier in the organization and a corresponding authentication token.

Devices are only candidates for approval according to the `HZN_SETUP_VENDOR`:

+ `"any"` - approve new devices from any vendor string for device's MAC address
+ `"<regexp>"` - approve new devices matching regular expression, e.g. `"[Rr]aspberry*"`

Devices are approved based on the following settings for `HZN_SETUP_APPROVE`:

+ `auto` - automatically approve any new device which provides a conforming serial # and MAC address
+ `serial` - approve only devices which provide serial numbers found in the database
+ `mac` - approve only devices which provide MAC addresses found in the database
+ `both` - approve only devices which provide both serial # and _matching_ MAC addresses found in the database

Non-approved devices will receive JSON error payload. Approved devices will receive a JSON payload with identifier and token.

Devices automatically process the response and register with the exchange.

The database is updated with a date-time stamp and any previously missing information (e.g. MAC address will be added if previously unspecified or non-matching in `serial` case).

The device database may be created using the [IBM Cloudant](https://www.ibm.com/cloud/cloudant) noSQL service.  The format of the database is a series of records in the following format:

```

```

All the entries are optional when auto-approving; identifiers and tokens will be auto-generated based on serial number, MAC address, and any provided `HZN_SETUP_BASENAME`, for example: `"mynode-"`

## How To Use
Copy this [repository][repository], change to the `hznsetup` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon.hznsetup
% make
...
```

The `hznsetup` value will initially be incomplete until the service completes its initial execution.  Subsequent tests should return a completed payload, see below:

```
% make check
```
Produce a status result:

```
{
  "hznsetup": {
    "nodes": 48,
    "date": 1556227120,
    "pid": 51
  },
  "date": 1556227120,
  "hzn": {
    "agreementid": "393f54b46f6a9f8fda47bc19caac66271e10b31e20370e0d554b3d9375d5855f",
    "arch": "amd64",
    "cpus": 1,
    "device_id": "davidsimac.local",
    "exchange_url": "https://alpha.edge-fabric.com/v1",
    "host_ips": [
      "127.0.0.1",
      "192.168.1.27",
      "192.168.1.26",
      "9.80.94.82"
    ],
    "organization": "dcmartin@us.ibm.com",
    "ram": 1024,
    "pattern": null
  },
  "config": {
    "tmpdir": "/tmp",
    "logto": "/dev/stderr",
    "log_level": "info",
    "debug": true,
    "org": "dcmartin@us.ibm.com",
    "exchange": "https://alpha.edge-fabric.com/v1",
    "pattern": "",
    "port": 3093,
    "db": "https://515bed78-9ddc-408c-bf41-32502db2ddf8-bluemix.cloudant.com",
    "username": "515bed78-9ddc-408c-bf41-32502db2ddf8-bluemix",
    "approve": "auto",
    "vendor": "any",
    "services": null
  },
  "service": {
    "label": "hznsetup",
    "version": "0.0.1"
  }
}
```

## EXAMPLE

### Client request
Clients request node status by submitting a JSON payload containing device details, for example:

```
curl 'localhost:3093' -X POST -H "Content-Type: application/json" --data-binary @client-request.json 
```

The `client-request.json` file contains the device specific details:

```
{
  "serial": "000000003eb8a500",
  "mac": [
    "b8:27:eb:b8:a5:00",
    "b8:27:eb:ed:f0:55"
  ]
}
```

When the service registers the device, the service response (JSON) provides node information to the device:

```
{
  "exchange": "https://alpha.edge-fabric.com/v1",
  "org": "dcmartin@us.ibm.com",
  "pattern": "none",
  "node": {
    "serial": "000000003eb8a500[0]",
    "device": "node-b827ebb8a500",
    "token": "27e8097388f301fa84e61c7bfa7a3926d067e3e2",
    "timestamp": "04/25/19-21:18:44",
    "exchange": {
      "token": "********",
      "name": "node-b827ebb8a500",
      "owner": "dcmartin@us.ibm.com/dcmartin@us.ibm.com",
      "pattern": "",
      "registeredServices": [],
      "msgEndPoint": "",
      "softwareVersions": {},
      "lastHeartbeat": "2019-04-25T21:18:45.077Z[UTC]",
      "publicKey": "",
      "id": "dcmartin@us.ibm.com/node-b827ebb8a500"
    }
  },
  "input": {
    "serial": "000000003eb8a500",
    "mac": [
      "b8:27:eb:b8:a5:00",
      "b8:27:eb:ed:f0:55"
    ]
  },
  "date": 1556227125
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

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/hznsetup/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/hznsetup/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/hznsetup/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/hznsetup/Dockerfile


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
