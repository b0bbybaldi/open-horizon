# `yolo2msghub` - Send entity recognition counts to Kafka

Provides _pattern_ of services to send YOLO classified image entity counts to Kafka; updates as often as underlying services provide.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Services

This _pattern_ utilizes the following micro-services:

+ [`yolo`][yolo-service] - captures images from camera and counts specified entity
+ [`hal`][hal-service] - provides hardware inventory layer API for client
+ [`cpu`][cpu-service] - provides CPU percentage API for client
+ [`wan`][wan-service] - provides wide-area-network information API for client

[yolo-service]: https://github.com/dcmartin/open-horizon/tree/master/yolo
[hal-service]: https://github.com/dcmartin/open-horizon/tree/master/hal
[cpu-service]: https://github.com/dcmartin/open-horizon/tree/master/cpu
[wan-service]: https://github.com/dcmartin/open-horizon/tree/master/wan

## Architecture

This service supports the following architectures:

+ `arm` - RaspberryPi (armhf)
+ `amd64` - AMD/Intel 64-bit (x86-64)
+ `arm64` - nVidia TX2 (aarch)

## How To Use

Copy this [repository][repository], change to the `yolo2msghub` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/yolo2msghub
% make
...
{
  "hostname": "a60b406943d4-172017000007",
  "org": "dcmartin@us.ibm.com",
  "pattern": "yolo2msghub",
  "device": "davidsimac.local-amd64_yolo2msghub",
  "pid": 8,
  "yolo2msghub": {
    "log_level": "info",
    "debug": "false",
    "services": [
      {
        "name": "yolo",
        "url": "http://yolo:80"
      },
      {
        "name": "hal",
        "url": "http://hal:80"
      },
      {
        "name": "cpu",
        "url": "http://cpu:80"
      },
      {
        "name": "wan",
        "url": "http://wan:80"
      }
    ]
  }
}
```
The `yolo` payload will be incomplete until the service completes; subsequent `make check` will return complete; see below:
```
{
  "hostname": "a60b406943d4-172017000007",
  "org": "dcmartin@us.ibm.com",
  "pattern": "yolo2msghub",
  "device": "davidsimac.local-amd64_yolo2msghub",
  "pid": 8,
  "yolo2msghub": {
    "log_level": "info",
    "debug": "false",
    "services": [
      {
        "name": "yolo",
        "url": "http://yolo:80"
      },
      {
        "name": "hal",
        "url": "http://hal:80"
      },
      {
        "name": "cpu",
        "url": "http://cpu:80"
      },
      {
        "name": "wan",
        "url": "http://wan:80"
      }
    ],
    "date": 1548705396,
    "yolo": {
    "log_level": "info",
    "debug": "false",
    "date": 1548705878,
    "period": 0,
    "entity": "person",
    "time": 41.135097,
    "count": 0,
    "width": 320,
    "height": 240,
    "scale": "320x240",
    "mock": "false",
    "image": "<redacted>"
  },
    "hal": {"log_level":"info","debug":"false","date":1548701599,"period":60,"lshw":{"id":"6f8d7dbd61da","class":"system","claimed":true,"description":"Computer","product":"Raspberry Pi 3 Model B Plus Rev 1.3","serial":"000000005770a507","width":32,"children":[{"id":"core","class":"bus","claimed":true,"description":"Motherboard","physid":"0","capabilities":{"raspberrypi_3-model-b-plus":true,"brcm_bcm2837":true},"children":[{"id":"cpu:0","class":"processor","claimed":true,"description":"CPU","product":"cpu","physid":"0","businfo":"cpu@0","units":"Hz","size":1400000000,"capacity":1400000000,"capabilities":{"cpufreq":"CPU Frequency scaling"}},{"id":"cpu:1","class":"processor","disabled":true,"claimed":true,"description":"CPU","product":"cpu","physid":"1","businfo":"cpu@1","units":"Hz","size":1400000000,"capacity":1400000000,"capabilities":{"cpufreq":"CPU Frequency scaling"}},{"id":"cpu:2","class":"processor","disabled":true,"claimed":true,"description":"CPU","product":"cpu","physid":"2","businfo":"cpu@2","units":"Hz","size":1400000000,"capacity":1400000000,"capabilities":{"cpufreq":"CPU Frequency scaling"}},{"id":"cpu:3","class":"processor","disabled":true,"claimed":true,"description":"CPU","product":"cpu","physid":"3","businfo":"cpu@3","units":"Hz","size":1400000000,"capacity":1400000000,"capabilities":{"cpufreq":"CPU Frequency scaling"}},{"id":"memory","class":"memory","claimed":true,"description":"System memory","physid":"4","units":"bytes","size":972234752}]},{"id":"network","class":"network","claimed":true,"description":"Ethernet interface","physid":"1","logicalname":"eth0","serial":"02:42:ac:11:00:04","units":"bit/s","size":10000000000,"configuration":{"autonegotiation":"off","broadcast":"yes","driver":"veth","driverversion":"1.0","duplex":"full","ip":"172.17.0.4","link":"yes","multicast":"yes","port":"twisted pair","speed":"10Gbit/s"},"capabilities":{"ethernet":true,"physical":"Physical interface"}}]},"lsusb":[{"bus_number":"001","device_id":"001","device_bus_number":"1d6b","manufacture_id":"Bus 001 Device 001: ID 1d6b:0002","manufacture_device_name":"Bus 001 Device 001: ID 1d6b:0002"},{"bus_number":"001","device_id":"003","device_bus_number":"0424","manufacture_id":"Bus 001 Device 003: ID 0424:2514","manufacture_device_name":"Bus 001 Device 003: ID 0424:2514"},{"bus_number":"001","device_id":"002","device_bus_number":"0424","manufacture_id":"Bus 001 Device 002: ID 0424:2514","manufacture_device_name":"Bus 001 Device 002: ID 0424:2514"},{"bus_number":"001","device_id":"005","device_bus_number":"0424","manufacture_id":"Bus 001 Device 005: ID 0424:7800","manufacture_device_name":"Bus 001 Device 005: ID 0424:7800"},{"bus_number":"001","device_id":"004","device_bus_number":"1415","manufacture_id":"Bus 001 Device 004: ID 1415:2000","manufacture_device_name":"Bus 001 Device 004: ID 1415:2000"}],"lscpu":{"Architecture":"armv7l","Byte Order":"Little Endian","CPU(s)":"4","On-line CPU(s) list":"0-3","Thread(s) per core":"1","Core(s) per socket":"4","Socket(s)":"1","Vendor ID":"ARM","Model":"4","Model name":"Cortex-A53","Stepping":"r0p4","CPU max MHz":"1400.0000","CPU min MHz":"600.0000","BogoMIPS":"89.60","Flags":"half thumb fastmult vfp edsp neon vfpv3 tls vfpv4 idiva idivt vfpd32 lpae evtstrm crc32"},"lspci":null,"lsblk":[{"name":"mmcblk0","maj:min":"179:0","rm":"0","size":"29.7G","ro":"0","type":"disk","mountpoint":null,"children":[{"name":"mmcblk0p1","maj:min":"179:1","rm":"0","size":"43.9M","ro":"0","type":"part","mountpoint":null},{"name":"mmcblk0p2","maj:min":"179:2","rm":"0","size":"29.7G","ro":"0","type":"part","mountpoint":"/etc/hosts"}]}]},
    "cpu": {"log_level":"info","debug":"false","date":1548706059,"period":60,"interval":1,"percent":62.59},
    "wan": {"log_level":"info","debug":"false","date":1548705696,"period":1800,"speedtest":{"download":4902775.066290534,"upload":7378550.674441272,"ping":17.986,"server":{"url":"http://speedtest.sjc.sonic.net/speedtest/upload.php","lat":"37.3041","lon":"-121.8727","name":"San Jose, CA","country":"United States","cc":"US","sponsor":"Sonic.net, Inc.","id":"17846","host":"speedtest.sjc.sonic.net:8080","d":7.476714842887551,"latency":17.986},"timestamp":"2019-01-28T20:01:02.277115Z","bytes_sent":9519104,"bytes_received":12411456,"share":null,"client":{"ip":"67.164.104.198","lat":"37.2458","lon":"-121.8306","isp":"Comcast Cable","isprating":"3.7","rating":"0","ispdlavg":"0","ispulavg":"0","loggedin":"0","country":"US"}}}
  }
}
```

# Open Horizon

This service may be published to an Open Horizon exchange for an organization.  Please see the documentation for additional details.

## User Input (options)
Nodes should _register_ using a derivative of the template `userinput.json` [file][userinput].  Options include:
+ `YOLO2MSGHUB_PORT` - port for access; default 8587 
+ `YOLO2MSGHUB_APIKEY` - message hub API key; required; no default
+ `YOLO2MSGHUB_BROKER` - message hub brokers; default provided
+ `YOLO_ENTITY` - entity to count; defaults to `person`
+ `YOLO_PERIOD` - seconds between updates; defaults to `0`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)
### Example registration
```
% hzn register -u {org}/iamapikey:{apikey} -n {nodeid}:{token} -e {org} -f userinput.json
```
## Organization

Prior to _publishing_ the `service.json` [file][service-json] must be modified for your organization.

+ `org` - `dcmartin@us.ibm.com/yolo2msghub`
+ `url` - `com.github.dcmartin.open-horizon.yolo2msghub`
+ `version` - `0.0.1`

## Publishing
The **make** targets for `publish` and `verify` make the service and its container available for node registration.
```
% make publish
...
Using 'dcmartin/amd64_yolo2msghub@sha256:b1d9c38fee292f895ed7c1631ed75fc352545737d1cd58f762a19e53d9144124' in 'deployment' field instead of 'dcmartin/amd64_yolo2msghub:0.0.1'
Creating com.github.dcmartin.open-horizon.yolo2msghub_0.0.1_amd64 in the exchange...
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

[userinput]: https://github.com/dcmartin/open-horizon/blob/master/yolo2msghub/userinput.json
[service-json]: https://github.com/dcmartin/open-horizon/blob/master/yolo2msghub/service.json
[build-json]: https://github.com/dcmartin/open-horizon/blob/master/yolo2msghub/build.json
[dockerfile]: https://github.com/dcmartin/open-horizon/blob/master/yolo2msghub/Dockerfile


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
