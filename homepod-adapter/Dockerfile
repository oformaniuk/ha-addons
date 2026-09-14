FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_ARCH
WORKDIR /src

COPY app/HomeAssistantCompanion.csproj ./app/
RUN dotnet restore app/HomeAssistantCompanion.csproj

COPY app/ ./app/
WORKDIR /src/app
RUN case "$BUILD_ARCH" in \
      aarch64) runtime_identifier=linux-arm64 ;; \
      amd64) runtime_identifier=linux-x64 ;; \
      *) echo "Unsupported BUILD_ARCH: $BUILD_ARCH" >&2; exit 1 ;; \
    esac \
 && dotnet publish HomeAssistantCompanion.csproj \
      --configuration Release \
      --runtime "$runtime_identifier" \
      --self-contained true \
      --output /out \
      /p:PublishSingleFile=true \
      /p:PublishTrimmed=false

FROM ghcr.io/home-assistant/base-debian:bookworm
ARG BUILD_VERSION
WORKDIR /app
COPY --from=build /out/HomeAssistantCompanion /usr/local/bin/homepod-adapter
COPY rootfs /
RUN chmod +x /usr/local/bin/homepod-adapter \
 && chmod +x /etc/s6-overlay/s6-rc.d/homepod-adapter/run

EXPOSE 8080

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="app" \
  io.hass.arch="aarch64|amd64"
