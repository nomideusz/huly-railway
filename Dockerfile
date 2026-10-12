# Huly's web front and seven backend services in one container, behind Caddy.
# Upstream huly-selfhost runs each as its own container behind nginx; on Railway
# that is 9 services that only ever talk to each other. Bump HULY in every FROM together.
FROM hardcoreeng/front:v0.7.426 AS front
FROM hardcoreeng/account:v0.7.426 AS account
FROM hardcoreeng/transactor:v0.7.426 AS transactor
FROM hardcoreeng/collaborator:v0.7.426 AS collaborator
FROM hardcoreeng/workspace:v0.7.426 AS workspace
FROM hardcoreeng/fulltext:v0.7.426 AS fulltext
FROM hardcoreeng/stats:v0.7.426 AS stats
FROM caddy:2.10.2 AS caddy

# rekoni is the base: it carries the apt tools (poppler, antiword, unrtf) it shells out to.
FROM hardcoreeng/rekoni-service:v0.7.426
COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY --from=front /app /opt/huly/front
COPY --from=account /usr/src/app /opt/huly/account
COPY --from=transactor /usr/src/app /opt/huly/transactor
COPY --from=collaborator /usr/src/app /opt/huly/collaborator
COPY --from=workspace /usr/src/app /opt/huly/workspace
COPY --from=fulltext /usr/src/app /opt/huly/fulltext
COPY --from=stats /usr/src/app /opt/huly/stats
RUN mv /usr/src/app /opt/huly/rekoni
COPY Caddyfile /etc/caddy/Caddyfile
COPY run.sh /usr/local/bin/run.sh
ENV HULY_VERSION=0.7.426
ENTRYPOINT []
CMD ["/bin/bash", "/usr/local/bin/run.sh"]
