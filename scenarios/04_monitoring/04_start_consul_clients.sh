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

verify_incoming        = false
verify_incoming_rpc    = true
verify_outgoing        = true
verify_server_hostname = true

ca_file = "/etc/consul/config/consul-agent-ca.pem"

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
SERVICE="db"
NODE_NAME=${SERVICE}

header2 "Starting agent for ${SERVICE}"

log "Install Consul on ${SERVICE}"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "cp /opt/bin/consul /usr/local/bin/consul && chmod +x /usr/local/bin/consul"

log "Install Envoy on ${SERVICE}"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "cp /opt/bin/envoy /usr/local/bin/envoy && chmod +x /usr/local/bin/envoy"

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
  
  connect {
    sidecar_service {}
  }  
  
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

log "Start sidecar proxy for ${SERVICE}"
TOK=${AGENT_TOKEN}

set -x

ssh -o ${SSH_OPTS} ${SERVICE}${FQDN_SUFFIX} \
  "/usr/local/bin/consul connect envoy -token=${TOK} -envoy-binary /usr/local/bin/envoy -sidecar-for ${SERVICE}-1 -admin-bind 0.0.0.0:21000 -- -l debug > /tmp/sidecar-proxy.log 2>&1 &"

set +x 

##################
## API
##################

SERVICE="api"
NODE_NAME=${SERVICE}

header2 "Starting agent for ${SERVICE}"

log "Install Consul on ${SERVICE}"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "cp /opt/bin/consul /usr/local/bin/consul && chmod +x /usr/local/bin/consul"

log "Install Envoy on ${SERVICE}"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "cp /opt/bin/envoy /usr/local/bin/envoy && chmod +x /usr/local/bin/envoy"

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
  
  connect {
    sidecar_service {
      proxy {
        upstreams = [
          {
            destination_name = "db"
            local_bind_port = 5432
          }
        ]
      }
    }
  }

  checks =[ 
    {
      id =  "check-${SERVICE}",
      name = "Product ${SERVICE} status check",
      service_id = "${SERVICE}-1",
      tcp  = "localhost:8081",
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

log "Start sidecar proxy for ${SERVICE}"
TOK=${AGENT_TOKEN}

ssh -o ${SSH_OPTS} ${SERVICE}${FQDN_SUFFIX} \
  "/usr/local/bin/consul connect envoy -token=${TOK} -envoy-binary /usr/local/bin/envoy -sidecar-for ${SERVICE}-1 -admin-bind 0.0.0.0:21000 -- -l debug > /tmp/sidecar-proxy.log 2>&1 &"

##################
## Frontend
##################
SERVICE="frontend"
NODE_NAME=${SERVICE}

header2 "Starting agent for ${SERVICE}"

log "Install Consul on ${SERVICE}"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "cp /opt/bin/consul /usr/local/bin/consul && chmod +x /usr/local/bin/consul"

log "Install Envoy on ${SERVICE}"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "cp /opt/bin/envoy /usr/local/bin/envoy && chmod +x /usr/local/bin/envoy"

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
  
  connect {
    sidecar_service {
      proxy {
        upstreams = [
          {
            destination_name = "api"
            local_bind_port = 8081
          }
        ]
      }
    }
  }

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

log "Start sidecar proxy for ${SERVICE}"
TOK=${AGENT_TOKEN}

ssh -o ${SSH_OPTS} ${SERVICE}${FQDN_SUFFIX} \
  "/usr/local/bin/consul connect envoy -token=${TOK} -envoy-binary /usr/local/bin/envoy -sidecar-for ${SERVICE}-1 -admin-bind 0.0.0.0:21000 -- -l debug > /tmp/sidecar-proxy.log 2>&1 &"

##################
## NGINX
##################

SERVICE="nginx"
NODE_NAME=${SERVICE}

header2 "Starting agent for ${SERVICE}"

log "Install Consul on ${SERVICE}"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "cp /opt/bin/consul /usr/local/bin/consul && chmod +x /usr/local/bin/consul"

log "Install Envoy on ${SERVICE}"
ssh -o ${SSH_OPTS} app@${SERVICE}${FQDN_SUFFIX} \
      "cp /opt/bin/envoy /usr/local/bin/envoy && chmod +x /usr/local/bin/envoy"

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
  
  connect {
    sidecar_service {
      proxy {
        upstreams = [
          {
            destination_name = "frontend"
            local_bind_port = 3000
          }
        ]
      }
    }
  }

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

log "Start sidecar proxy for ${SERVICE}"
TOK=${AGENT_TOKEN}

ssh -o ${SSH_OPTS} ${SERVICE}${FQDN_SUFFIX} \
  "/usr/local/bin/consul connect envoy -token=${TOK} -envoy-binary /usr/local/bin/envoy -sidecar-for ${SERVICE}-1 -admin-bind 0.0.0.0:21000 -- -l debug > /tmp/sidecar-proxy.log 2>&1 &"

## Query Service Catalog

