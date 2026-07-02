#!/bin/bash
# Checks: session-broker is up and its logs are retrievable (it logs to stdout,
# so kubectl logs works). Defensive baseline check — nothing is broken.
if ! kubectl get deployment session-broker -n media >/dev/null 2>&1; then
  echo "session-broker isn't present in namespace media yet. The cluster may still be coming up — wait and retry." >&2
  exit 1
fi
if ! kubectl logs deploy/session-broker -n media --tail=1 >/dev/null 2>&1; then
  echo "Couldn't read logs from session-broker yet. Wait for its Pod to be Running and retry." >&2
  exit 1
fi
echo "✓ session-broker logs to stdout and kubectl logs retrieves them"
exit 0
