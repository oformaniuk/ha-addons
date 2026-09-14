# Changelog

## 0.154.0

- Pins Codex CLI to version `0.154.0` so Home Assistant can detect and offer Codex updates.

## 0.6.8

- Adds `armhf` and `armv7` add-on architectures and maps ARM builds to matching Go and `ttyd` release targets.

## 0.6.7

- Installs `python3-yaml` so `ha-validate` and Python-based YAML checks can import the `yaml` module.

## 0.6.6

- Configures `nano` as the default `EDITOR`, `VISUAL`, `GIT_EDITOR`, and `SUDO_EDITOR` for Codex and shell sessions.

## 0.6.5

- Launches Codex with `--dangerously-bypass-approvals-and-sandbox` from the web UI, `ai` helper, and interactive shell function to avoid bubblewrap in Home Assistant add-on containers.

## 0.3.3

- Changes the default Codex sandbox mode to `danger-full-access` because Home Assistant add-on containers commonly cannot run bubblewrap mount operations used by `workspace-write`.

## 0.3.2

- Maps the Home Assistant configuration directory into the add-on at `/homeassistant` with read/write access.

## 0.3.1

- Replaces the raw `custom_model_providers` TOML text field with structured provider settings so Home Assistant does not flatten multi-line provider tables into invalid one-line TOML.

## 0.3.0

- Adds `codex_model_provider` to explicitly write `model_provider` in generated Codex config. Leave it empty to omit the setting.
- Adds structured `custom_model_providers` settings so custom providers render as valid TOML without relying on multi-line text input.

## 0.1.2

- Adds full Configuration tab metadata and documentation.
- Adds the `ai` shortcut for opening or reattaching the persistent Codex session.
- Simplifies the options schema for Supervisor compatibility.
- Includes bubblewrap for tools that can use process/filesystem sandboxing.

## 0.1.0

- Initial Codex + ttyd Home Assistant add-on package.
- Uses dtach for persistent sessions without tmux.
- Adds optional SSH, helper commands, minimal MCP server, and YAML LSP wrapper.
