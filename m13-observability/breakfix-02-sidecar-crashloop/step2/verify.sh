#!/bin/bash
# Checks: sip-monitor is Available again — which requires its Pod to be fully
# Ready, i.e. BOTH containers (app + metrics-agent) up. A 1/2 Pod with the
# crashlooping sidecar is never Ready, so the Deployment is not Available until
# the sidecar command is fixed. Deterministic once the rollout completes.
if ! kubectl wait --for=condition=Available deployment/sip-monitor -n signaling --timeout=90s >/dev/null 2>&1; then
  echo "sip-monitor still isn't Available — its metrics-agent sidecar isn't Ready (Pod stuck below 2/2). Correct the sidecar's command (container index 1) so it runs a command the image provides, then wait for the rollout." >&2
  exit 1
fi
echo "✓ sip-monitor is 2/2 and Available — the app and its metrics-agent sidecar are both Ready"
exit 0
