#!/usr/bin/env bash

# ++-----------------+
# || Variables       |
# ++-----------------+


# ++-----------------+
# || Begin           |
# ++-----------------+

header1 "Starting Application"

header2 "Starting Database"

ssh -o ${SSH_OPTS} app@db${FQDN_SUFFIX} \
      "bash -c /start_database.sh"

header2 "Starting API"

ssh -o ${SSH_OPTS} app@api${FQDN_SUFFIX} \
      "bash -c /start_api.sh"


header2 "Starting Frontend"

header2 "Starting Nginx"
