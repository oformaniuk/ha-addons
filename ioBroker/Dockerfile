FROM buanet/iobroker:v11.1.0

ARG BUILD_VERSION=latest-v11

# copy over the patched iobroker_startup.sh
COPY iobroker_startup.sh /opt/scripts/iobroker_startup.sh
RUN chmod a+x /opt/scripts/iobroker_startup.sh

LABEL \
  io.hass.name="ioBroker" \
  io.hass.description="ioBroker using the official Docker image, persisting into addon_config" \
  io.hass.type="app" \
  io.hass.arch="armv7|aarch64|amd64" \
  io.hass.version="${BUILD_VERSION}"
