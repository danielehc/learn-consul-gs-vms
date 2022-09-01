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
      "bash -c /start_database.sh local"

header2 "Starting API"

ssh -o ${SSH_OPTS} app@hashicups-api${FQDN_SUFFIX} \
      "bash -c /start_api.sh local"

header2 "Starting Frontend"
set -x 
ssh -o ${SSH_OPTS} app@hashicups-frontend${FQDN_SUFFIX} \
      "bash -c /start_frontend.sh local"
set +x 
header2 "Starting Nginx"

ssh -o ${SSH_OPTS} app@hashicups-nginx${FQDN_SUFFIX} \
      "bash -c /start_nginx.sh local"
