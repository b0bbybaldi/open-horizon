#!/bin/bash
curl -fsSL "${HZN_EXCHANGE_URL}admin/status" -u ${HZN_ORG_ID}/iamapikey:${HZN_EXCHANGE_APIKEY} 2> /dev/null | jq '.'
