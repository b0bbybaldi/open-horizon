#!/bin/sh

socat TCP4-LISTEN:8585,fork EXEC:./node-id.sh

