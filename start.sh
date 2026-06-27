#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[runpod-ssh] $*" >&2
}

find_llama_server() {
  if [[ -x /app/llama-server ]]; then
    echo /app/llama-server
    return 0
  fi

  if command -v llama-server >/dev/null 2>&1; then
    command -v llama-server
    return 0
  fi

  log "ERROR: llama-server not found"
  log "PATH=${PATH}"
  log "Available /app files:"
  ls -la /app >&2 || true
  exit 127
}

prepare_ssh() {
  log "Preparing SSH server"

  mkdir -p /run/sshd /root/.ssh
  chmod 700 /root/.ssh

  touch /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys

  if [[ -n "${PUBLIC_KEY:-}" ]]; then
    log "Adding PUBLIC_KEY"
    printf '%s\n' "${PUBLIC_KEY}" >> /root/.ssh/authorized_keys
  fi

  if [[ -n "${SSH_PUBLIC_KEY:-}" ]]; then
    log "Adding SSH_PUBLIC_KEY"
    printf '%s\n' "${SSH_PUBLIC_KEY}" >> /root/.ssh/authorized_keys
  fi

  awk 'NF && !seen[$0]++' /root/.ssh/authorized_keys > /root/.ssh/authorized_keys.tmp
  mv /root/.ssh/authorized_keys.tmp /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys

  ssh-keygen -A >/dev/null

  cat > /etc/ssh/sshd_config.d/runpod.conf <<'EOF'
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
AllowTcpForwarding yes
GatewayPorts no
PermitTunnel yes
EOF

  /usr/sbin/sshd
  log "SSH server started"
}

main() {
  prepare_ssh

  local llama_server
  llama_server="$(find_llama_server)"

  log "Starting llama-server: ${llama_server} $*"
  exec "${llama_server}" "$@"
}

main "$@"