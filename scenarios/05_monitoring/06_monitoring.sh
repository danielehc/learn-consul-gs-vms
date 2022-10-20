#!/usr/bin/env bash

header1 "Configure nodes for monitoring"

## Download grafana-agent
## https://github.com/grafana/agent/releases

log "Coping grafana-agent binary on client nodes"

scp /assets/grafana-agent-linux-0.28.0-amd64 consul:/home/app/grafana-agent; \
scp /assets/grafana-agent-linux-0.28.0-amd64 hashicups-db:/home/app/grafana-agent; \
scp /assets/grafana-agent-linux-0.28.0-amd64 hashicups-api:/home/app/grafana-agent; \
scp /assets/grafana-agent-linux-0.28.0-amd64 hashicups-frontend:/home/app/grafana-agent; \
scp /assets/grafana-agent-linux-0.28.0-amd64 hashicups-nginx:/home/app/grafana-agent;

header2 "Create grafana-agent configuration files"

NODE="consul"

tee ${ASSETS}/grafana-agent-${NODE}.yaml > /dev/null << EOF
server:
  log_level: debug

metrics:
  global:
    scrape_interval: 60s
    remote_write:
    - url: http://mimir:9009/api/v1/push
  configs:
  - name: default
    scrape_configs:
    - job_name: consul-server
      metrics_path: '/v1/agent/metrics'
      static_configs:
        - targets: ['127.0.0.1:8500']

logs:
  configs:
  - name: default
    clients:
      - url: http://loki:3100/loki/api/v1/push
    positions:
      filename: /tmp/positions.yaml
    scrape_configs:
     - job_name: consul-server
       static_configs:
       - targets: 
           - localhost
         labels:
           job: logs
           host: ${NODE}
           __path__: /tmp/*.log
EOF

scp ${ASSETS}/grafana-agent-${NODE}.yaml ${NODE}:/home/app/grafana-agent.yaml;

NODE="hashicups-db"

tee ${ASSETS}/grafana-agent-${NODE}.yaml > /dev/null << EOF
server:
  log_level: debug

metrics:
  global:
    scrape_interval: 60s
    remote_write:
    - url: http://mimir:9009/api/v1/push
  configs:
  - name: default
    scrape_configs:
    - job_name: ${NODE}
      metrics_path: '/stats/prometheus'
      static_configs:
        - targets: ['127.0.0.1:19000']
    - job_name: consul-agent
      metrics_path: '/v1/agent/metrics'
      static_configs:
        - targets: ['127.0.0.1:8500']

logs:
  configs:
  - name: default
    clients:
      - url: http://loki:3100/loki/api/v1/push
    positions:
      filename: /tmp/positions.yaml
    scrape_configs:
     - job_name: service-mesh-apps
       static_configs:
       - targets: 
           - localhost
         labels:
           job: logs
           host: ${NODE}
           __path__: /tmp/*.log
EOF

scp ${ASSETS}/grafana-agent-${NODE}.yaml ${NODE}:/home/app/grafana-agent.yaml;

NODE="hashicups-api"

tee ${ASSETS}/grafana-agent-${NODE}.yaml > /dev/null << EOF
server:
  log_level: debug

metrics:
  global:
    scrape_interval: 60s
    remote_write:
    - url: http://mimir:9009/api/v1/push
  configs:
  - name: default
    scrape_configs:
    - job_name: ${NODE}
      metrics_path: '/stats/prometheus'
      static_configs:
        - targets: ['127.0.0.1:19000']
    - job_name: consul-agent
      metrics_path: '/v1/agent/metrics'
      static_configs:
        - targets: ['127.0.0.1:8500']

logs:
  configs:
  - name: default
    clients:
      - url: http://loki:3100/loki/api/v1/push
    positions:
      filename: /tmp/positions.yaml
    scrape_configs:
     - job_name: service-mesh-apps
       static_configs:
       - targets: 
           - localhost
         labels:
           job: logs
           host: ${NODE}
           __path__: /tmp/*.log

# traces:
#   configs:
#   - name: default
#     receivers:
#       jaeger:
#         protocols:
#           grpc: #(default endpoint = 0.0.0.0:14250)
#           thrift_http: #(default endpoint = 0.0.0.0:14268)
#             endpoint: 0.0.0.0:14271
#           thrift_binary: #(default endpoint = 0.0.0.0:6832)
#           thrift_compact: #(default endpoint = 0.0.0.0:6831)
#       zipkin: #(default endpoint = 0.0.0.0:9411)
#          endpoint: 0.0.0.0:5775
#       otlp:
#          protocols:
#            grpc:
#     remote_write:
#       - endpoint: jaeger:14250
#         insecure: true  # only add this if TLS is not required
#    batch:
#      timeout: 5s
#      send_batch_size: 100
EOF

scp ${ASSETS}/grafana-agent-${NODE}.yaml ${NODE}:/home/app/grafana-agent.yaml;

NODE="hashicups-frontend"

tee ${ASSETS}/grafana-agent-${NODE}.yaml > /dev/null << EOF
server:
  log_level: debug

metrics:
  global:
    scrape_interval: 60s
    remote_write:
    - url: http://mimir:9009/api/v1/push
  configs:
  - name: default
    scrape_configs:
    - job_name: ${NODE}
      metrics_path: '/stats/prometheus'
      static_configs:
        - targets: ['127.0.0.1:19000']
    - job_name: consul-agent
      metrics_path: '/v1/agent/metrics'
      static_configs:
        - targets: ['127.0.0.1:8500']

logs:
  configs:
  - name: default
    clients:
      - url: http://loki:3100/loki/api/v1/push
    positions:
      filename: /tmp/positions.yaml
    scrape_configs:
     - job_name: service-mesh-apps
       static_configs:
       - targets: 
           - localhost
         labels:
           job: logs
           host: ${NODE}
           __path__: /tmp/*.log
EOF

scp ${ASSETS}/grafana-agent-${NODE}.yaml ${NODE}:/home/app/grafana-agent.yaml;

NODE="hashicups-nginx"

tee ${ASSETS}/grafana-agent-${NODE}.yaml > /dev/null << EOF
server:
  log_level: debug

metrics:
  global:
    scrape_interval: 60s
    remote_write:
    - url: http://mimir:9009/api/v1/push
  configs:
  - name: default
    scrape_configs:
    - job_name: ${NODE}
      metrics_path: '/stats/prometheus'
      static_configs:
        - targets: ['127.0.0.1:19000']
    - job_name: consul-agent
      metrics_path: '/v1/agent/metrics'
      static_configs:
        - targets: ['127.0.0.1:8500']

logs:
  configs:
  - name: default
    clients:
      - url: http://loki:3100/loki/api/v1/push
    positions:
      filename: /tmp/positions.yaml
    scrape_configs:
     - job_name: service-mesh-apps
       static_configs:
       - targets: 
           - localhost
         labels:
           job: logs
           host: ${NODE}
           __path__: /tmp/*.log
EOF

scp ${ASSETS}/grafana-agent-${NODE}.yaml ${NODE}:/home/app/grafana-agent.yaml;

header2 "Start grafana-agent on nodes"

set -x

ssh -o ${SSH_OPTS} app@consul${FQDN_SUFFIX} \
    "bash -c '/home/app/grafana-agent -config.file /home/app/grafana-agent.yaml > /tmp/grafana-agent.log 2>&1'" &

sleep 1


ssh -o ${SSH_OPTS} app@hashicups-db${FQDN_SUFFIX} \
    "bash -c '/home/app/grafana-agent -config.file /home/app/grafana-agent.yaml > /tmp/grafana-agent.log 2>&1'" &

sleep 1

ssh -o ${SSH_OPTS} app@hashicups-api${FQDN_SUFFIX} \
    "bash -c '/home/app/grafana-agent -config.file /home/app/grafana-agent.yaml > /tmp/grafana-agent.log 2>&1'" &

sleep 1

ssh -o ${SSH_OPTS} app@hashicups-frontend${FQDN_SUFFIX} \
    "bash -c '/home/app/grafana-agent -config.file /home/app/grafana-agent.yaml > /tmp/grafana-agent.log 2>&1'" &

sleep 1

ssh -o ${SSH_OPTS} app@hashicups-nginx${FQDN_SUFFIX} \
    "bash -c '/home/app/grafana-agent -config.file /home/app/grafana-agent.yaml > /tmp/grafana-agent.log 2>&1'" &

sleep 1

set +x

# exit 0

## Configure Consul server for prometheus
# log "Generating Consul server telemetry config"

# tee ${ASSETS}/agent-server-telemetry.hcl > /dev/null << EOF
# telemetry {
#   prometheus_retention_time = "60s"
#   disable_hostname = true
# }
# EOF

# scp -o ${SSH_OPTS} agent-server-telemetry.hcl                   consul${FQDN_SUFFIX}:/etc/consul/config > /dev/null 2>&1

# ssh -o ${SSH_OPTS} consul${FQDN_SUFFIX} \
#     "/usr/local/bin/consul reload >> /tmp/consul-server.log 2>&1" &

