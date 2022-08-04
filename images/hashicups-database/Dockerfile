ARG BASE_VERSION
ARG APP_VERSION

FROM postgres:latest as pgres
# FROM hashicorpdemoapp/product-api-db:${APP_VERSION} as base

FROM danielehc/instruqt-base-consul:${BASE_VERSION} 


RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive \
	apt-get --assume-yes install postgresql postgresql-client postgresql-contrib && \
	rm -rf /var/lib/apt/lists/*

RUN mkdir /docker-entrypoint-initdb.d

COPY --from=pgres /usr/local/bin/docker-entrypoint.sh /usr/local/bin/

COPY products.sql /docker-entrypoint-initdb.d/
COPY pg_hba.conf /home/app

RUN mkdir -p /var/run/postgresql && chown -R 1000:1000 /var/run/postgresql && chmod 2777 /var/run/postgresql

ENV PGDATA /var/lib/postgresql/data
# ENV POSTGRES_HOST_AUTH_METHOD trust
ENV POSTGRES_DB products
ENV POSTGRES_USER postgres
ENV POSTGRES_PASSWORD password
# # this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)
RUN mkdir -p "$PGDATA" && \
    chown -R 1000:1000 "$PGDATA" && \
    chmod 777 "$PGDATA" && \
    chown -R 1000:1000 /var/lib/postgresql && \
    chown -R 1000:1000 /etc/postgresql
    

COPY start_database.sh /start_database.sh
RUN  chmod +x /start_database.sh

STOPSIGNAL SIGINT

EXPOSE 5432

# The appliucation will be started manually ar runtime
# CMD ["docker-entrypoint.sh", "postgres"]



# CMD ["postgres", "--version"]