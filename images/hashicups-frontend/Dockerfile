ARG BASE_VERSION
ARG APP_VERSION

FROM hashicorpdemoapp/frontend:${APP_VERSION} as application
# FROM im2nguyenhashi/hashicups-frontend:latest as application
FROM danielehc/instruqt-base-consul:${BASE_VERSION} 

RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive \
	apt-get --assume-yes install nodejs && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ENV NODE_ENV production
# ENV NEXT_PUBLIC_PUBLIC_API_URL http://api:8081
ENV NEXT_PUBLIC_PUBLIC_API_URL /
# Uncomment the following line in case you want to disable telemetry during runtime.
# ENV NEXT_TELEMETRY_DISABLED 1

# RUN addgroup --system --gid 1001 nodejs
# RUN adduser --system --uid 1001 nextjs

# You only need to copy next.config.js if you are NOT using the default configuration
# COPY --from=builder /app/next.config.js ./
COPY --from=application /app/public ./public
COPY --from=application /app/.next ./.next
COPY --from=application /app/node_modules ./node_modules
COPY --from=application /app/package.json ./package.json

RUN chown -R 1000:1000 /app

# COPY --from=application /app/entrypoint.sh ./entrypoint.sh
COPY start_frontend.sh /start_frontend.sh
RUN  chmod +x /start_frontend.sh

USER app

EXPOSE 3000

ENV PORT 3000

# The appliucation will be started manually ar runtime
# CMD ["/app/start_frontend.sh"]