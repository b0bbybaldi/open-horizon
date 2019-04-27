#!/usr/bin/with-contenv bash

# ==============================================================================
set -o nounset  # Exit script on use of an undefined variable
set -o pipefail # Return exit status of the last command in the pipe that failed
# set -o errexit  # Exit script when a command exits with non-zero status
# set -o errtrace # Exit on error inside any functions or sub-shells


##
## START HTTPD
##
if [ -s "${APACHE_CONF}" ]; then
    # parameters from addon options
    APACHE_ADMIN="${HORIZON_ORGANIZATION}"
    # edit defaults
    hass.log.debug "Changing Listen to ${APACHE_PORT}"
    sed -i 's|^Listen\(.*\)|Listen '${APACHE_PORT}'|' "${APACHE_CONF}"
    hass.log.debug "Changing ServerAdmin to ${APACHE_ADMIN}"
    sed -i 's|^ServerAdmin\(.*\)|ServerAdmin '"${APACHE_ADMIN}"'|' "${APACHE_CONF}"
    # sed -i 's|^ServerTokens \(.*\)|ServerTokens '"${APACHE_TOKENS}"'|' "${APACHE_CONF}"
    # sed -i 's|^ServerSignature \(.*\)|ServerSignature '"${APACHE_SIGNATURE}"'|' "${APACHE_CONF}"
    # set environment
    echo "SetEnv ADDON_CONFIG_FILE ${ADDON_CONFIG_FILE}" >> "${APACHE_CONF}"
    echo "SetEnv HORIZON_CLOUDANT_URL ${HORIZON_CLOUDANT_URL}" >> "${APACHE_CONF}"
    echo "SetEnv HORIZON_DEVICE_DB ${HORIZON_DEVICE_DB}" >> "${APACHE_CONF}"
    echo "SetEnv HORIZON_SHARE_DIR ${HORIZON_SHARE_DIR}" >> "${APACHE_CONF}"
    # make run directory
    mkdir -p "${APACHE_RUN_DIR}"
    hass.log.debug "Starting apache2"
    # start HTTP daemon 
    service apache2 start
else
    hass.log.warning "Did not find Apache configuration at ${APACHE_CONF}"
fi

# loop while node is alive
while [ true ]; do
	sleep 30
done
