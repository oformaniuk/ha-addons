#!/usr/bin/env bash
export HOME=/data
export CODEX_HOME=/data/.codex
export XDG_DATA_HOME=/data/.local/share
export XDG_CONFIG_HOME=/data/.config
export XDG_CACHE_HOME=/data/.cache
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
export EDITOR=/usr/bin/nano
export VISUAL=/usr/bin/nano
export GIT_EDITOR=/usr/bin/nano
export SUDO_EDITOR=/usr/bin/nano
[ -f /data/.env_vars ] && source /data/.env_vars
cd /homeassistant 2>/dev/null || true
codex() {
  case "${1:-}" in
    login|logout|update|completion|help|--help|-h|--version|-V)
      command codex "$@"
      ;;
    *)
      command codex --dangerously-bypass-approvals-and-sandbox "$@"
      ;;
  esac
}
alias c='codex'
alias a='codex-session'
alias ll='ls -la'
