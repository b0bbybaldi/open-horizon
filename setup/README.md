# Open Horizon Setup

This repository contains sample scripts to automatically setup nodes for [Open Horizon][open-horizon] as provided in the IBM Cloud.  Detailed [documentation][edge-fabric] for the IBM Cloud Edge Fabric is available on-line.  A Slack [channel][edge-slack] is also available.  You may create and publish your patterns to your organization.  Refer to the [examples][examples] available on GitHub.  Please see DCMARTIN/open-horizon [instructions][dcm-oh].

*** NOTE: A [video][horizon-video-setup] (3m:30s) is available ***

## Initialization
The initialization process works through a Master/Client pattern; the Master will scan the LAN for new Client devices from specified vendor, e.g. `Rasberry Pi Foundation`, and utilize the [template][template]) to install both Open Horizon as well as the indicated pattern.  The Client devices are automatically processed by the Master as they are discovered on the local-area-network (LAN).  Client devices are prepared by choosing a standard LINUX distribution, e.g. Rasbpian Stretch Lite, and preparing an appropriate SD card.

### Initialization template
The initialization template provide the specifics for devices and patterns; devices can be specified by MAC address (n.b. see **Options: nodes**) or will be automatically discovered based (n.b. see **Options: vendor**).  Copy and edit the `template.json` file for your environment.  Values are highlighted as `%%VALUE%%` 

### Initialization script
The `init-devices.sh` script automates the setup, installation, and configuration of multiple devices; currently this script has been tested with configuration for client RaspberryPi devices running Raspbian Stretch.  The script processes a list of `nodes` identified by the `MAC` addresses, updating the node entries with their resulting configuration.  Devices specified or discovered on the network are configured for `ssh` access with PKI for each configuration after initial login with distribution username and password.  Inspect the resulting configuration file for configuration changes applied to nodes discovered.

## Manual initialization
The default configuration file name is `horizon.json` and the default network is `192.168.1.0/24`.  The initialization script may be invoked from the command-line; the following is an example list of commands.
```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone https://github.com/dcmartin/open-horizon
% cd open-horizon/setup
```
Copy and edit the configuration `template.json` using the `mkconfig.sh` script:
```
% ./mkconfig
```
Check the configuration using the `chkconfig.sh` script
```
% ./chkconfig horizon.json
```
Flash SD card with appropriate LINUX distribution *and* update the SD card with WiFi credentials and SSH access using the `flash_usd.sh` script.  Repeat process of flashing distribution and running script to produce the required number of SD cards.
```
% ./flash_usd.sh
```
Insert uSD card(s) into Raspberry Pi(s), power-on, wait for initial boot sequence -- approximately 60 seconds -- and run the `init-devices.sh` script to find the client devices and configure as Horizon nodes.
```
% ./init-devices.sh horizon.json 192.168.1.0/24
```
Software installation takes a long time, over five (5) minutes on a RaspberryPi3+.  Please be patient.

# Automated initialization
Automated initialization is provided through a [Home-Assistant][ha-home] addon that executes the initialization script periodically and updates a Cloudant database with processed clients.

1. Start Ubuntu 18 AMD64 VM (currently _not_ working on Raspbian Stretch (Lite) for RaspberryPi)
1. Run installation scripts (as root, on device) for Open Horizon and Home Assistant
   + [`ibm.biz/horizon-setup`][horizon-setup]
   + [`ibm.biz/hassio-setup`][hassio-setup]
1. Connect to Home Assistant on VM or RPi at port 8123 (e.g. `http://vmhost.local:8123/`)
1. Install MQTT addon `Mosquitto` from the HassIO Addon Store (n.b. optionally install `Configurator` addon)
1. Create a configuration from [template][template] using the _setup_ [instructions][dcm-oh-setup]
1. Create a IBM Cloudant database named `hzn-config` and copy configutration into new entry
   + Copy configuration JSON (e.g. use `pbcopy` on _macOS_)
   + Paste JSON into new record in `hzn-config` database
   + Record enttry `_id` for `horizon.config` in addon options
1. Add the [DCMARTIN/hassio-addons][dcm-addons] repository and install the [Horizon Control][horizon-addon] (HC) addon
1. Configure HC addon
    + Cloudant credentials
    + Horizon credentials with `horizon.config` as `hzn-config` entry `_id`
    + Optional credentials for `Mosquitto` addon (_default_: no `username` or `password`)
1. Start HC addon
1. Access HC addon web UI (e.g. `http://raspberrypi.local:9999`)
1. Observe data flow through Home Assistant UX (e.g. `http://vmhost.local:8123`)

A **complete** HomeAssistant configuration with support for both CPU and SDR patterns is installed using these files:

+ [configuration.yaml][conf-yaml]
+ [groups.yaml][groups-yaml]
+ [automations.yaml][automations-yaml]
+ [ui-lovelace.yaml][ui-lovelace-yaml]

# Template specification

## Option: `nodes`
A list of nodes identified by MAC address; these entries are changed during initialization to indicate status. If specified as `null` the local-area-network will be scanned for new devices. Example initial `nodes` list:
```
  "nodes": [
    { "mac": "B8:27:EB:D0:95:AD", "id": "rp1" },
    { "mac": "B8:27:EB:01:E6:05", "id": "rp2" },
    { "mac": "B8:27:EB:90:6F:4A", "id": "rp3" },
    { "mac": "B8:27:EB:BD:1D:F3", "id": "rp4" },
    { "mac": "B8:27:EB:51:A7:48", "id": "rp5" },
    { "mac": "B8:27:EB:DD:A0:94", "id": "rp6" },
    { "mac": "B8:27:EB:7B:F9:FB", "id": "rp7" },
    { "mac": "B8:27:EB:F7:3A:8C", "id": "rp8" },
    { "mac": "B8:27:EB:A2:6F:D9", "id": "rp9" }
  ] 
```

## Option: `configurations`
List of configuration definitions of `pattern`, `exchange`, `network` for a set of `nodes`, each with `device` name and authentication `token`.  Any number of `variables` may be defined appropriate for the defined `pattern`.

**Note**: _You must obtain [credentials][kafka-creds] for IBM MessageHub for alpha phase_
```
  "configurations": [
    {
      "id": "cpuconf",
      "pattern": "cpu2msghub",
      "exchange": "production",
      "network": "PRODUCTION",
      "public_key": null,
      "private_key": null,
      "variables": [
        { "key": "MSGHUB_API_KEY", "value": "%%MSGHUB_API_KEY%%" }
      ],
      "nodes": [
        { "id": "rp1", "device": "test-cpu-1", "token": "foobar" },
        { "id": "rp2", "device": "test-cpu-2", "token": "foobar" },
        { "id": "rp3", "device": "test-cpu-3", "token": "foobar" },
        { "id": "rp4", "device": "test-cpu-4", "token": "foobar" }
      ]
    },
    {
      "id": "sdrconf",
      "pattern": "sdr2msghub",
      "exchange": "production",
      "network": "PRODUCTION",
      "variables": [
        { "key": "MSGHUB_API_KEY", "value": "%%MSGHUB_API_KEY%%" }
      ],
      "public_key": null,
      "private_key": null,
      "nodes": [
        { "id": "rp5", "device": "test-sdr-1", "token": "foobar" },
        { "id": "rp6", "device": "test-sdr-2", "token": "foobar" },
        { "id": "rp7", "device": "test-sdr-3", "token": "foobar" },
        { "id": "rp8", "device": "test-sdr-4", "token": "foobar" }
      ]
    }
  ]
```

## Option: `patterns`
The edge fabric runs _patterns_ which correspond to one or more LINUX containers providing various services.  There are two public patterns in the **IBM** organization which periodically send data an IBM Message Hub (aka Kafka) service _topic_:

+ [`cpu2msghub`][cpu-pattern] - sends a CPU measurement and GPS location message to your **private** topic
+ [`sdr2msghub`][sdr-pattern] - sends a software-defined radio (SDR) audio and GPS location message to a **shared** topic

Both patterns require an API key.

+ MSGHUB_API_KEY - a **private** key for each user; may be shared across multiple devices
```
  "patterns": [
    {
      "id": "cpu2msghub",
      "org": "IBM",
      "url": "github.com.open-horizon.examples.cpu2msghub"
    },
    {
      "id": "sdr2msghub",
      "org": "IBM",
      "url": "github.com.open-horizon.examples.sdr2msghub"
    }
  ]
```

## Option: `exchanges`
List of exchange definitions for `id`, `org`, `url`, and credentials `username` and `password`
```
  "exchanges": [
    {
      "id": "production",
      "org": "<IBM Cloud login email>",
      "url": "https://alpha.edge-fabric.com/v1",
      "password": "<IBM Cloud Platform API key>"
    }
  ]
```

## Option: `networks`
List of network definitions of `id`, `dhcp`, `ssid`, and `password` for nodes.  Network configuration is _only_ applied once node has been successfully initialized.
```
  "networks": [
    {
      "id": "setup",
      "dhcp": "dynamic",
      "ssid": "%%WIFI_SSID%%",
      "password": "%%WIFI_PASSWORD%%"
    },
    {
      "id": "PRODUCTION",
      "dhcp": "dynamic",
      "ssid": "TEST",
      "password": "0123456789"
    }
  ]
```

## Output

When the script completes, the `nodes` list is updated with the configurations applied, for example:

```
    {
      "mac": "B8:27:EB:F7:3A:8C",
      "id": "rp8",
      "ssh": {
        "id": "cpuconf",
        "device": "test-cpu-1",
        "token": "Ah@rdP@$$wOoD"
      },
      "software": {
        "repository": "updates",
        "horizon": "2.20.1",
        "docker": "Docker version 18.09.0, build 4d60db4",
        "command": "/usr/bin/hzn",
        "distribution": {
          "id": "raspbian-stretch-lite",
          "kernel_version": "4.14",
          "release_date": "2018-11-13",
          "version": "November 2018"
        }
      },
      "exchange": {
        "id": "production",
        "url": "https://alpha.edge-fabric.com/v1",
        "node": {
          "dcmartin@us.ibm.com/test-cpu-1": {
            "lastHeartbeat": "2018-11-21T19:08:50.381Z[UTC]",
            "msgEndPoint": "",
            "name": "test-cpu-1",
            "owner": "dcmartin@us.ibm.com/dcmartin@us.ibm.com",
            "pattern": "",
            "publicKey": "",
            "registeredServices": [],
            "softwareVersions": null,
            "token": "********"
          }
        },
        "status": {
          "dbSchemaVersion": 15,
          "msg": "Exchange server operating normally",
          "numberOfAgbotAgreements": 6,
          "numberOfAgbotMsgs": 1,
          "numberOfAgbots": 2,
          "numberOfNodeAgreements": 8,
          "numberOfNodeMsgs": 0,
          "numberOfNodes": 20,
          "numberOfUsers": 28
        }
      },
      "node": {
        "id": "00000000c4a26fd9",
        "organization": "dcmartin@us.ibm.com",
        "pattern": "IBM/cpu2msghub",
        "name": "00000000c4a26fd9",
        "token_last_valid_time": "2018-11-21 18:03:20 +0000 UTC",
        "token_valid": true,
        "ha": false,
        "configstate": {
          "state": "configured",
          "last_update_time": "2018-11-21 18:03:24 +0000 UTC"
        },
        "configuration": {
          "exchange_api": "https://alpha.edge-fabric.com/v1/",
          "exchange_version": "1.65.0",
          "required_minimum_exchange_version": "1.63.0",
          "preferred_exchange_version": "1.63.0",
          "architecture": "arm",
          "horizon_version": "2.20.1"
        },
        "connectivity": {
          "firmware.bluehorizon.network": true,
          "images.bluehorizon.network": true
        }
      },
      "pattern": [
        {
          "name": "Policy for github.com.open-horizon.examples.cpu merged with Policy for github.com.open-horizon.examples.gps merged with cpu2msghub__IBM_arm",
          "current_agreement_id": "ca92b425dd479835fcdb965d12e492e0d87db3e2233035f3b02e027ad56aeb73",
          "consumer_id": "IBM/agbot-1",
          "agreement_creation_time": "2018-11-21 18:03:50 +0000 UTC",
          "agreement_accepted_time": "2018-11-21 18:03:59 +0000 UTC",
          "agreement_finalized_time": "2018-11-21 18:04:05 +0000 UTC",
          "agreement_execution_start_time": "2018-11-21 18:04:14 +0000 UTC",
          "agreement_data_received_time": "",
          "agreement_protocol": "Basic",
          "workload_to_run": {
            "url": "github.com.open-horizon.examples.cpu2msghub",
            "org": "IBM",
            "version": "1.2.5",
            "arch": "arm"
          }
        }
      ],
      "network": {
        "ssid": "TEST",
        "password": "0123456789"
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

David C Martin (github@dcmartin.com)

[commits]: https://github.com/dcmartin/open-horizon/setup/commits/master
[contributors]: https://github.com/dcmartin/open-horizon/setup/graphs/contributors
[releases]: https://github.com/dcmartin/open-horizon/setup/releases
[horizon-video-setup]: https://youtu.be/IfR-XY603JY

[horizon-setup]: https://github.com/dcmartin/open-horizon/blob/master/setup/hzn-install.sh
[hassio-setup]: https://github.com/dcmartin/open-horizon/blob/master/setup/hassio-install.sh

[mosquitto-core]: https://github.com/hassio-addons/repository/tree/master/mqtt
[configurator-addon]: https://www.home-assistant.io/addons/configurator
[conf-yaml]: https://raw.githubusercontent.com/dcmartin/hassio-addons/master/horizon/homeassistant/configuration.yaml
[groups-yaml]: https://raw.githubusercontent.com/dcmartin/hassio-addons/master/horizon/homeassistant/groups.yaml
[automations-yaml]: https://raw.githubusercontent.com/dcmartin/hassio-addons/master/horizon/homeassistant/automations.yaml
[ui-lovelace-yaml]: https://raw.githubusercontent.com/dcmartin/hassio-addons/master/horizon/homeassistant/ui-lovelace.yaml
[sdr2msghub-yaml]: https://github.com/dcmartin/hassio-addons/blob/master/sdr2msghub/sdr2msghub.yaml
[cpu2msghub-yaml]: https://github.com/dcmartin/hassio-addons/blob/master/cpu2msghub/cpu2msghub.yaml

[dcmartin]: https://github.com/dcmartin
[repository]: https://github.com/dcmartin/hassio-addons
[dcm-oh]: https://github.com/dcmartin/open-horizon
[dcm-oh-setup]: https://github.com/dcmartin/open-horizon/tree/master/setup
[cpu-pattern]: https://github.com/open-horizon/examples/tree/master/edge/msghub/cpu2msghub
[sdr-pattern]: https://github.com/open-horizon/examples/tree/master/edge/msghub/sdr2msghub
[cpu-addon]: https://github.com/dcmartin/hassio-addons/tree/master/cpu2msghub
[sdr-addon]: https://github.com/dcmartin/hassio-addons/tree/master/sdr2msghub
[horizon-addon]: https://github.com/dcmartin/hassio-addons/tree/master/horizon
[ha-home]: https://www.home-assistant.io/

[issue]: https://github.com/dcmartin/open-horizon/setup/issues
[keepchangelog]: http://keepachangelog.com/en/1.0.0/
[repository]: https://github.com/dcmartin/hassio-addons
[watson-nlu]: https://console.bluemix.net/catalog/services/natural-language-understanding
[watson-stt]: https://console.bluemix.net/catalog/services/speech-to-text
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[ibm-registration]: https://console.bluemix.net/registration/
[open-horizon]: https://github.com/open-horizon
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[macos-install]: https://github.com/open-horizon/anax/releases
[hzn-setup]: https://raw.githubusercontent.com/dcmartin/open-horizon/master/setup/hzn-setup.sh
[image]: http://releases.ubuntu.com/18.04.1/
[examples]: https://github.com/open-horizon/examples
[template]: https://github.com/dcmartin/open-horizon/blob/master/setup/template.json
