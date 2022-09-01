
# ARG ENVOY_VERSION

FROM filebrowser/filebrowser:latest AS filebrowser
# FROM envoyproxy/envoy:${ENVOY_VERSION} AS envoy-bin


FROM debian:latest

# COPY --from=envoy-bin /usr/local/bin/envoy /usr/local/bin/envoy
# COPY --from=consul-bin /bin/consul /usr/local/bin/consul
# COPY --from=vault-bin /bin/vault /usr/local/bin/vault
# COPY --from=application /app/fake-service /usr/local/bin/fake-service
# COPY --from=envoy-bin /usr/local/bin/envoy /usr/local/bin/envoy
COPY --from=filebrowser /filebrowser /usr/local/bin/filebrowser

# https://stackoverflow.com/questions/66963068/docker-alpine-executable-binary-not-found-even-if-in-path
# https://www.gitmemory.com/issue/sgerrand/alpine-pkg-glibc/154/851078836
# RUN rm /usr/glibc-compat/lib/ld-linux-x86-64.so.2 && /usr/glibc-compat/sbin/ldconfig

RUN apt-get update

## Install `setcap` for binary capabilities
## Install `tini` as init process
RUN DEBIAN_FRONTEND=noninteractive \
	apt-get --assume-yes install bash bash-completion lsb-release \
								vim curl wget dnsutils jq iputils-ping tree \
								procps net-tools\
								openssl dropbear openssh-client gnupg \
								libcap2-bin \
								tini && \
	rm -rf /var/lib/apt/lists/*

# Add repositories
# HashiCorp repository
RUN curl --fail --silent --show-error --location https://apt.releases.hashicorp.com/gpg | \
		gpg --dearmor | \
		dd of=/usr/share/keyrings/hashicorp-archive-keyring.gpg

RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
		tee -a /etc/apt/sources.list.d/hashicorp.list

RUN mkdir -p /etc/dropbear
RUN chown -R 1000:1000 /etc/dropbear

# Set prompt and aliases
## Tring out icons 💻 🐳 👾 🔥 🐧 🍥 🍄 💀 👤 👊 👉 ⭕ 🔷 🔵
ENV TERM=xterm
ENV PS1='🔵:\[\033[1;36m\]\u@\h: \[\033[1;34m\]\w\[\033[0;35m\] \[\033[1;36m\]\$ \[\033[0m\]'

COPY ./bash.aliases /etc/bash.aliases
RUN printf "\n source /etc/bash.aliases \n" >> /etc/bash.bashrc

## Give binaries the capability to run on privileged ports without using root
# RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/consul
# RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/fake-service
RUN setcap 'cap_net_bind_service=+ep' /usr/sbin/dropbear
RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/filebrowser

## Add user wuth UID and GID 1000
	# -p "$(openssl passwd -1 app)" \
RUN addgroup --gid 1000 app && \
	adduser \
	--disabled-password \
	--shell "/bin/bash" \
	--home "/home/app" \
	--uid 1000 \
	--gid 1000 \
	--gecos '' \
	"app"

RUN printf "\n source /etc/bash.aliases \n" >> /home/app/.bashrc

## Set users password
RUN echo app:app | chpasswd
RUN echo root:toor | chpasswd

## The image needs a cert-key pair to enable SSH automatically
## generate it with `ssh-keygen -t rsa -b 4096`
COPY ./ssh/id_rsa.pub /etc/dropbear/authorized_keys
COPY ./ssh/id_rsa.pub /home/app/.ssh/authorized_keys
COPY ./ssh/id_rsa.pub /root/.ssh/authorized_keys

COPY ./ssh/id_rsa.pub /home/app/.ssh
COPY ./ssh/id_rsa /home/app/.ssh
COPY ./ssh/id_rsa.pub /root/.ssh
COPY ./ssh/id_rsa /root/.ssh
RUN chown -R 1000:1000 /home/app/.ssh

COPY ./filebrowser.json /.filebrowser.json
RUN chown -R 1000:1000 /.filebrowser.json
RUN touch /database.db && chown -R 1000:1000 /database.db

# RUN echo 'alias ssh="dbclient"' >> /home/app/.bashrc

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]

CMD ["/entrypoint.sh"]