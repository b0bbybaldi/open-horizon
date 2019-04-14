#!/bin/bash
set -o errexit

###
### configure Docker for experimental features
###


## add experimental feature to Docker configuration file; restart Docker after
docker_config_experimental()
{
  if [ ! -z "${1}" ]; then DOCKER_EXPERIMENTAL="${1}"; fi
  if [ "${DEBUG:-}" = 'true' ]; then echo "--- INFO -- $0 $$ -- docker_experimental: ${DOCKER_EXPERIMENTAL}" &> /dev/stderr; fi
  if [ -s "/etc/docker/daemon.json" ]; then
    config=$(jq '.' /etc/docker/daemon.json)
  fi
  if [ ! -z "${config:-}" ]; then
    echo "${config}" | jq '.experimental='${DOCKER_EXPERIMENTAL:-false} | sudo tee /etc/docker/daemon.json
  else
    echo '{"experimental":'${DOCKER_EXPERIMENTAL:-false}'}' | sudo tee /etc/docker/daemon.json
  fi
}

## update docker
docker_update()
{
  sudo apt update -y
  sudo apt install -y -qq --only-upgrade docker-ce
}

## restart docker
docker_restart()
{
  sudo service docker restart
}

###
### main
###

docker_update
docker_config_experimental true
docker_restart
