#!/usr/bin/env bash

source ./00_local_vars.env

ASS_DIR=`pwd ./assets`

## Docker tag for resources
DK_TAG="instruqt"
DK_NET="instruqt-net"

## Define primary datacenter and domain for the sandbox Consul DC
DOMAIN="learn"
PRIMARY_DATACENTER="local"

## Create network
log "Creating Network ${DK_NET}"
docker network create ${DK_NET} --subnet=172.20.0.0/24 --label tag=${DK_TAG} > /dev/null 2>&1


## Create Operator node
log "Starting Operator"
EXTRA_PARAMS="--volume=${ASS_DIR}/assets:/assets"
if [ "${EXPOSE_CONTAINER_PORTS}" == "true" ] ; then
  EXTRA_PARAMS="-p 7777:7777 ${EXTRA_PARAMS}"
fi
spin_container_param "operator" "${DK_NET}" "${DOCKER_REPOSITORY}/${IMAGE_NAME_BASE}:${IMAGE_TAG}" "${EXTRA_PARAMS}"


log "Starting Consul server node"
EXTRA_PARAMS="" #"--dns=172.20.0.2 --dns-search=learn"
if [ "${EXPOSE_CONTAINER_PORTS}" == "true" ]; then
    EXTRA_PARAMS="-p 1443:443 ${EXTRA_PARAMS}"
fi
spin_container_param "consul" "${DK_NET}" "${DOCKER_REPOSITORY}/${IMAGE_NAME_BASE}:${IMAGE_TAG}" "${EXTRA_PARAMS}"


log "Starting Service node Nginx"
EXTRA_PARAMS=""
if [ "${EXPOSE_CONTAINER_PORTS}" == "true" ]; then
    EXTRA_PARAMS="-p 1443:1443 ${EXTRA_PARAMS}"
fi
spin_container_param "hashicups-nginx" "${DK_NET}" "${DOCKER_REPOSITORY}/${IMAGE_NAME_NGINX}:${IMAGE_TAG}" "${EXTRA_PARAMS}"


log "Starting Service node frontend"
EXTRA_PARAMS=""
# if [ "${EXPOSE_CONTAINER_PORTS}" == "true" ]; then
#     EXTRA_PARAMS="-p 1443:1443 ${EXTRA_PARAMS}"
# fi
spin_container_param "hashicups-frontend" "${DK_NET}" "${DOCKER_REPOSITORY}/${IMAGE_NAME_FRONTEND}:${IMAGE_TAG}" "${EXTRA_PARAMS}"


log "Starting Service node API"
EXTRA_PARAMS=""
# if [ "${EXPOSE_CONTAINER_PORTS}" == "true" ]; then
#     EXTRA_PARAMS="-p 1443:1443 ${EXTRA_PARAMS}"
# fi
spin_container_param "hashicups-api" "${DK_NET}" "${DOCKER_REPOSITORY}/${IMAGE_NAME_API}:${IMAGE_TAG}" "${EXTRA_PARAMS}"


log "Starting Service node DB"
EXTRA_PARAMS=""
# if [ "${EXPOSE_CONTAINER_PORTS}" == "true" ]; then
#     EXTRA_PARAMS="-p 1443:1443 ${EXTRA_PARAMS}"
# fi
spin_container_param "hashicups-db" "${DK_NET}" "${DOCKER_REPOSITORY}/${IMAGE_NAME_DATABASE}:${IMAGE_TAG}" "${EXTRA_PARAMS}"

# Resets extra params
EXTRA_PARAMS=""


## Monitoring
# TEMPO_IMAGE="grafana/tempo:latest"
# TEMPO_PARAMS="--volume=${ASS_DIR}/assets/tempo/tempo.yaml:/etc/tempo.yaml"
# TEMPO_COMMAND="-config.file=/etc/tempo.yaml"

LOKI_IMAGE="grafana/loki:main"
LOKI_PARAMS="" #"-e JAEGER_AGENT_HOST=tempo \
             # -e JAEGER_ENDPOINT=http://tempo:14268/api/traces \
             # -e JAEGER_SAMPLER_TYPE=const \
             # -e JAEGER_SAMPLER_PARAM=1"
LOKI_COMMAND="-config.file=/etc/loki/local-config.yaml"

# PROMETHEUS_IMAGE="prom/prometheus:latest"
# PROMETHEUS_PARAMS="--volume=${ASS_DIR}/assets/prometheus:/etc/prometheus"
# PROMETHEUS_COMMAND="" #"/bin/prometheus --config.file=/etc/prometheus.yml"

GRAFANA_IMAGE="grafana/grafana:latest"
GRAFANA_PARAMS="--volume=${ASS_DIR}/assets/grafana/provisioning/datasources:/etc/grafana/provisioning/datasources \
                --volume=${ASS_DIR}/assets/grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards \
                --volume=${ASS_DIR}/assets/grafana/dashboards:/var/lib/grafana/dashboards \
                -e GF_AUTH_ANONYMOUS_ENABLED=true \
                -e GF_AUTH_ANONYMOUS_ORG_ROLE=Admin \
                -e GF_AUTH_DISABLE_LOGIN_FORM=true"
GRAFANA_COMMAND=""

MIMIR_IMAGE="grafana/mimir:latest"
MIMIR_PARAMS="--volume=${ASS_DIR}/assets/mimir/mimir.yaml:/etc/mimir/mimir.yaml"
MIMIR_COMMAND="--config.file=/etc/mimir/mimir.yaml"

# JAEGER_IMAGE="jaegertracing/all-in-one:latest"
# JAEGER_PARAMS=""
# JAEGER_COMMAND=""

# log "Starting Monitoring node Tempo"

# set -x

# spin_container_param_nouser "tempo" "${DK_NET}" "${TEMPO_IMAGE}" "${TEMPO_PARAMS}" "${TEMPO_COMMAND}"

spin_container_param_nouser "loki" "${DK_NET}" "${LOKI_IMAGE}" "${LOKI_PARAMS}" "${LOKI_COMMAND}"

# spin_container_param_nouser "prometheus" "${DK_NET}" "${PROMETHEUS_IMAGE}" "${PROMETHEUS_PARAMS}" "${PROMETHEUS_COMMAND}"

spin_container_param_nouser "grafana" "${DK_NET}" "${GRAFANA_IMAGE}" "${GRAFANA_PARAMS}" "${GRAFANA_COMMAND}"

spin_container_param_nouser "mimir" "${DK_NET}" "${MIMIR_IMAGE}" "${MIMIR_PARAMS}" "${MIMIR_COMMAND}"

# spin_container_param_nouser "jaeger" "${DK_NET}" "${JAEGER_IMAGE}" "${JAEGER_PARAMS}" "${JAEGER_COMMAND}"

# set +x

