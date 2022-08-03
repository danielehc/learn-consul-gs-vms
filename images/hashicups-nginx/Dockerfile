ARG BASE_VERSION

FROM danielehc/instruqt-base-consul:${BASE_VERSION} 

RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive \
	apt-get --assume-yes install nginx && \
	rm -rf /var/lib/apt/lists/*

# RUN mkdir -p /usr/share/nginx/html && chown -R 1000:1000 /usr/share/nginx/html

# COPY --from=base /usr/share/nginx/html /usr/share/nginx/html

RUN setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx

RUN mkdir -p /run/nginx && touch /run/nginx/nginx.pid && chown -R 1000:1000 /run/nginx && chown -R 1000:1000 /var/run/nginx
RUN mkdir /var/cache/nginx && chown -R 1000:1000 /var/cache/nginx


RUN mkdir -p /etc/nginx
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

RUN chown -R 1000:1000 /etc/nginx
RUN chown -R 1000:1000 /usr/share/nginx/html

RUN mkdir -p /var/log/nginx && chown -R 1000:1000 /var/log/nginx
RUN mkdir -p /var/lib/nginx && chown -R 1000:1000 /var/lib/nginx

EXPOSE 80

# CMD ["nginx", "-g", "daemon off;"]