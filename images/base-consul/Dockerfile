ARG CONSUL_VERSION
ARG ENVOY_VERSION
ARG BASE_VERSION


# FROM envoyproxy/envoy:${ENVOY_VERSION} as envoy-bin
FROM consul:${CONSUL_VERSION} as consul-bin
FROM envoyproxy/envoy-alpine:${ENVOY_VERSION} as envoy-bin


FROM filebrowser/filebrowser:latest AS filebrowser
# FROM envoyproxy/envoy:${ENVOY_VERSION} AS envoy-bin

# FROM debian:latest
FROM danielehc/instruqt-base:${BASE_VERSION}

RUN mkdir -p /opt/bin

COPY --from=envoy-bin /usr/local/bin/envoy /opt/bin/envoy
COPY --from=consul-bin /bin/consul /opt/bin/consul

## Give binaries the capability to run on privileged ports without using root
RUN setcap 'cap_net_bind_service=+ep' /opt/bin/consul

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]

CMD ["/entrypoint.sh"]