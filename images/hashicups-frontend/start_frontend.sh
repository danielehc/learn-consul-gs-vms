#!/bin/bash




# export NEXT_PUBLIC_PUBLIC_API_URL=http://api:8081
export NEXT_PUBLIC_PUBLIC_API_URL=/
# export NEXT_PUBLIC_PUBLIC_API_URL=http://api:8081

echo "Checking for NEXT_PUBLIC_PUBLIC_API_URL env var"
test -n "$NEXT_PUBLIC_PUBLIC_API_URL"

find /app/.next \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s#APP_NEXT_PUBLIC_API_URL#$NEXT_PUBLIC_PUBLIC_API_URL#g"

echo "Checking for NEXT_PUBLIC_FOOTER_FLAG env var"
test -n "$NEXT_PUBLIC_FOOTER_FLAG"

find /app/.next \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s#APP_PUBLIC_FOOTER_FLAG#$NEXT_PUBLIC_FOOTER_FLAG#g"

echo "Starting HashiCups Frontend"
# exec "/app/node_modules/.bin/next start"
# pushd /app > /dev/null 2>&1

cd /app

## Check Parameters
if   [ "$1" == "local" ]; then

    echo "Starting service on local insterface"

    /app/node_modules/.bin/next start > /tmp/frontend.log 2>&1 &

else

    echo "Starting service on global insterface"

    /app/node_modules/.bin/next start --hostname "127.0.0.1" > /tmp/frontend.log 2>&1 &

fi

