#!/bin/bash
if [ -z $(command -v "lshw") ]; then
  echo '{"lshw":null}'
  exit 1
fi
echo -n '{"lshw":' $(lsjw -json) '}'
exit 0
