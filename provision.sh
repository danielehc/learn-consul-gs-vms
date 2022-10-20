#! /bin/bash
# set -x

# ++-----------------+
# || Functions       |
# ++-----------------+

clean_env() {

  ########## ------------------------------------------------
  header1     "CLEANING PREVIOUS SCENARIO"
  ###### -----------------------------------------------

  if [[ $(docker ps -aq --filter label=tag=${DK_TAG}) ]]; then
    docker rm -f $(docker ps -aq --filter label=tag=${DK_TAG})
  fi

  if [[ $(docker volume ls -q --filter label=tag=${DK_TAG}) ]]; then
    docker volume rm $(docker volume ls -q --filter label=tag=${DK_TAG})
  fi

  if [[ $(docker network ls -q --filter label=tag=${DK_TAG}) ]]; then
    docker network rm $(docker network ls -q --filter label=tag=${DK_TAG})
  fi

  # ## Remove custom scripts
  rm -rf ${ASSETS}scripts/*

  ## Remove certificates 
  rm -rf ${ASSETS}secrets/*

  ## Remove data 
  rm -rf ${ASSETS}data/*

  ## Remove logs
  # rm -rf ${LOGS}/*
  
  ## Unset variables
  unset CONSUL_HTTP_ADDR
  unset CONSUL_HTTP_TOKEN
  unset CONSUL_HTTP_SSL
  unset CONSUL_CACERT
  unset CONSUL_CLIENT_CERT
  unset CONSUL_CLIENT_KEY
}

## spin_container_param NAME NETWORK IMAGE_NAME:IMAGE_TAG EXTRA_DOCKER_PARAMS
## NAME: Name of the container and hostname of the node
## NETWORK: Docker network the container will run into
## IMAGE_NAME:IMAGE_TAG: Docker image and version to run
## EXTRA_DOCKER_PARAMS: The following tring gets paseed as is as Docker command params
spin_container_param() {

  CONTAINER_NAME=$1
  CONTAINER_NET=$2
  IMAGE=$3
  EXTRA_PARAMS=$4
  COMMAND=$5

  ## Containers have a user named `app` with UID=1000 and GID=1000 
  # USER="$(id -u):$(id -g)"
  USER="1000:1000"

  log "Starting container $1"
  # set -x
  docker run \
  -d \
  --net ${CONTAINER_NET} \
  --user ${USER} \
  --name=${CONTAINER_NAME} \
  --hostname=${CONTAINER_NAME} \
  --label tag=${DK_TAG} ${EXTRA_PARAMS}\
  ${IMAGE} ${COMMAND} > /dev/null 2>&1

  if [ $? != 0 ]; then
    log_err "Failed startup for container $1. Exiting."
    exit 1
  fi 

  # set +x
}

spin_container_param_nouser() {

  CONTAINER_NAME=$1
  CONTAINER_NET=$2
  IMAGE=$3
  EXTRA_PARAMS=$4
  COMMAND=$5

  log "Starting container $1"
  # set -x
  docker run \
  -d \
  --net ${CONTAINER_NET} \
  --name=${CONTAINER_NAME} \
  --hostname=${CONTAINER_NAME} \
  --label tag=${DK_TAG} ${EXTRA_PARAMS}\
  ${IMAGE} ${COMMAND} > /dev/null 2>&1

  if [ $? != 0 ]; then
    log_err "Failed startup for container $1. Exiting."
    exit 1
  fi 

  # set +x
}

show_nodes() {

  for i in `docker ps -aq --filter label=tag=instruqt`; do 
    docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}} - {{.Name}}' $i; 
  done

}

operate_modular() { 

  mkdir -p ${ASSETS}scripts

  for i in `find ops/*` ; do
    cat $i >> ${ASSETS}scripts/operate.sh
  done

  chmod +x ${ASSETS}scripts/operate.sh

  # Copy script to operator container
  docker cp ${ASSETS}scripts/operate.sh operator:/home/app/operate.sh
  
  # Run script
  # docker exec -it operator "chmod +x /home/app/operate.sh"
  docker exec -it operator "/home/app/operate.sh"

}

spin_scenario_infra() {
  
  ########## ------------------------------------------------
  header1     "DEPLOYING INFRASTRUCTURE"
  ###### -----------------------------------------------

  # set -x
  
  if [ ! -z $1 ]; then

    # Check if scenario is present

    SCENARIO_FOLDER=`find ./scenarios/$1* -maxdepth 0`
    
    if [ ! -d "${SCENARIO_FOLDER}" ]; then
      echo Scenario not found.
      echo Available scenarios:
      find ./scenarios/* -maxdepth 0 | sed 's/.*\//\t/g'
      exit 1
    fi

  else
    echo Pass a scenario as argument.
    echo Available scenarios:
    find ./scenarios/* -maxdepth 0 | sed 's/.*\//\t/g'
    exit 1
  fi

  if [ -f  ${SCENARIO_FOLDER}/spin_infrastructure.sh ]; then

      pushd ${SCENARIO_FOLDER} > /dev/null 2>&1

      ## BUG this sources again the global vars and resets the Header Counter
      source ./spin_infrastructure.sh

      popd > /dev/null 2>&1
  fi

  set +x

}

## TODO
operate_scenario() { 

  # set -x

  ########## ------------------------------------------------
  header1     "OPERATING SCENARIO"
  ###### -----------------------------------------------

  if [ ! -z $1 ]; then

    SCENARIO_FOLDER=`find ./scenarios/$1* -maxdepth 0`
    
    if [ ! -d ${SCENARIO_FOLDER} ]; then
      echo Scenario not found.
      echo Available scenarios:
      find ./scenarios/* -maxdepth 0 | sed 's/.*\//\t/g'
    fi
  
  else
    echo Pass a scenario as argument.
    echo Available scenarios:
    find ./scenarios/* -maxdepth 0 | sed 's/.*\//\t/g'
  fi

  mkdir -p ${ASSETS}scripts

  for i in `find ${SCENARIO_FOLDER}/* -name "[0-9]*"` ; do
    cat $i >> ${ASSETS}scripts/operate.sh
  done

  chmod +x ${ASSETS}scripts/operate.sh

  # Copy script to operator container
  docker cp ${ASSETS}scripts/operate.sh operator:/home/app/operate.sh
  
  # Run script
  # docker exec -it operator "chmod +x /home/app/operate.sh"
  docker exec -it operator "/home/app/operate.sh"

  # set +x

}

solve_scenario() {
  ########## ------------------------------------------------
  header1     "SOLVING SCENARIO"
  ###### -----------------------------------------------

  set -x
  
  if [ ! -z $1 ]; then

    # Check if scenario is present

    SCENARIO_FOLDER=`find ./scenarios/$1* -maxdepth 0`
    
    if [ ! -d "${SCENARIO_FOLDER}" ]; then
      echo Scenario not found.
      echo Available scenarios:
      find ./scenarios/* -maxdepth 0 | sed 's/.*\//\t/g'
      exit 1
    fi

  else
    echo Pass a scenario as argument.
    echo Available scenarios:
    find ./scenarios/* -maxdepth 0 | sed 's/.*\//\t/g'
    exit 1
  fi

  if [ -f  ${SCENARIO_FOLDER}/solve_scenario.sh ]; then

    pushd ${SCENARIO_FOLDER} > /dev/null 2>&1

    # Copy script to operator container
    docker cp solve_scenario.sh operator:/home/app/solve_scenario.sh
  
    # Run script
    # docker exec -it operator "chmod +x /home/app/operate.sh"
    docker exec -it operator "/home/app/solve_scenario.sh"
    popd > /dev/null 2>&1
  fi

  set +x
}

distribute_configs() {

  docker cp ./ops/generate_consul_server_config.sh consul:/home/app
  docker cp ./ops/generate_consul_client_config_sd.sh consul:/home/app
  docker cp ./ops/generate_consul_client_config_mesh.sh consul:/home/app
  # docker cp ./ops/generate_consul_client_config_sd.sh db:/home/app
  # docker cp ./ops/generate_consul_client_config_sd.sh api:/home/app
  # docker cp ./ops/generate_consul_client_config_sd.sh frontend:/home/app
  # docker cp ./ops/generate_consul_client_config_sd.sh nginx:/home/app

}


login() {
  docker exec -it $1 /bin/bash
}

build() {
  
  ########## ------------------------------------------------
  header1     "BUILDING DOCKER IMAGES"
  ###### -----------------------------------------------
  # ./images/batch_build.sh $1

  declare -a IMAGES=("base" "base-consul" "hashicups-database" "hashicups-api" "hashicups-frontend" "hashicups-nginx")

  for i in "${IMAGES[@]}"
  do
    header2 "Bulding image ${DOCKER_REPOSITORY}/$i"

    pushd images/$i > /dev/null 2>&1

    export DOCKER_IMAGE=`echo $i | sed 's/^base/instruqt-base/g'`
    export IMAGE_TAG="latest"
    # echo `pwd`
    make latest
  
    if [ $? != 0 ]; then
      log_err "Build failed. Exiting."
      exit 1
    fi

    popd > /dev/null 2>&1    
  done
}

print_available_services() {

  echo -e "\033[1m\033[31mFILES CREATED IN THIS MODULE:\033[0m"
    find ${ASSETS} -type f -newer ${TSTAMP_MARKER} | sort
  echo ""

  if [ "${EXPOSE_CONTAINER_PORTS}" == true ]; then 

  echo pippo

  fi

}

print_available_configs() {

  for i in `docker exec -it operator /bin/bash -c "find ~/assets -type f -name \"${1:-*}\" | sort"`; do

    REPLACEMENT_URL="/home/app"

    if [ "${START_FILE_BROWSER}" == true ] ; then

      if [ "${EXPOSE_CONTAINER_PORTS}" == true ]; then 

        REPLACEMENT_URL="http://localhost:7777/files"
      else
        REPLACEMENT_URL="http://`docker inspect operator --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'`:7777/files"
      fi
    fi

    echo ${REPLACEMENT_URL}$(echo $i | sed 's/\/home\/app//g')

  done

}

# ++-----------------+
# || Variables       |
# ++-----------------+

# --- GLOBAL VARS AND FUNCTIONS ---
source ops/00_global_vars.env

# --------------------
# --- FLOW CONTROL ---
# --------------------

## Build docker imgages on startup
## TODO: Make it count
BUILD_ON_STARTUP=false

## Generate new certificates
export GEN_NEW_CERTS=false

# --------------------
# ------ CONSUL ------
# --------------------
CONSUL_VERSION=${CONSUL_VERSION:="latest"}
VAULT_VERSION="latest"

# --------------------
# ------ DOCKER ------
# --------------------

# danielehc/instruqt-base

# ${DOCKER_REPOSITORY}/${IMAGE_NAME_BASE}:${IMAGE_TAG}
DOCKER_REPOSITORY=${DOCKER_REPOSITORY:-"danielehc"}
IMAGE_NAME_BASE="instruqt-base-consul"
IMAGE_NAME_NGINX="hashicups-nginx"
IMAGE_NAME_FRONTEND="hashicups-frontend"
IMAGE_NAME_API="hashicups-api"
IMAGE_NAME_DATABASE="hashicups-database"
# IMAGE_TAG=v${CONSUL_VERSION}
IMAGE_TAG="latest"

GENERATE_MULTIPLE_NETWORKS=false

## If true will expose to host some of the container ports
EXPOSE_CONTAINER_PORTS=false

# For OSes different than Linux ports are exposed automatically
if [ `is_linux` != "true" ] ; then
  EXPOSE_CONTAINER_PORTS=true
fi

## Docker tag for resources
DK_TAG="instruqt"
DK_NET="instruqt-net"

# --------------------
# --- ENVIRONMENT ----
# --------------------

ASSETS="assets/"

## Comma separates string of prerequisites
PREREQUISITES="docker,wget,jq,grep,sed,tail,awk"

# ++-----------------+
# || Begin           |
# ++-----------------+

## Check Parameters
if   [ "$1" == "clean" ]; then
  clean_env
  exit 0
elif [ "$1" == "scenario" ]; then
  clean_env
  spin_scenario_infra $2
  operate_scenario $2
  distribute_configs
  exit 0
elif [ "$1" == "login" ]; then
  login $2
  exit 0
elif [ "$1" == "nodes" ]; then
  show_nodes
  exit 0
elif [ "$1" == "build" ]; then
  export CONSUL_VERSION
  export DOCKER_REPOSITORY
  build "./images/"
  exit 0
elif [ "$1" == "solve" ]; then
  solve_scenario $2
  exit 0
elif [ "$1" == "spin" ]; then
  clean_env
  spin_scenario_infra $2
  # operate_scenario $2
  # distribute_configs
  exit 0
# elif [ "$1" == "operate" ]; then
#   operate_modular
#   exit 0
# elif [ "$1" == "scenario_infra" ]; then
#   clean_env
#   spin_scenario_infra $2
#   # operate_scenario $2
#   exit 0
# elif [ "$1" == "services" ]; then
#   print_available_services
#   exit 0
# elif [ "$1" == "configs" ]; then
#   print_available_configs $2
#   exit 0
# elif [ "$1" == "build_only" ]; then
#   export CONSUL_VERSION
#   export ONLY_BUILD=true
#   # export DOCKER_REPOSITORY
#   build "./images/"
#   exit 0
fi


## Clean environment
log "Cleaning Environment"
clean_env

########## ------------------------------------------------
header1     "PROVISIONING PREREQUISITES"
###### -----------------------------------------------

## Checking Prerequisites
log "Checking prerequisites..."
for i in `echo ${PREREQUISITES} | sed 's/,/ /g'` ; do
  prerequisite_check $i
done


