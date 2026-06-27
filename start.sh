#!/usr/bin/env bash
set -euo pipefail

prepare_ssh() {
  mkdir -p /run/sshd /root/.ssh
  chmod 700 /root/.ssh

  touch /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys

  if [[ -n "${PUBLIC_KEY:-}" ]]; then
    printf '%s\n' "${PUBLIC_KEY}" >> /root/.ssh/authorized_keys
  fi

  if [[ -n "${SSH_PUBLIC_KEY:-}" ]]; then
    printf '%s\n' "${SSH_PUBLIC_KEY}" >> /root/.ssh/authorized_keys
  fi

  # Remove empty lines and duplicate keys.
  awk 'NF && !seen[$0]++' /root/.ssh/authorized_keys > /root/.ssh/authorized_keys.tmp
  mv /root/.ssh/authorized_keys.tmp /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys

  ssh-keygen -A

  {
    echo "PermitRootLogin prohibit-password"
    echo "PasswordAuthentication no"
    echo "PubkeyAuthentication yes"
    echo "AuthorizedKeysFile .ssh/authorized_keys"
    echo "PermitTunnel yes"
    echo "AllowTcpForwarding yes"
    echo "GatewayPorts no"
  } > /etc/ssh/sshd_config.d/runpod.conf

  /usr/sbin/sshd
}

prepare_ssh

# Preserve the official llama.cpp server-cuda user-facing syntax:
# RunPod command can still be:
# -m /workspace/model.gguf --host 0.0.0.0 --port 8000 -c 8192 -ngl 999
exec /llama-server "$@"