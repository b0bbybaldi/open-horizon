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

## Variables
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
{
  "serial": "<string>",
  "mac":["00:04:4B:CC:4A:A6",..],
  "

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
    "nodes": 56,
    "date": 1556325635,
    "pid": 52
  },
  "date": 1556325635,
  "hzn": {
    "agreementid": "175ac3b3a3bb6485f22486fda800ff772b5ac7cfdfb8d698f005d3185e6bcb5a",
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
    "pkg": {
      "url": "http://pkg.bluehorizon.network/",
      "key": "http://pkg.bluehorizon.network/bluehorizon.network-public.key"
    },
    "basename": "test-",
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
    "product": "jetson-nano",
    "serial": "042111900396808083fb",
    "mac": "00:04:4b:cc:4a:a6",
    "inet": "192.168.1.87/24"
  }
```

When the service registers the device, the service response (JSON) provides node information to the device:

```
{
  "exchange": "https://alpha.edge-fabric.com/v1",
  "org": "dcmartin@us.ibm.com",
  "pattern": "none",
  "node": {
    "serial": "042111900396808083fb",
    "device": "test-00044bcc4aa6",
    "exchange": {
      "token": "********",
      "name": "test-00044bcc4aa6",
      "owner": "dcmartin@us.ibm.com/dcmartin@us.ibm.com",
      "pattern": "",
      "registeredServices": [],
      "msgEndPoint": "",
      "softwareVersions": {},
      "lastHeartbeat": "2019-04-27T00:40:58.904Z[UTC]",
      "publicKey": "",
      "id": "dcmartin@us.ibm.com/test-00044bcc4aa6"
    },
    "token": "e16b73d92d490df288fdfea68406d74935b90124"
  },
  "date": 1556325659
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
