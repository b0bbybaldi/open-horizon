# &#128515; `hello` - The `hello-world` example

## Introduction
As with all software systems a simple example is required to on-board new users; this service is that example.

In this example a new service, `hello`, will be created, built, tested, published, and run.

The `hello` service emits a JavaScript Object Notation (JSON) response when it receives a request for its status; the `make` program is used to build, run, test, publish, and deploy; for example:

```
% make
...
{ "hello": "world" }
```

## Requirements

Using a  **&#63743; macOS computer** with the following software installed:

+ Open Horizon - the `hzn` command-line-interface (CLI) and (optional) local agent
+ Docker - the `docker` command-line-interface and service
+ `make` - build automation
+ `jq` - JSON query processor
+ `ssh` - secure shell
+ `envsubst` - GNU `gettext` package command for environment variable substitution
+ `curl` - retrieve resources identified by universal resource locators (URL)

Please refer to [`CICD.md`][cicd-md] for more information.

[cicd-md]: https://github.com/dcmartin/open-horizon/blob/master/doc/CICD.md

### &#10071;  Default exchange & registry
The Open Horizon exchange and Docker registry defaults are utilized.

+ `HZN_EXCHANGE_URL` - `http://alpha.edge-fabric.com/v1/`
+ `DOCKER_REGISTRY` - `docker.io`

## &#9995; Development host

It is expected that the development host has been configured as an Open Horizon node with the `hzn` command-line-interface (CLI) and local agent installed.  To utilize the localhost as a pattern test node, the user must have both `sudo` and `ssh` privileges for the development host.

### &#63743; macOS computer 
Install Open Horizon for the **&#63743; mac** ([other devices](https://test.cloud.ibm.com/docs/edge-fabric?topic=edge-fabric-adding-devices)) using the following commands:

```
curl http://pkg.bluehorizon.network/macos/certs/horizon-cli.crt -o horizon-cli.crt
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain horizon-cli.crt
curl http://pkg.bluehorizon.network/macos/horizon-cli-2.22.6.pkg -o horizon-cli-2.22.6.pkg
sudo installer -pkg horizon-cli-2.22.6.pkg -target /
```

Create a symbolic links from `/usr/bin` to `/usr/local/bin` to enable remote access to `hzn` and `docker`:

```
sudo ln -s /usr/local/bin/hzn /usr/bin
sudo ln -s /usr/local/bin/docker /usr/bin
```

Start Open Horizon, copy SSH credentials to test devices, and check node status.

```
horizon-container start
ssh-copy-id localhost
ssh localhost hzn node list
```


## Step 1
Create a new directory, and clone this [repository][repository]

[repository]: http://github.com/dcmartin/open-horizon

```
mkdir -p ~/gitdir/open-horizon
cd ~/gitdir/open-horizon
git clone http://github.com/dcmartin/open-horizon.git .
```

## Step 2
Copy the IBM Cloud Platform API key file downloaded from [IAM](https://cloud.ibm.com/iam), and set environment variables for Open Horizon organization and Docker namespace:

```
cp ~/Downloads/apiKey.json .
export HZN_ORG_ID=
export DOCKER_NAMESPACE=
echo "${HZN_ORG_ID}" > HZN_ORG_ID
echo "${DOCKER_NAMESPACE}" > DOCKER_NAMESPACE
```

## Step 3
Create signing keys used when publishing services and patterns.

```
hzn key create ${HZN_ORG_ID} $(whoami)@$(hostname)
mv -f *.key ${HZN_ORG_ID}.key
mv -f *.pem ${HZN_ORG_ID}.pem
```

## Step 4
Create a new directory for the new service `hello` and link repository scripts (`sh`) and service `makefile` to `hello` directory:

```
mkdir hello
cd hello
ln -s ../sh .
ln -s ../service.makefile Makefile
```

## Step 5
Create the **`./Dockerfile`** with the following contents

```
FROM ${BUILD_FROM}
RUN apt-get update && apt-get install -qq -y socat
COPY rootfs /
CMD ["/usr/bin/run.sh"]
```

## Step 6
Create `build.json` configuration file; specify `FROM` targets for Docker `build`; provide base container images for all supported architectures.

**`./build.json`**

```
{
  "build_from":{
    "amd64":"ubuntu:bionic",
    "arm": "arm32v7/ubuntu:bionic",
    "arm64": "arm64v8/ubuntu:bionic"
  }
}
```

## Step 7
Create `rootfs/` directory to store files that will be copied to the `/` directory of the container:

```
% mkdir rootfs
```

Then make the subdirectory for what will become`/usr/bin` on the container; scripts for this service will be stored there.

```
mkdir -p rootfs/usr/bin
```

## Step 8
Create the following scripts.

The `run.sh` script is called when the container is launched (n.b. `CMD` instruction in `Dockerfile).

**`rootfs/usr/bin/run.sh`**

```
#!/bin/sh
# listen to port 81 forever, fork a new process executing script /usr/bin/service.sh to return response
socat TCP4-LISTEN:81,fork EXEC:/usr/bin/service.sh
```

The `service.sh` script is called by the `run.sh` script every time it receives a status request.

**`rootfs/usr/bin/service.sh`**

```
#!/bin/sh
# generate an HTTP response containing a JavaScript Object Notation (JSON) payload
echo "HTTP/1.1 200 OK"
echo
echo '{"hello":"world"}'
```

Change the scripts' permissions to enable execution:

```
chmod 755 rootfs/usr/bin/run.sh
chmod 755 rootfs/usr/bin/service.sh
```

## Step 9
Create JSON configuration files; the variable values will be substituted during the build process.  Specify a value for `url` to replace default below.

The `service.json` file contains the `label` of the service which will be used for service identification.

**`./service.json`**

```
{
  "label": "hello",
  "org": "${HZN_ORG_ID}",
  "url": "hello-${USER}",
  "version": "0.0.1",
  "arch": "${BUILD_ARCH}",
  "sharable": "singleton",
  "deployment": {
    "services": {
      "hello": {
        "image": null
      }
    }
  }
}
```

Create `userinput.json` configuration file; this file will be used for testing the service in a pattern.

**`./userinput.json`**

```
{
  "services": [
    {
      "org": "${HZN_ORG_ID}",
      "url": "${SERVICE_URL}",
      "versionRange": "[0.0.0,INFINITY)",
      "variables": {}
    }
  ]
}
```

## Step 10 
Configure environment for to map container service port (`81`) to an open port on the development host:

```
export DOCKER_PORT=12345
```

## Step 11
Build, run, and check the service container locally using the native (i.e. `amd64`) architecture.

```
% make
>>> MAKE -- 11:44:37 -- hello building: hello-beta; tag: dcmartin/amd64_dcmartin.hello-beta:0.0.1
>>> MAKE -- 11:44:38 -- removing container named: amd64_dcmartin.hello-beta
amd64_dcmartin.hello-beta
>>> MAKE -- 11:44:38 -- running container: dcmartin/amd64_dcmartin.hello-beta:0.0.1; name: amd64_dcmartin.hello-beta
2565ecd514322e55bd6c1091982541d30e5db212682887c25d1e814caf4c0445
>>> MAKE -- 11:44:41 -- checking container: dcmartin/amd64_dcmartin.hello-beta:0.0.1; URL: http://localhost:12345
{
  "hello": "world"
}
```

## Step 12
Build all service containers for __all supported architectures__ (n.b. use `build-service` for single architecture).

```
% make service-build
```
Then test the service for __all supported architectures__; if successful, publish service for all supported architectures.

```
make service-test && make service-publish
```

## Step 13
Create pattern configuration file to test the `yolo2msghub` service.  The variables will have values substituted during the build process.

**`./pattern.json`**

```
{
  "label": "hello-${USER}",
  "services": [
    {
      "serviceUrl": "${SERVICE_URL}",
      "serviceOrgid": "${HZN_ORG_ID}",
      "serviceArch": "amd64",
      "serviceVersions": [
        {
          "version": "${SERVICE_VERSION}"
        }
      ]
    },
    {
      "serviceUrl": "${SERVICE_URL}",
      "serviceOrgid": "${HZN_ORG_ID}",
      "serviceArch": "arm",
      "serviceVersions": [
        {
          "version": "${SERVICE_VERSION}"
        }
      ]
    },
    {
      "serviceUrl": "${SERVICE_URL}",
      "serviceOrgid": "${HZN_ORG_ID}",
      "serviceArch": "arm64",
      "serviceVersions": [
        {
          "version": "${SERVICE_VERSION}"
        }
      ]
    }
  ]
}
```

## Step 14
Publish pattern for `hello` service.

```
% make pattern-publish
>>> MAKE -- 19:51:13 -- publishing: hello; organization: dcmartin@us.ibm.com; exchange: https://alpha.edge-fabric.com/v1/
Updating hello in the exchange...
Storing dcmartin@us.ibm.com.pem with the pattern in the exchange...
```

## Step 15
The development host is presumed to be the default test device if no `TEST_TMP_MACHINES` file exists; multiple devices may be listed, one per line.  For example, to create a test pool of three devices, including the localhost and two other devices identified by DNS name and IP address, respectively.

```
% echo 'localhost' >> ./TEST_TMP_MACHINES
% echo 'my-test-rpi3.local' >> ./TEST_TMP_MACHINES
% echo '192.168.1.57' >> ./TEST_TMP_MACHINES
...
```
Ensure remote access to test devices; copy SSH credentials from the the development host to all test devices; for example:

```
% ssh-copy-id localhost
```

## Step 16
Register test device(s) with `hello` pattern:

```
% make nodes
>>> MAKE -- 19:51:17 -- registering nodes: localhost
>>> MAKE -- 19:51:17 -- registering localhost 
+++ WARN -- ./sh/nodereg.sh 41808 -- missing service organization; using dcmartin@us.ibm.com/hello
--- INFO -- ./sh/nodereg.sh 41808 -- localhost at IP: 127.0.0.1
--- INFO -- ./sh/nodereg.sh 41808 -- localhost -- configured with dcmartin@us.ibm.com/hello
--- INFO -- ./sh/nodereg.sh 41808 -- localhost -- version: ; url: 
```

## Step 17
Inspect nodes until fully configured; device output is collected from executing the following commands.

+ `hzn node list`
+ `hzn agreement list`
+ `hzn service list`
+ `docker ps`

```
% make nodes-list
>>> MAKE -- 19:51:15 -- listing nodes: localhost
>>> MAKE -- 19:51:15 -- listing localhost
{"node":"localhost"}
{"agreements":[{"url":"hello-dcmartin","org":"dcmartin@us.ibm.com","version":"0.0.1","arch":"amd64"}]}
{"services":["hello-dcmartin"]}
{"container":"3b0c98f586bb637a4ec7aa939207518ca7ec5c74ae197c375be2180c7bac67b1-hello"}
{"container":"horizon1"}
```

## Step 18
Test nodes for correct output.

```
% make nodes-test
>>> MAKE -- 19:51:22 -- testing: hello; node: localhost; port: 81; date: Wed Apr 10 19:51:22 PDT 2019
ELAPSED: 0
{"hello":"world"}
```

## Step 19
Clean nodes; unregister device from Open Horizon and remove all containers and images.

```
% make nodes-clean
```

## Step 20 
Clean service; remove all running containers and images for all architectures from the development host.

```
% make service-clean
```
