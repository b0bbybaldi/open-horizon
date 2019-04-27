#!/bin/bash

# test if root
if [ $(whoami) != 'root' ]; then echo "*** ERROR $0 $$ -- run as root" &> /dev/stderr; exit 1; fi

# if no `ip` command; stop
if [ -z "$(command -v ip)" ]; then echo "*** ERROR $0 $$ -- no ip command installed" &> /dev/stderr; exit 1; fi

# test for hardware inspection
if [ -z "$(command -v lshw)" ]; then 
  APTGET=$(command -v apt-get)
  # test if we can install
  if [ -z "${APTGET}" ]; then 
    echo "*** ERROR $0 $$ -- no lshw command installed" &> /dev/stderr
    exit 1
  else 
    echo "+++ WARN $0 $$ -- installing lshw" &> /dev/stderr
    ${APTGET} install -qq -y lshw &> /dev/null
  fi
fi

LSHW=$(sudo lshw 2> /dev/null | egrep 'product|serial' | head -2 | sed 's/^[ ]*//' | awk -F': ' 'BEGIN { printf(""); x=0; } { if (x++ > 0) { printf(","); } printf("\"%s\":\"%s\"", $1, $2); } END { printf(""); }')
IPADDR=$(ip addr | egrep  -B 1 $(hostname -I | awk '{ print $1 }') | awk 'BEGIN { printf(""); x=0 } { if (x++ > 0) { printf(",") }; printf("\"%s\":\"%s\"", $1, $2); } END { printf("\n"); }' | sed 's|link/ether|mac|')

REQUEST='{'${LSHW:-null}','${IPADDR:-null}'}'

echo "${REQUEST}"
