#!/usr/bin/env bash
# Push a public key into the root authorized_keys of Proxmox guests.
# Idempotent: re-running does not duplicate the entry.
#
#   ./distribute-key.sh <node> "<public key line>" <ctid> [ctid...]
#
# Example:
#   ./distribute-key.sh 10.0.0.10 "$(cat termix.pub)" 100 101 102
set -euo pipefail

node=${1:?node host or IP required}
key=${2:?public key line required}
shift 2
[ $# -gt 0 ] || { echo "at least one container id required" >&2; exit 2; }

# A stable substring of the key, used as the idempotency marker.
marker=$(printf '%s' "$key" | awk '{print $2}' | tail -c 32)

ssh "root@${node}" "bash -s" <<REMOTE
set -euo pipefail
printf '%s\n' '${key}' > /tmp/.dk.pub
for ct in $*; do
  if ! pct status "\$ct" 2>/dev/null | grep -q running; then
    echo "CT \$ct: not running, skipped"; continue
  fi
  pct push "\$ct" /tmp/.dk.pub /tmp/.dk.pub
  pct exec "\$ct" -- sh -c '
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    touch /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    chown -R root:root /root/.ssh
    grep -qsF "${marker}" /root/.ssh/authorized_keys \
      || cat /tmp/.dk.pub >> /root/.ssh/authorized_keys
    rm -f /tmp/.dk.pub
  '
  echo "CT \$ct: ok"
done
rm -f /tmp/.dk.pub
REMOTE
