# Home Assistant Add-ons

Home Assistant add-on repository for custom add-ons.

## Add-ons

### Codex CLI

AI coding agent for editing Home Assistant configuration with Codex CLI, ttyd,
MCP integration, LSP helpers, and persistent sessions.

### ioBroker

ioBroker using the official Docker image, persisting into add-on config.

### HomePod MQTT Bridge

Receives HomePod sensor data and forwards it to Home Assistant webhooks. Add
the HomePod names and webhook GUIDs in the add-on Configuration tab.

## Development

Each add-on lives in its own folder and contains at least:

- `config.yaml` for Supervisor metadata and options
- `Dockerfile` for the container image
- startup scripts and runtime files needed by the container

For local testing, place this repository under the Home Assistant `/addons`
directory or add the published repository URL in the Home Assistant add-on store.

## References

- [Home Assistant app repository documentation](https://developers.home-assistant.io/docs/add-ons/repository/)
- [Home Assistant app configuration documentation](https://developers.home-assistant.io/docs/apps/configuration/)
