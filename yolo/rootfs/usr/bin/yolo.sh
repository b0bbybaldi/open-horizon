#!/bin/bash
fswebcam --no-banner /tmp/image.$$.jpg
cd /darknet && ./darknet detector test cfg/voc.data cfg/yolov2-tiny-voc.cfg yolov2-tiny-voc.weights /tmp/image.$$.jpg > /tmp/image.$$.out
TIME=$(cat /tmp/image.$$.out | egrep "Predicted" | sed 's/.*Predicted in \([^ ]*\).*/\1/')
if [ -z "${TIME}" ]; then TIME=0; fi
PERSONS=$(cat /tmp/image.$$.out | egrep '^person' | wc -l)
NODEID=$(hostname)
IMAGE=$(base64 -w 0 -i predictions.jpg)
echo '{"devid":"'${NODEID}'","date":'$(date +%s)',"time":'${TIME}',"person":'${PERSONS}',"image":"'${IMAGE}'"}'
