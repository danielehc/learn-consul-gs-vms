ARG BASE_VERSION
ARG APP1_VERSION
ARG APP2_VERSION
ARG APP3_VERSION

FROM hashicorpdemoapp/public-api:${APP1_VERSION} as application1
FROM hashicorpdemoapp/product-api:${APP2_VERSION} as application2
FROM hashicorpdemoapp/payments:${APP3_VERSION} as application3

FROM danielehc/instruqt-base-consul:${BASE_VERSION}

RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive \
	apt-get --assume-yes install default-jre postgresql-client && \
	rm -rf /var/lib/apt/lists/*


# Install Public API
COPY --from=application1 app/public-api /bin/public-api

# Install Product API
COPY --from=application2 /app/product-api /bin/product-api
COPY wait.sh /bin/
COPY conf.json /home/app/conf.json

RUN chmod +x /bin/product-api && chmod +x /bin/wait.sh

# Install Payments
COPY --from=application3 spring-boot-payments-*.jar /bin/spring-boot-payments.jar

# Install startup script
COPY start_api.sh /home/app/start_api.sh
RUN  chmod +x /home/app/start_api.sh

EXPOSE 8080

# Start Payments
CMD ["/home/app/start_api.sh"]
