#!/bin/sh

export PGDATA="/var/lib/postgresql/data"
export POSTGRES_DB="products"
export POSTGRES_USER="postgres"
export POSTGRES_PASSWORD="password"
# Get latest Postgres version installed
PSQL_VERSION=`ls /usr/lib/postgresql -1 | sort -r | head`

PATH=$PATH:/usr/lib/postgresql/${PSQL_VERSION}/bin


/usr/local/bin/docker-entrypoint.sh postgres > /tmp/database.log 2>&1 &

sleep 15

killall postgres >> /tmp/database.log 2>&1 &

# cp /home/app/pg_hba.conf /etc/postgresql/${PSQL_VERSION}/main/pg_hba.conf
cp /home/app/pg_hba.conf ${PGDATA}/pg_hba.conf

# printf "\n listen_addresses = 'localhost' \n" >> /etc/postgresql/${PSQL_VERSION}/main/conf.d/listen_address.conf
printf "\n listen_addresses = '*' \n" >> ${PGDATA}/postgresql.conf

/usr/local/bin/docker-entrypoint.sh postgres > /tmp/database.log 2>&1 &