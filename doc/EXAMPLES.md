# Examples
The examples are divided into levels of complexity:

+ Level `0` - The null service; does nothing useful.
+ Level `1` - A *synchronous* data capture and response; for low-latency data sources only.
+ Level `2` - An *asynchronous* data capture and response; data is captured independently of request for data; polls source
+ Level `3` - A service which performs analysis of data at edge; e.g. AI inferencing
+ Level `4` - A service which combines other services (i.e. `requiredServices`); also deployable as _pattern_
+ Level `5` - More than one service interoperating within a _pattern_ 
+ Level `6` - Service(s) inter-operating on more than one node.
+ Level `7` - Service -AAS for other nodes (e.g. `couchdb`)
+ Level `8` - Multi-pattern composition (i.e. _application_)

## Examples listing
Below is a listing of services, some of which are also configured to be deployed as test patterns.  Services denoted in *italic* are either WIP or TBD.

Level|Type|Services|Port|Expose|Shared|Description
---|---|---|---|---|---|---|
0|service|`hello`|80|||the minimum "hello world" example; output `{"hello":"world"}` using `socat`
1| service |`cpu`|80|||synchronous ReStFul service from low-latency data source
2| service |`wan`|80|||asynchronously updating long-latency data source, i.e. wide-area-network monitor
2| service |`hal`|80|||hardware abstraction layer (device capabilities, serial #, etc..)
2|service|`herald`|80, 5959, 5960|5959, 5960||Listen & broadcast on LAN; **Python** `Flask` example
2| *service* |`record`|80|||poll microphone and record sound bits; default `5` seconds every `10` seconds
2| *service* |`fft`|80|||capture output from `record` and perform anomaly detection
3| service |`yolo`|80|||capture image from webcam, detect & classify entities ([darknet](https://pjreddie.com/darknet/)
3|*service*|`herald4pattern`|80, 5959, 5960|5959, 5960||announce the _pattern_ information for the node
4|service, pattern|`yolo2msghub`|8587|8587||integrate multiple service outputs and send to cloud using Kafka
||+|`cpu`|
||+|`hal`| 
||+|`wan` |
||+|`yolo` |
4|*service* |`fft4mqtt`|
||+|`fft`
5 |service, pattern|`motion2mqtt`|8080, 8081, 8082|8082||capture images using [motion package](https://motion-project.github.io/); send to MQTT
||+|`mqtt`|80, 1883|1883|X|provide on-device MQTT broker; shared across services
||+|`hal`|80|||to detect camera
||+|`wan`|80|||to monitor Internet
||+|`cpu`|80|||to monitor CPU load
||+|`yolo4motion`|80|||modified from `yolo` to listen via MQTT to `motion`
||+|`mqtt`|80, 1883|1883|X|provide on-device MQTT broker; shared across services
||service|`mqtt2kafka`|80|||route specified MQTT topics' payloads to Kafka broker
5|*service*|`noize`|9191|9191||capture audio after silence and send to MQTT broker
 ||+|`mqtt`|
 ||+|`mqtt2mqtt`|
6|*service*|`fft-detect`|
||+|*fft4mqtt*|
||+|mqtt|||X|
||+|`couchdb`|||x|
||service|`mqtt2kafka`||||route specified MQTT topics' payloads to cloud
||+|mqtt|||X|
7|*service* |`couchdb`||||local noSQL store; see  [**CouchDB**](http://couchdb.apache.org/)
8|pattern|`gateway4motion`|NA|NA||gateway for multiple motion2mqtt devices
||service|`motion-control`|80|8080, 8081, 8082||Provide control infrastructure for `motion` configuration
||service|`gateway-webui`|80|80|||Web UX for _application_: motion and entity detection and classification
||+|`couchdb`|80|<STD>|X||CouchDB service with replication to/from IBM Cloudant
||+|`mqtt`|80|81, 1883|X||MQTT broker
||+|`cpu`|80|81, 1883|X||CPU monitor
||+|`hal`|80|81, 1883|X||hardware monitor
||+|`wan`|80|81, 1883|X||Internet monitor
||+|`herald4pattern`|80, 5959, 5960|5959, 5960||Herald of services in _pattern_
||+|`mqtt2kafka`|80||X||MQTT to Kafka relay
 |service|`grafana`||3306||Graphical analysis
 |service|`influxdb`||8086||Time-series database
8|pattern|`motion4gateway`|NA|NA||`yolo4motion` using `gateway4motion` services
||service|`motion2mqtt`|
||+|`cpu`|80|81, 1883|X||CPU monitor
||+|`hal`|80|81, 1883|X||hardware monitor
||+|`yolo4motion`|
||service|`mqtt2mqtt`|
||+|`herald4pattern`|80, 5959, 5960|5959, 5960||Herald of services in _pattern_
||+|`mqtt`|