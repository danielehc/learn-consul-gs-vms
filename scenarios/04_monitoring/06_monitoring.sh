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

header2 "Create grafana-agent configuration script"

tee /home/app/generate_consul_monitoring_config.sh << 'EOFS'
#!/usr/bin/env bash

echo "Generating Grafana Agent configuration"

mkdir grafana_agent_configs

pushd grafana_agent_configs

ASSETS="./"

NODE="consul-server"

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
EOF

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

logs:/home/app/grafana-agent -config.file /home/app/grafana-agent.yaml
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

popd
EOFS

chown app: /home/app/generate_consul_monitoring_config.sh
chmod +x /home/app/generate_consul_monitoring_config.sh



