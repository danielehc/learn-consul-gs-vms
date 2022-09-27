#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

## Number of servers to spin up (3 or 5 recommended for production environment)
SERVER_NUMBER=1

## Define primary datacenter and domain for the sandbox Consul DC
DOMAIN="consul"
PRIMARY_DATACENTER="dc1"

# SUpports specific version or `latest`
# CONSUL_VERSION="1.12.2"
CONSUL_VERSION="latest"

## Define the number and names of datacenters to deploy
declare -a DATACENTERS=("${PRIMARY_DATACENTER}") # "dc2" "dc3")

# declare -a SERVICES=() #"web" "api" "db")
declare -a SERVICES=("frontend" "payments" "product-api" "product-api-db" "public-api")
SVC_MATCH_IMAGE_NAME=true

declare -a MESH_ELEMENTS=() #"igw" "tgw" "mgw")

# Start file manager on operator
START_FILE_BROWSER=true

# +---+  
# | Flow Control :  Variables to influence flow of execution
# +---+  

## Debug flow, if no proper Docker image is defined start fake-app
START_APPS=false

## Timestamp
TSTAMP_MARKER="/tmp/tstamp.$$"
touch -t `date '+%Y%m%d%H%M.%S'` ${TSTAMP_MARKER}

## Header Counters
H1=0
H2=0
H3=0

# ++-----------------+
# || Functions       |
# ++-----------------+

## Prints a line on stdout prepended with date and time
log() {
  echo -e "\033[1m["$(date +"%Y-%d-%d %H:%M:%S")"] - ${@}\033[0m"
}

log_err() {
  DEC_ERR="\033[1m\033[31m[ERROR] \033[0m\033[1m"
  log "${DEC_ERR}${@}"  
}

log_warn() {
  DEC_WARN="\033[1m\033[33m[WARN] \033[0m\033[1m"
  log "${DEC_WARN}${@}"  
}

## Prints a header on stdout
header() {

  echo -e " \033[1m\033[32m"

  echo ""
  echo "++----------- " 
  echo "||   ${@} "
  echo "++------      " 

  echo -e "\033[0m"
}

header1() {
  H1=$((H1+1))
  H2=0
  H3=0
  header "$H1 - $@"

  log_provision "# $H1 - ${@}"
}

header2() {
  H2=$((H2+1))
  H3=0

  echo -e " \033[1m\033[32m"
  echo "##   $H1.$H2 - ${@} "
  echo -e "\033[0m"

  log_provision "## $H1.$H2 - ${@}"

}

header3() {

  H3=$((H3+1))

  echo -e " \033[1m\033[32m"
  echo "###   $H1.$H2.$H3 - ${@} "
  echo -e "\033[0m"

  log_provision "### $H1.$H2.$H3 - ${@}"

}

log_provision() {

  if [ ! -z "${LOG_PROVISION}" ]; then
    touch ${LOG_PROVISION}
    echo -e "${@}" >> ${LOG_PROVISION}
  fi

}

## Check if the binary exists otherwise exits
prerequisite_check() {
  if [ ! -z "$1" ] ; then
    if [[ `which $1` ]] ; then
      log "[ $1 ] - found"
      return
    fi
  fi
  log_err "[ $1 ] - Not found"
  exit 1
}

## Check if OS is Linux based or not
is_linux() {

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo true
  else
    echo false
  fi

}

#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

WORKDIR="/home/app/"
ASSETS="${WORKDIR}assets/"
LOGS="${WORKDIR}logs/"

LOG_PROVISION="${LOGS}provision.log"
LOG_CERTIFICATES="${LOGS}certificates.log"
LOG_FILES_CREATED="${LOGS}files_created.log"

# Create necessary directories to operate
mkdir -p ${ASSETS}
mkdir -p ${LOGS}

PATH=$PATH:/home/app/bin

## Instruqt compatibility
if [[ ! -z "${INSTRUQT_PARTICIPANT_ID}" ]]; then
    FQDN_SUFFIX=".$INSTRUQT_PARTICIPANT_ID.svc.cluster.local"
else
    FQDN_SUFFIX=""
fi

SSH_OPTS="StrictHostKeyChecking=accept-new"

# ++-----------------+
# || Functions       |
# ++-----------------+

print_env() {
  if [ ! -z $1 ] ; then

    if [[ -f "${ASSETS}/env-$1.conf" ]] && [[ -s "${ASSETS}/env-$1.conf" ]] ;  then

      cat ${ASSETS}/env-$1.conf

    elif [ "$1" == "consul" ]; then

      ## If the environment file does not exist prints current variables
      ## This is used to export them in a file afted defining them in the script.
      echo " export CONSUL_HTTP_ADDR=${CONSUL_HTTP_ADDR}"
      echo " export CONSUL_HTTP_TOKEN=${CONSUL_HTTP_TOKEN}"
      echo " export CONSUL_HTTP_SSL=${CONSUL_HTTP_SSL}"
      echo " export CONSUL_CACERT=${CONSUL_CACERT}"
      echo " export CONSUL_TLS_SERVER_NAME=${CONSUL_TLS_SERVER_NAME}"
      echo " export CONSUL_FQDN_ADDR=${CONSUL_FQDN_ADDR}"

    elif [ "$1" == "vault" ]; then

      echo " export VAULT_ADDR=${VAULT_ADDR}"
      echo " export VAULT_TOKEN=${VAULT_TOKEN}"

    fi

  else
    # If no argument is passed prints all available environment files
    for env_file in `find ${ASSETS} -name env-*`; do
      
      echo -e "\033[1m\033[31mENV: ${env_file}\033[0m"
      cat ${env_file}
      echo ""
    done
  fi
}

# Waits for a node with hostname passed as an argument to be resolvable
wait_for() {

  _HOSTNAME=$1

  _NODE_IP=`dig +short $1`

  while [ -z ${_NODE_IP} ]; do

    log_warn "$1 not running yet"

    _NODE_IP=`dig +short $1`
  
  done

}

run_locally() {
  echo "Run command and log on files"
}

run_on() {
  echo "Run command and log on files"
}

source_and_log() {
    echo "Source file and log on files"
}

get_created_files() {

  echo "------------------------------------------------"  >> ${LOG_FILES_CREATED}
  echo " Module $H1 - Files Created"                       >> ${LOG_FILES_CREATED}
  echo "-----------------------------------------------"   >> ${LOG_FILES_CREATED}
  echo ""                                                  >> ${LOG_FILES_CREATED}

  find ${ASSETS} -type f -newer ${TSTAMP_MARKER} | sort >> ${LOG_FILES_CREATED}

  echo ""                                                  >> ${LOG_FILES_CREATED}

  if [[ ! -z "$1" ]] && [[ "$1" == "--verbose" ]] ; then

    echo -e "\033[1m\033[31mFILES CREATED IN THIS MODULE:\033[0m"
    find ${ASSETS} -type f -newer ${TSTAMP_MARKER} | sort
    echo ""

  fi

  touch -t `date '+%Y%m%d%H%M.%S'` ${TSTAMP_MARKER}

  sleep 1

}

# ++-----------------+
# || Begin           |
# ++-----------------+

# Check if start filebrowser on operator
if [ "${START_FILE_BROWSER}" == true ]; then
  log "Starting filebrowser on operator"
  LOG_FILEBROWSER="${LOGS}filebrowser.log"
  nohup filebrowser > ${LOG_FILEBROWSER} 2>&1 &
fi


# log "Starting Consul on operator"
# Generate Consul config

mkdir -p ${ASSETS}/consul/config
mkdir -p ${ASSETS}/consul/data



#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+


# ++-----------------+
# || Begin           |
# ++-----------------+

header1 "Starting Application"

header2 "Starting Database"

ssh -o ${SSH_OPTS} app@hashicups-db${FQDN_SUFFIX} \
      "bash -c /start_database.sh"

header2 "Starting API"

ssh -o ${SSH_OPTS} app@hashicups-api${FQDN_SUFFIX} \
      "bash -c /start_api.sh"

header2 "Starting Frontend"
set -x 
ssh -o ${SSH_OPTS} app@hashicups-frontend${FQDN_SUFFIX} \
      "bash -c /start_frontend.sh"
set +x 
header2 "Starting Nginx"

ssh -o ${SSH_OPTS} app@hashicups-nginx${FQDN_SUFFIX} \
      "bash -c /start_nginx.sh"
#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

## Number of servers to spin up (3 or 5 recommended for production environment)
SERVER_NUMBER=1

## Define primary datacenter and domain for the sandbox Consul DC
DOMAIN="consul"
DATACENTER="dc1"

SSH_OPTS="StrictHostKeyChecking=accept-new"

# echo "Solving scenario 00"

ASSETS="/home/app/assets"

rm -rf ${ASSETS}

mkdir -p ${ASSETS}

pushd ${ASSETS}


# ++-----------------+
# || Begin           |
# ++-----------------+


header1 "Starting Consul server"

##########################################################

header2 "Install Consul"

log  "Install Consul on operator"
cp /opt/bin/consul /usr/local/bin/consul && chmod +x /usr/local/bin/consul

log "Test Consul installation"
consul version


header2 Install Consul on Consul server
ssh -o ${SSH_OPTS} app@consul${FQDN_SUFFIX} \
      "cp /opt/bin/consul /usr/local/bin/consul && chmod +x /usr/local/bin/consul"

log "Test Consul installation"
ssh -o ${SSH_OPTS} app@consul${FQDN_SUFFIX} \
      "/usr/local/bin/consul version"

##########################################################
header2 "Create secrets"

log "Generate gossip encryption key"
echo encrypt = \"$(consul keygen)\" > agent-gossip-encryption.hcl

log "Generate CA"
consul tls ca create -domain=${DOMAIN}

log "Generate Server Certificates"
consul tls cert create -server -domain ${DOMAIN} -dc=${DATACENTER}

log "Create Consul folders"

ssh -o ${SSH_OPTS} app@consul${FQDN_SUFFIX} \
      "mkdir -p /etc/consul/config && mkdir -p /etc/consul/data"


##########################################################
header2 "Configure Consul"

log "Generate agent configuration"
tee agent-server-secure.hcl > /dev/null << EOF
# agent-server-secure.hcl

# Data Persistence
data_dir = "/etc/consul/data"

# Logging
log_level = "DEBUG"

# Enable service mesh
connect {
  enabled = true
}

# Addresses and ports
addresses {
  grpc = "127.0.0.1"
  // http = "127.0.0.1"
  // http = "0.0.0.0"
  https = "0.0.0.0"
  dns = "127.0.0.1"
}

ports {
  grpc  = 8502
  http  = 8500
  https = 443
  dns   = 53
}

# DNS recursors
recursors = ["1.1.1.1"]

## Disable script checks
enable_script_checks = false

## Enable local script checks
enable_local_script_checks = true
EOF

log "Generate TLS configuration"
tee agent-server-tls.hcl > /dev/null << EOF
## TLS Encryption (requires cert files to be present on the server nodes)
verify_incoming        = false
verify_incoming_rpc    = true
verify_outgoing        = true
verify_server_hostname = true

auto_encrypt {
  allow_tls = true
}

ca_file   = "/etc/consul/config/consul-agent-ca.pem"
cert_file = "/etc/consul/config/${DATACENTER}-server-${DOMAIN}-0.pem"
key_file  = "/etc/consul/config/${DATACENTER}-server-${DOMAIN}-0-key.pem"
EOF


log "Generate ACL configuration"
tee agent-server-acl.hcl > /dev/null << EOF
## ACL configuration
acl = {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true
  enable_token_replication = true
  down_policy = "extend-cache"
}
EOF

log "Generate server specific configuration"
tee agent-server-specific.hcl > /dev/null << EOF
## Server specific configuration for ${DATACENTER}
server = true
bootstrap_expect = ${SERVER_NUMBER}
datacenter = "${DATACENTER}"

client_addr = "127.0.0.1"

## UI configuration (1.9+)
ui_config {
  enabled = true
}
EOF

log "Copy Configuration on Consul server"
scp -o ${SSH_OPTS} agent-gossip-encryption.hcl                 consul${FQDN_SUFFIX}:/etc/consul/config > /dev/null 2>&1
scp -o ${SSH_OPTS} consul-agent-ca.pem                         consul${FQDN_SUFFIX}:/etc/consul/config > /dev/null 2>&1
scp -o ${SSH_OPTS} ${DATACENTER}-server-${DOMAIN}-0.pem        consul${FQDN_SUFFIX}:/etc/consul/config > /dev/null 2>&1
scp -o ${SSH_OPTS} ${DATACENTER}-server-${DOMAIN}-0-key.pem    consul${FQDN_SUFFIX}:/etc/consul/config > /dev/null 2>&1
scp -o ${SSH_OPTS} agent-server-secure.hcl                     consul${FQDN_SUFFIX}:/etc/consul/config > /dev/null 2>&1
scp -o ${SSH_OPTS} agent-server-tls.hcl                        consul${FQDN_SUFFIX}:/etc/consul/config > /dev/null 2>&1
scp -o ${SSH_OPTS} agent-server-acl.hcl                        consul${FQDN_SUFFIX}:/etc/consul/config > /dev/null 2>&1
scp -o ${SSH_OPTS} agent-server-specific.hcl                   consul${FQDN_SUFFIX}:/etc/consul/config > /dev/null 2>&1

popd

##########################################################
header2 "Start Consul"

log "Start Consul on Consul server"

CONSUL_PID=`ssh -o ${SSH_OPTS} consul${FQDN_SUFFIX} "pidof consul"`

until [ ! -z "${CONSUL_PID}" ] 

do
  log_warn "Consul not started yet...starting"

  ssh -o ${SSH_OPTS} consul${FQDN_SUFFIX} \
    "/usr/local/bin/consul agent \
    -node=consul \
    -log-file=/tmp/consul-server-${DATACENTER} \
    -config-dir=/etc/consul/config > /tmp/consul-server.log 2>&1" &

  sleep 1
  
  CONSUL_PID=`ssh -o StrictHostKeyChecking=accept-new consul "pidof consul"`

done

header2 "Configure ACL"

export CONSUL_HTTP_ADDR="https://consul${FQDN_SUFFIX}"
export CONSUL_HTTP_SSL=true
export CONSUL_CACERT="${ASSETS}/consul-agent-ca.pem"
export CONSUL_TLS_SERVER_NAME="server.${PRIMARY_DATACENTER}.${DOMAIN}"
export CONSUL_FQDN_ADDR="consul${FQDN_SUFFIX}"

log "ACL Bootstrap"

for i in `seq 1 9`; do

  consul acl bootstrap --format json > ${ASSETS}/acl-token-bootstrap.json 2> /dev/null;

  excode=$?

  if [ ${excode} -eq 0 ]; then
    break;
  else
    if [ $i -eq 9 ]; then
      echo -e '\033[1m\033[31m[ERROR] \033[0m Failed to bootstrap ACL system, exiting.';
      exit 1
    else
      echo -e '\033[1m\033[33m[WARN] \033[0m ACL system not ready. Retrying...';
      sleep 5;
    fi
  fi

done

export CONSUL_HTTP_TOKEN=`cat ${ASSETS}/acl-token-bootstrap.json | jq -r ".SecretID"`

# echo $CONSUL_HTTP_TOKEN

log "Create ACL policies and tokens"

tee ${ASSETS}/acl-policy-dns.hcl > /dev/null << EOF
## dns-request-policy.hcl
node_prefix "" {
  policy = "read"
}
service_prefix "" {
  policy = "read"
}
# only needed if using prepared queries
query_prefix "" {
  policy = "read"
}
EOF

tee ${ASSETS}/acl-policy-server-node.hcl > /dev/null << EOF
## consul-server-one-policy.hcl
node_prefix "consul" {
  policy = "write"
}
EOF

consul acl policy create -name 'acl-policy-dns' -description 'Policy for DNS endpoints' -rules @${ASSETS}/acl-policy-dns.hcl  > /dev/null 2>&1

consul acl policy create -name 'acl-policy-server-node' -description 'Policy for Server nodes' -rules @${ASSETS}/acl-policy-server-node.hcl  > /dev/null 2>&1

consul acl token create -description 'DNS - Default token' -policy-name acl-policy-dns --format json > ${ASSETS}/acl-token-dns.json 2> /dev/null

DNS_TOK=`cat ${ASSETS}/acl-token-dns.json | jq -r ".SecretID"` 

## Create one agent token per server
log "Setup ACL tokens for Server"

consul acl token create -description "server agent token" -policy-name acl-policy-server-node  --format json > ${ASSETS}/server-acl-token.json 2> /dev/null

SERV_TOK=`cat ${ASSETS}/server-acl-token.json | jq -r ".SecretID"`


consul acl set-agent-token agent ${SERV_TOK}
consul acl set-agent-token default ${DNS_TOK}

log "Bootstrap token: ${CONSUL_HTTP_TOKEN}"#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+

## Number of servers to spin up (3 or 5 recommended for production environment)
SERVER_NUMBER=1

## Define primary datacenter and domain for the sandbox Consul DC
DOMAIN="consul"
DATACENTER="dc1"

SSH_OPTS="StrictHostKeyChecking=accept-new"

# echo "Solving scenario 00"

ASSETS="/home/app/assets"

# rm -rf ${ASSETS}

# mkdir -p ${ASSETS}

pushd ${ASSETS}

SERVICE=""
NODE_NAME=""
SERVER_NAME=${CONSUL_FQDN_ADDR}

# ++-----------------+
# || Begin           |
# ++-----------------+


header1 "Starting Consul client agents"

log ""
tee ${ASSETS}/agent-client-secure.hcl > /dev/null << EOF
## agent-client-secure.hcl
server = false
datacenter = "${DATACENTER}"
domain = "${DOMAIN}" 

# Logging
log_level = "DEBUG"

#client_addr = "127.0.0.1"

retry_join = [ "${SERVER_NAME}${FQDN_SUFFIX}" ]

# Ports

ports {
  grpc  = 8502
  http  = 8500
  https = 443
  dns   = 8600
}

enable_script_checks = false

enable_central_service_config = true

data_dir = "/etc/consul/data"

## TLS Encryption (requires cert files to be present on the server nodes)
tls {
  defaults {
    ca_file   = "/etc/consul/config/consul-agent-ca.pem"
    verify_outgoing        = true
    verify_incoming        = true
  }
  https {
    verify_incoming        = false
  }
  internal_rpc {
    verify_server_hostname = true
  }
}

auto_encrypt {
  tls = true
}

acl {
  enabled        = true
  default_policy = "deny"
  enable_token_persistence = true
}
EOF

##################
## Database
##################
SERVICE="hashicups-db"
NODE_NAME=${SERVICE}

header2 "Starting agent for ${SERVICE}"

log "Install Consul on ${SERVICE}"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "cp /opt/bin/consul /usr/local/bin/consul && chmod +x /usr/local/bin/consul"

log "Create Consul folders"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "mkdir -p /etc/consul/config && mkdir -p /etc/consul/data"

log "Create node specific configuration"

# consul acl token create -description "svc-${dc}-${svc} agent token" -node-identity "${ADDR}:${dc}" -service-identity="${svc}"  --format json > ${ASSETS}/acl-token-${ADDR}.json 2> /dev/null
# AGENT_TOK=`cat ${ASSETS}/acl-token-${ADDR}.json | jq -r ".SecretID"`

# Using root token for now
AGENT_TOKEN=`cat ${ASSETS}/acl-token-bootstrap.json | jq -r ".SecretID"`

tee ${ASSETS}/agent-client-${SERVICE}-acl-tokens.hcl > /dev/null << EOF
acl {
  tokens {
    agent  = "${AGENT_TOKEN}"
    default  = "${AGENT_TOKEN}"
  }
}
EOF


log "Create service configuration"

tee ${ASSETS}/svc-${SERVICE}.hcl > /dev/null << EOF
## svc-${SERVICE}.hcl
service {
  name = "${SERVICE}"
  id = "${SERVICE}-1"
  tags = ["v1"]
  port = 5432
  
  check {
    id =  "check-${SERVICE}",
    name = "Product ${SERVICE} status check",
    service_id = "${SERVICE}-1",
    tcp  = "localhost:5432",
    interval = "1s",
    timeout = "1s"
  }
}
EOF

log "Copy configuration files on ${SERVICE}"

scp -o ${SSH_OPTS} ${ASSETS}/agent-gossip-encryption.hcl             ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/agent-client-secure.hcl                 ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/consul-agent-ca.pem                     ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/consul-agent-ca.pem > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/agent-client-${SERVICE}-acl-tokens.hcl  ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/svc-${SERVICE}.hcl                      ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1

log "Starting Consul on ${SERVICE}"

CONSUL_PID=`ssh -o ${SSH_OPTS} ${SERVICE}${FQDN_SUFFIX} "pidof consul"`

until [ ! -z "${CONSUL_PID}" ] 

do
  log_warn "Consul not started yet...starting"

  ssh -o ${SSH_OPTS} ${SERVICE}${FQDN_SUFFIX} \
    "/usr/local/bin/consul agent \
    -node=${SERVICE} \
    -log-file=/tmp/consul-agent \
    -config-dir=/etc/consul/config > /tmp/consul-agent.log 2>&1" &

  sleep 1
  
  CONSUL_PID=`ssh -o StrictHostKeyChecking=accept-new ${SERVICE}${FQDN_SUFFIX} "pidof consul"`
done

##################
## API
##################

SERVICE="hashicups-api"
NODE_NAME=${SERVICE}

header2 "Starting agent for ${SERVICE}"

log "Install Consul on ${SERVICE}"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "cp /opt/bin/consul /usr/local/bin/consul && chmod +x /usr/local/bin/consul"

log "Create Consul folders"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "mkdir -p /etc/consul/config && mkdir -p /etc/consul/data"

log "Create node specific configuration"

# consul acl token create -description "svc-${dc}-${svc} agent token" -node-identity "${ADDR}:${dc}" -service-identity="${svc}"  --format json > ${ASSETS}/acl-token-${ADDR}.json 2> /dev/null
# AGENT_TOK=`cat ${ASSETS}/acl-token-${ADDR}.json | jq -r ".SecretID"`

# Using root token for now
AGENT_TOKEN=`cat ${ASSETS}/acl-token-bootstrap.json | jq -r ".SecretID"`

tee ${ASSETS}/agent-client-${SERVICE}-acl-tokens.hcl > /dev/null << EOF
acl {
  tokens {
    agent  = "${AGENT_TOKEN}"
    default  = "${AGENT_TOKEN}"
  }
}
EOF


log "Create service configuration"

tee ${ASSETS}/svc-${SERVICE}.hcl > /dev/null << EOF
## svc-${SERVICE}.hcl
service {
  name = "${SERVICE}"
  id = "${SERVICE}-1"
  tags = ["v1"]
  port = 8080
  
  checks =[ 
    {
      id =  "check-${SERVICE}",
      name = "Product ${SERVICE} status check",
      service_id = "${SERVICE}-1",
      tcp  = "${SERVICE}${FQDN_SUFFIX}:8081",
      interval = "1s",
      timeout = "1s"
    },
    {
      id =  "check-${SERVICE}-1",
      name = "Product ${SERVICE} status check 1",
      service_id = "${SERVICE}-1",
      tcp  = "${SERVICE}${FQDN_SUFFIX}:8080",
      interval = "1s",
      timeout = "1s"
    },
    {
      id =  "check-${SERVICE}-2",
      name = "Product ${SERVICE} status check 2",
      service_id = "${SERVICE}-1",
      tcp  = "${SERVICE}${FQDN_SUFFIX}:9090",
      interval = "1s",
      timeout = "1s"
    }
  ]
}
EOF

log "Copy configuration files on ${SERVICE}"

scp -o ${SSH_OPTS} ${ASSETS}/agent-gossip-encryption.hcl             ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/agent-client-secure.hcl                 ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/consul-agent-ca.pem                     ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/consul-agent-ca.pem > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/agent-client-${SERVICE}-acl-tokens.hcl  ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/svc-${SERVICE}.hcl                      ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1

log "Starting Consul on ${SERVICE}"

CONSUL_PID=`ssh -o ${SSH_OPTS} ${SERVICE}${FQDN_SUFFIX} "pidof consul"`

until [ ! -z "${CONSUL_PID}" ] 

do
  log_warn "Consul not started yet...starting"

  ssh -o ${SSH_OPTS} ${SERVICE}${FQDN_SUFFIX} \
    "/usr/local/bin/consul agent \
    -node=${SERVICE} \
    -log-file=/tmp/consul-agent \
    -config-dir=/etc/consul/config > /tmp/consul-agent.log 2>&1" &

  sleep 1
  
  CONSUL_PID=`ssh -o StrictHostKeyChecking=accept-new ${SERVICE}${FQDN_SUFFIX} "pidof consul"`
done

##################
## Frontend
##################
SERVICE="hashicups-frontend"
NODE_NAME=${SERVICE}

header2 "Starting agent for ${SERVICE}"

log "Install Consul on ${SERVICE}"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "cp /opt/bin/consul /usr/local/bin/consul && chmod +x /usr/local/bin/consul"

log "Create Consul folders"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "mkdir -p /etc/consul/config && mkdir -p /etc/consul/data"

log "Create node specific configuration"

# consul acl token create -description "svc-${dc}-${svc} agent token" -node-identity "${ADDR}:${dc}" -service-identity="${svc}"  --format json > ${ASSETS}/acl-token-${ADDR}.json 2> /dev/null
# AGENT_TOK=`cat ${ASSETS}/acl-token-${ADDR}.json | jq -r ".SecretID"`

# Using root token for now
AGENT_TOKEN=`cat ${ASSETS}/acl-token-bootstrap.json | jq -r ".SecretID"`

tee ${ASSETS}/agent-client-${SERVICE}-acl-tokens.hcl > /dev/null << EOF
acl {
  tokens {
    agent  = "${AGENT_TOKEN}"
    default  = "${AGENT_TOKEN}"
  }
}
EOF


log "Create service configuration"

tee ${ASSETS}/svc-${SERVICE}.hcl > /dev/null << EOF
## svc-${SERVICE}.hcl
service {
  name = "${SERVICE}"
  id = "${SERVICE}-1"
  tags = ["v1"]
  port = 3000
  
  check {
    id =  "check-${SERVICE}",
    name = "Product ${SERVICE} status check",
    service_id = "${SERVICE}-1",
    tcp  = "${SERVICE}${FQDN_SUFFIX}:3000",
    interval = "1s",
    timeout = "1s"
  }
}
EOF

log "Copy configuration files on ${SERVICE}"

scp -o ${SSH_OPTS} ${ASSETS}/agent-gossip-encryption.hcl             ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/agent-client-secure.hcl                 ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/consul-agent-ca.pem                     ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/consul-agent-ca.pem > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/agent-client-${SERVICE}-acl-tokens.hcl  ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/svc-${SERVICE}.hcl                      ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1

log "Starting Consul on ${SERVICE}"

CONSUL_PID=`ssh -o ${SSH_OPTS} ${SERVICE}${FQDN_SUFFIX} "pidof consul"`

until [ ! -z "${CONSUL_PID}" ] 

do
  log_warn "Consul not started yet...starting"

  ssh -o ${SSH_OPTS} ${SERVICE}${FQDN_SUFFIX} \
    "/usr/local/bin/consul agent \
    -node=${SERVICE} \
    -log-file=/tmp/consul-agent \
    -config-dir=/etc/consul/config > /tmp/consul-agent.log 2>&1" &

  sleep 1
  
  CONSUL_PID=`ssh -o StrictHostKeyChecking=accept-new ${SERVICE}${FQDN_SUFFIX} "pidof consul"`
done

##################
## NGINX
##################

SERVICE="hashicups-nginx"
NODE_NAME=${SERVICE}

header2 "Starting agent for ${SERVICE}"

log "Install Consul on ${SERVICE}"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "cp /opt/bin/consul /usr/local/bin/consul && chmod +x /usr/local/bin/consul"

log "Create Consul folders"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "mkdir -p /etc/consul/config && mkdir -p /etc/consul/data"

log "Create node specific configuration"

# consul acl token create -description "svc-${dc}-${svc} agent token" -node-identity "${ADDR}:${dc}" -service-identity="${svc}"  --format json > ${ASSETS}/acl-token-${ADDR}.json 2> /dev/null
# AGENT_TOK=`cat ${ASSETS}/acl-token-${ADDR}.json | jq -r ".SecretID"`

# Using root token for now
AGENT_TOKEN=`cat ${ASSETS}/acl-token-bootstrap.json | jq -r ".SecretID"`

tee ${ASSETS}/agent-client-${SERVICE}-acl-tokens.hcl > /dev/null << EOF
acl {
  tokens {
    agent  = "${AGENT_TOKEN}"
    default  = "${AGENT_TOKEN}"
  }
}
EOF


log "Create service configuration"

tee ${ASSETS}/svc-${SERVICE}.hcl > /dev/null << EOF
## svc-${SERVICE}.hcl
service {
  name = "${SERVICE}"
  id = "${SERVICE}-1"
  tags = ["v1"]
  port = 80
  
  check {
    id =  "check-${SERVICE}",
    name = "Product ${SERVICE} status check",
    service_id = "${SERVICE}-1",
    tcp  = "${SERVICE}${FQDN_SUFFIX}:80",
    interval = "1s",
    timeout = "1s"
  }
}
EOF

log "Copy configuration files on ${SERVICE}"

scp -o ${SSH_OPTS} ${ASSETS}/agent-gossip-encryption.hcl             ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/agent-client-secure.hcl                 ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/consul-agent-ca.pem                     ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/consul-agent-ca.pem > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/agent-client-${SERVICE}-acl-tokens.hcl  ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1
scp -o ${SSH_OPTS} ${ASSETS}/svc-${SERVICE}.hcl                      ${SERVICE}${FQDN_SUFFIX}:/etc/consul/config/ > /dev/null 2>&1

log "Starting Consul on ${SERVICE}"

CONSUL_PID=`ssh -o ${SSH_OPTS} ${SERVICE}${FQDN_SUFFIX} "pidof consul"`

until [ ! -z "${CONSUL_PID}" ] 

do
  log_warn "Consul not started yet...starting"

  ssh -o ${SSH_OPTS} ${SERVICE}${FQDN_SUFFIX} \
    "/usr/local/bin/consul agent \
    -node=${SERVICE} \
    -log-file=/tmp/consul-agent \
    -config-dir=/etc/consul/config > /tmp/consul-agent.log 2>&1" &

  sleep 1
  
  CONSUL_PID=`ssh -o StrictHostKeyChecking=accept-new ${SERVICE}${FQDN_SUFFIX} "pidof consul"`
done

## Query Service Catalog

