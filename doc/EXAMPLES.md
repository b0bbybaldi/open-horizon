# Examples
The examples are divided into levels of complexit:

Level|Type|Services|Port|Expose|Shared|Description
---|---|---|---|---|---|---|
0|service|`hello`|80|||the minimum "hello world" example; output `{"hello":"world"}` using `socat`
1| service |`cpu`|80|||synchronous ReStFul service from low-latency data source
2| service |`wan`|80|||asynchronously updating long-latency data source, i.e. wide-area-network monitor
2| service |`hal`|80|||hardware abstraction layer (device capabilities, serial #, etc..)
2|service|`herald`|80, 5959, 5960|5959, 5960||Listen & broadcast on LAN; **Python** `Flask` example
3| service |`yolo`|80|||capture image from webcam, detect & classify entities ([darknet](https://pjreddie.com/darknet/)
4|service, pattern|`yolo2msghub`|8587|8587||integrate multiple service outputs and send to cloud using Kafka
 |+|`cpu`|
 |+|`hal`| 
 |+|`wan` |
 |+|`yolo` |
5 |service, pattern|`motion2mqtt`|8080, 8081, 8082|8082||capture images using [motion package](https://motion-project.github.io/); send to MQTT
 |+|`mqtt`|80, 1883|1883|X|provide on-device MQTT broker; shared across services
 |+|`hal`|80|||to detect camera
 |+|`wan`|80|||to monitor Internet
 |+|`cpu`|80|||to monitor CPU load
 |+|`yolo4motion`|80|||modified from `yolo` to listen via MQTT to `motion`
 |service|`mqtt2mqtt`|80|||route specified MQTT topics' payloads to another MQTT broker
6|pattern|`yolo4motion2kafka`|NA|NA||send `yolo4motion` to Kafka service
 |service|`mqtt2kafka`|80|||route specified MQTT topics' payloads to cloud
 |+|`couchdb`|80||x|local noSQL store for services; expose standard [**CoucbDB**](http://couchdb.apache.org/) ports
7|pattern|`gateway4motion`|NA|NA||gateway for multiple motion2mqtt devices
 |service|`motion-control`|80|8080, 8081, 8082||Provide control infrastructure for `motion` configuration
 |service|`gateway-webui`|80|80|||Web UX for _application_: motion and entity detection and classification
 |+|`couchdb`|80|<STD>|X||CouchDB service with replication to/from IBM Cloudant
 |+|`mqtt`|80|81, 1883|X||MQTT broker
 |+|`cpu`|80|81, 1883|X||CPU monitor
 |+|`hal`|80|81, 1883|X||hardware monitor
 |+|`wan`|80|81, 1883|X||Internet monitor
 |+|`herald4pattern`|80, 5959, 5960|5959, 5960||Herald of services in _pattern_
 |+|`mqtt2kafka`|80||X||MQTT to Kafka relay
 |service|`grafana`||3306||Graphical analysis
 |service|`influxdb`||8086||Time-series database
8|pattern|`motion4gateway`|NA|NA||`yolo4motion` using `gateway4motion` services
 |service|`motion2mqtt`|
 |+|`cpu`|80|81, 1883|X||CPU monitor
 |+|`hal`|80|81, 1883|X||hardware monitor
 |+|`yolo4motion`|
 |service|`mqtt2mqtt`|
 |+|`herald4pattern`|80, 5959, 5960|5959, 5960||Herald of services in _pattern_
 |+|`mqtt`|
