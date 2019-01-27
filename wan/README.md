# `wan` - Wide-Area-Network monitoring service

Monitors Internet access information as micro-service; updates periodically (default `1800` seconds or 15 minutes).  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Architecture

This service supports the following architectures:

+ `arm` - RaspberryPi (armhf)
+ `amd64` - AMD/Intel 64-bit (x86-64)
+ `arm64` - nVidia TX2 (aarch)

## How To Use

Copy this [repository][repository], change to the `wan` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon .
% cd open-horizon/wan
% make
...
{
  "hostname": "4d1438b77650-172017000007",
  "org": "dcmartin@us.ibm.com",
  "pattern": "wan",
  "device": "newman-amd64_wan",
  "pid": 10,
  "wan": null
}
```
The `wan` value will initially be `null` until the service completes its initial execution.  Subsequent tests should return a completed payload, see below:
```
% curl -sSL http://localhost:8581
{
  "hostname": "4d1438b77650-172017000007",
  "org": "dcmartin@us.ibm.com",
  "pattern": "wan",
  "device": "newman-amd64_wan",
  "pid": 10,
  "wan": {
    "date": 1548614576,
    "speedtest": {
      "download": 290682338.9753496,
      "upload": 8137848.183276349,
      "ping": 16.524,
      "server": {
        "url": "http://sjc.speedtest.net/speedtest/upload.php",
        "lat": "37.3041",
        "lon": "-121.8727",
        "name": "San Jose, CA",
        "country": "United States",
        "cc": "US",
        "sponsor": "Speedtest.net",
        "id": "10384",
        "url2": "http://sjc2.speedtest.net/speedtest/upload.php",
        "host": "sjc.host.speedtest.net:8080",
        "d": 7.476714842887551,
        "latency": 16.524
      },
      "timestamp": "2019-01-27T18:42:34.474127Z",
      "bytes_sent": 10731520,
      "bytes_received": 364044952,
      "share": null,
      "client": {
        "ip": "67.164.104.198",
        "lat": "37.2458",
        "lon": "-121.8306",
        "isp": "Comcast Cable",
        "isprating": "3.7",
        "rating": "0",
        "ispdlavg": "0",
        "ispulavg": "0",
        "loggedin": "0",
        "country": "US"
      }
    }
  }
}
```

# Open Horizon

This service may be published to an Open Horizon exchange for an organization.  Please see the documentation for additional details.

## Node registration
Nodes should _register_ using a derivative of the template `userinput.json` [file][userinput].  Options include:
+ `WAN_PERIOD` - seconds between updates; defaults to `1800` seconds (15 minutes)
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
### Example registration
```
% hzn register -u {org}/iamapikey:{apikey} -n {nodeid}:{token} -e {org} -f userinput.json
```
## Organization

Prior to _publishing_ the `service.json` [file][service-json] must be modified for your organization.

+ `org` - `dcmartin@us.ibm.com/wan`
+ `url` - `com.github.dcmartin.open-horizon.wan`
+ `version` - `0.0.1`

## Publishing
The **make** targets for `publish` and `verify` make the service and its container available for node registration.
```
% make publish
...
Using 'dcmartin/amd64_wan@sha256:b1d9c38fee292f895ed7c1631ed75fc352545737d1cd58f762a19e53d9144124' in 'deployment' field instead of 'dcmartin/amd64_wan:0.0.1'
Creating com.github.dcmartin.open-horizon.wan_0.0.1_amd64 in the exchange...
Storing IBM-6d570b1519a1030ea94879bbe827db0616b9f554-public.pem with the service in the exchange...
```
```
% make verify
# should return 'true'
hzn exchange service list -o dcmartin@us.ibm.com -u iamapikey:bbNhrb_lTRsNVay_PmivR14Ie2mby3Bm0Bgo0XJne82A | jq '.|to_entries[]|select(.value=="'"dcmartin@us.ibm.com/com.github.dcmartin.open-horizon.wan_0.0.1_amd64"'")!=null'
true
# should return 'All signatures verified'
hzn exchange service verify --public-key-file ../IBM-6d570b1519a1030ea94879bbe827db0616b9f554-public.pem -o dcmartin@us.ibm.com -u iamapikey:bbNhrb_lTRsNVay_PmivR14Ie2mby3Bm0Bgo0XJne82A ""dcmartin@us.ibm.com/com.github.dcmartin.open-horizon.wan_0.0.1_amd64""
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

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/wan/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/wan/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/wan/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/wan/Dockerfile


[dcmartin]: https://github.com/dcmartin
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: https://github.com/open-horizon/anax/releases
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: https://github.com/dcmartin/open-horizon/blob/master/setup/README.md
