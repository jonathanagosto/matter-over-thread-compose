FROM openthread/border-router:latest

LABEL org.opencontainers.image.authors="Jonathan L. Agosto Cruz <hello@jonathanagosto.com>"
LABEL org.opencontainers.image.description="Containerized matter-over-thread setup for remote antennas."
LABEL org.opencontainers.image.url="https://github.com/jonathanagosto/matter-over-thread-compose"
LABEL org.opencontainers.image.source="https://github.com/jonathanagosto/matter-over-thread-compose"
LABEL org.opencontainers.image.version="main"

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Utc/UTC
ENV OT_INFRA_IF=wlan0
ENV OT_LOG_LEVEL=2
ENV OT_THREAD_IF=wpan0
ENV ANTENNA_ADDRESS=
ENV ANTENNA_PORT=
ENV ANTENNA_BAUD_RATE=460800
ENV OT_RCP_DEVICE=spinel+hdlc+uart:///tmp/ttyAntenna0?uart-baudrate=$ANTENNA_BAUD_RATE

RUN apt-get update \
    && apt-get install --no-install-recommends -qq -y socat \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# Configure log rotation
RUN mkdir -p /etc/docker/ \
    && printf '{"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"3"}}' > /etc/docker/daemon.json

# Create TTY device for the antenna
RUN printf '#!/bin/sh\nset -e\nnohup socat -d -d pty,link=/tmp/ttyAntenna0,raw,echo=0,isig=0 tcp:$ANTENNA_ADDRESS:$ANTENNA_PORT,forever,interval=10,nodelay > /dev/null 2>&1 &\nexec /init "$@"' > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]