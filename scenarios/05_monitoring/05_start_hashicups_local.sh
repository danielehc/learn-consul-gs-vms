#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+


# ++-----------------+
# || Begin           |
# ++-----------------+

header1 "Starting Application"

header2 "Starting Database on localhost"

ssh -o ${SSH_OPTS} app@hashicups-db${FQDN_SUFFIX} \
      "bash -c '/start_database.sh local'"

sleep 2

header2 "Starting API on localhost"

ssh -o ${SSH_OPTS} app@hashicups-api${FQDN_SUFFIX} \
      "bash -c '/start_api.sh local'"

header2 "Starting Frontend on localhost"
set -x 
ssh -o ${SSH_OPTS} app@hashicups-frontend${FQDN_SUFFIX} \
      "bash -c '/start_frontend.sh local'"
set +x 
header2 "Starting Nginx"

ssh -o ${SSH_OPTS} app@hashicups-nginx${FQDN_SUFFIX} \
      "bash -c '/start_nginx.sh local'"
