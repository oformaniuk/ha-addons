# Codex for Home Assistant

This add-on is a Codex CLI variant of the OpenCode Home Assistant add-on pattern:

- Home Assistant sidebar access through `ttyd` on ingress port `8099`
- Persistent terminal sessions through `dtach`, not `tmux`
- `/homeassistant` mounted read/write
- Supervisor and Home Assistant API access enabled
- Helper commands for logs, MCP status, and validation
- Optional SSH access to the same persistent session
- Minimal Home Assistant MCP server for entity states, services, templates, logs, safe config file reads/writes, and `hab` gateway calls
- YAML LSP wrapper installed for future editor/client integrations
- `nano` configured as the default terminal editor for Codex and shell workflows

## First run

Open **Codex** from the Home Assistant sidebar. The terminal starts in `/homeassistant` and attaches to the persistent `codex-main` session.

Run:

```bash
codex login
ai
```

If you already have `auth.json`, you can copy it into `/data/.codex/auth.json` inside the add-on. Treat that file like a password.

## Configuration

Configure the add-on from the **Configuration** tab in the add-on page. Save changes and restart the add-on for them to apply.

### Feature Options

| Option | Default | Description |
| --- | --- | --- |
| **Enable MCP Home Assistant Integration** | `true` | Enables the Codex MCP server for Home Assistant states, services, templates, logs, validated config file reads/writes, and `hab` gateway calls. |
| **Enable LSP Home Assistant Integration** | `true` | Enables the Home Assistant-aware YAML language helper. This is installed for editor/client integrations and future terminal workflows. |
| **UI mode** | `tui` | `tui` opens the persistent Codex session. `shell` opens a persistent login shell. Both use `dtach` so reconnects land in the same session. |

### Terminal Appearance

| Option | Default | Description |
| --- | --- | --- |
| **Terminal theme** | `breeze` | Color scheme for the browser terminal. Options: `breeze`, `catppuccin_mocha`, `catppuccin_latte`, `dracula`, `nord`, `tokyo_night`, `one_dark`, `solarized_dark`, `solarized_light`, `gruvbox_dark`. |
| **Font size** | `14` | Terminal font size in pixels. Valid range: 10-24. |
| **Cursor style** | `block` | Cursor shape: `block`, `underline`, or `bar`. |
| **Blinking cursor** | `false` | Whether the terminal cursor should blink. |

### Codex Defaults

| Option | Default | Description |
| --- | --- | --- |
| **Codex model** | `""` | Optional default model written to `/data/.codex/config.toml`. Leave empty to use the Codex CLI default. |
| **Codex model provider** | `""` | Optional provider name written as `model_provider` in `/data/.codex/config.toml`. Leave empty to omit the setting. |
| **Custom model providers** | `[]` | Structured provider definitions rendered as `[model_providers.<provider>]` TOML tables. Use this instead of pasting provider TOML into the extra config field. |
| **Codex approval policy** | `on-request` | Controls when Codex asks for approval. Options: `untrusted`, `on-request`, `never`. |
| **Codex sandbox mode** | `danger-full-access` | Controls Codex sandboxing. Options: `read-only`, `workspace-write`, `danger-full-access`. Home Assistant add-on containers commonly cannot run bubblewrap, so `workspace-write` can fail with `bwrap: Failed to make / slave: Permission denied`. |
| **Codex default permissions** | `:workspace` | Default permission preset written to Codex config. |
| **Extra Codex config TOML** | `""` | Advanced TOML appended verbatim to `/data/.codex/config.toml` after generated settings. Avoid using this for multi-line provider tables in the Home Assistant UI; use **Custom model providers** instead. |

#### Custom Model Provider Example

```yaml
codex_model_provider: "codex-lb"
custom_model_providers:
  - provider: "codex-lb"
    name: "OpenAI"
    base_url: "https://example.com/backend-api/codex"
    wire_api: "responses"
    env_key: "OPENAI_API_KEY"
    supports_websockets: true
    requires_openai_auth: true
```

### Access And Environment

| Option | Default | Description |
| --- | --- | --- |
| **Home Assistant long-lived access token** | `""` | Optional token exposed as `HA_ACCESS_TOKEN` for tools that need direct Home Assistant Core API access beyond the Supervisor token. |
| **Environment variables** | `[]` | Custom environment variables exposed to Codex and terminal shells. Protected system variables such as `HOME`, `PATH`, `SUPERVISOR_TOKEN`, and `CODEX_HOME` are ignored. |
| **Enable SSH** | `false` | Enables optional direct SSH access on port `2222`. |
| **SSH public key** | `""` | Public key for the `codex` SSH user. Preferred over password authentication. |
| **SSH password** | `""` | Optional password for the `codex` SSH user. Leave empty to disable password login. |

#### Environment Variables Example

Add entries in the Configuration tab:

| Name | Value |
| --- | --- |
| `OPENAI_API_KEY` | `sk-...` |
| `AZURE_RESOURCE_NAME` | `my-azure-resource` |

After saving and restarting the add-on, these variables are available in the terminal and to Codex. Environment variables are written to `/data/.env_vars`, excluded from Home Assistant backups, and visible in the add-on Configuration tab.

## Persistence without tmux

This add-on uses:

```bash
dtach -A /data/sessions/codex-main.sock -r winch /usr/local/bin/codex-wrapper
```

That gives detach/reattach behavior without installing tmux. You can reconnect from the web UI or optional SSH and land in the same session. Automatic Codex launches use `--dangerously-bypass-approvals-and-sandbox` because the Home Assistant add-on container is already the outer execution boundary and does not reliably support bubblewrap.

## Optional SSH

Set:

```yaml
ssh_enabled: true
ssh_public_key: "ssh-ed25519 AAAA..."
```

Then connect:

```bash
ssh codex@homeassistant.local -p 2222
ai
```

Use `ai` to attach to the same persistent session as the web UI without needing to know the underlying `dtach` command. Password auth is supported for convenience but public key auth is strongly preferred.

## Helper commands

```bash
ha-logs core
ha-logs error
ha-logs supervisor 200
ha-mcp status
ha-mcp test
ha-validate
ai
hab --help
zigporter --help
```

## MCP

When `mcp_enabled: true`, the add-on writes this to `/data/.codex/config.toml`:

```toml
[mcp_servers.homeassistant]
enabled = true
command = "node"
args = ["/opt/ha-mcp-server/index.js"]
cwd = "/homeassistant"
env_vars = ["SUPERVISOR_TOKEN", "HA_ACCESS_TOKEN"]
```

Codex must be restarted after changing MCP configuration.

## Notes and differences from upstream OpenCode add-on

This package intentionally replaces:

- `opencode-ai` with `@openai/codex`
- `tmux` with `dtach`
- OpenCode JSON config with Codex TOML config

It preserves the overall add-on shape: ingress terminal, HA config RW mount, Supervisor API access, helper scripts, MCP/LSP directories, and terminal appearance options.
