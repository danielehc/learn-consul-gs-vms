#!/bin/bash

killall nginx 2>&1 &

sleep 1

## Check Parameters
if   [ "$1" == "local" ]; then

    echo "Starting service on local interface."

    tee /etc/nginx/conf.d/def_upstreams.conf << EOF
upstream frontend_upstream {
    server localhost:3000;
}

upstream api_upstream {
    server localhost:8081;
}
EOF

else

    echo "Starting service on global interface."

fi

/usr/sbin/nginx & 