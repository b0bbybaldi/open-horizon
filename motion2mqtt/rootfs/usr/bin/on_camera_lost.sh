#!/bin/tcsh

if ( -d "/tmpfs" ) then 
  set TMPDIR = "/tmpfs"
else
  set TMPDIR = "/tmp"
endif

unsetenv DEBUG
unsetenv DEBUG_MQTT

if ($?DEBUG) echo "$0:t $$ -- START" `date` >& /dev/stderr

## REQUIRES date utilities
if ( -e /usr/bin/dateutils.dconv ) then
   set dateconv = /usr/bin/dateutils.dconv
else if ( -e /usr/bin/dateconv ) then
   set dateconv = /usr/bin/dateconv
else if ( -e /usr/local/bin/dateconv ) then
   set dateconv = /usr/local/bin/dateconv
else
  if ($?DEBUG && $?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"ERROR":"'$0:t'","pid":"'$$'","error":"no date converter; install dateutils"}'
  goto done
endif

#
# %$ - camera name
# %Y - The year as a decimal number including the century. 
# %m - The month as a decimal number (range 01 to 12). 
# %d - The day of the month as a decimal number (range 01 to 31).
# %H - The hour as a decimal number using a 24-hour clock (range 00 to 23)
# %M - The minute as a decimal number (range 00 to 59). >& /dev/stderr
# %S - The second as a decimal number (range 00 to 61). 
#

set CN = "$1"
set YR = "$2"
set MO = "$3"
set DY = "$4"
set HR = "$5"
set MN = "$6"
set SC = "$7"
set TS = "${YR}${MO}${DY}${HR}${MN}${SC}"

# get time
set NOW = `$dateconv -i '%Y%m%d%H%M%S' -f "%s" "$TS"`

if ($?DEBUG && $?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"DEBUG":"'$0:t'","pid":"'$$'","camera":"'$CN'","time":'$NOW'}'

if ( -s "${MOTION_PID_FILE}" ) then
  set PID = ( `cat "${MOTION_PID_FILE}"`` )
  if ( "${PID}" != "" ) then
    kill -HUP  ${PID}
  endif
endif

## do MQTT
if ($?MQTT_HOST && $?MQTT_PORT) then
  # POST JSON
  set MQTT_TOPIC = "$MOTION_GROUP/$MOTION_CLIENT/$CN/status/lost"
  motion2mqtt_pub.sh -q 2 -r -t "$MQTT_TOPIC" -m '{"device":"'$MOTION_CLIENT'","camera":"'"$CN"'","time":'"$NOW"',"status":"lost"}'
  # POST no signal jpg
  set MQTT_TOPIC = "$MOTION_GROUP/$MOTION_CLIENT/$CN/image"
  motion2mqtt_pub.sh -q 2 -r -t "$MQTT_TOPIC" -f "/etc/motion/sample.jpg"
  # POST no signal gif
  set MQTT_TOPIC = "$MOTION_GROUP/$MOTION_CLIENT/$CN/image-animated"
  motion2mqtt_pub.sh -q 2 -r -t "$MQTT_TOPIC" -f "/etc/motion/sample.gif"
endif

##
## ALL DONE
##

done:
  if ($?DEBUG && $?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"DEBUG":"'$0:t'","pid":"'$$'","info":"END"}'
  if ($?DEBUG) echo "$0:t $$ -- END" `date` >& /dev/stderr
