#!/bin/bash

# if [ ! -z `pidof nginx` ]; then kill -9 `pidof nginx`; fi

if [ ! -z `pidof nginx` ]; then killall nginx; fi



## Check Parameters
if   [ "$1" == "local" ]; then

    echo "Starting service on local insterface"

    tee /etc/nginx/conf.d/def_upstreams.conf << EOF
upstream frontend_upstream {
    server localhost:3000;
}

upstream api_upstream {
    server localhost:8081;
}
EOF

else

    echo "Starting service on global insterface"

fi

/usr/sbin/nginx & 