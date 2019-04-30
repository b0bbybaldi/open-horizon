#!/bin/bash
exchange=$(curl -fsSL "${HZN_EXCHANGE_URL%/}/admin/status" -u ${HZN_ORG_ID}/iamapikey:${HZN_EXCHANGE_APIKEY} 2> /dev/null)
echo "${exchange:-null}" | jq '.org="'${HZN_ORG_ID}'"|.url="'${HZN_EXCHANGE_URL}'"'

