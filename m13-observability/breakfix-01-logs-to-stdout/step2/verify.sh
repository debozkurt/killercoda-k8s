#!/bin/bash
# Checks: session-logger's session activity is now visible via kubectl logs —
# either because the app logs to stdout (Option A) or a streaming sidecar tails
# the file to stdout (Option B). Both surface the "session sess-N established"
# lines under --all-containers. Deterministic once the fix rolls out.
LOGS=$(kubectl logs -n app-services deploy/session-logger --all-containers=true --tail=50 2>/dev/null)
if ! echo "$LOGS" | grep -q 'session sess-'; then
  echo "session-logger's per-session activity still isn't visible in 'kubectl logs'. Get its output onto stdout — either reconfigure the app to log to stdout, or add a streaming sidecar (log-stream) that tails /var/log/app/session.log. Then re-run after the rollout completes." >&2
  exit 1
fi
echo "✓ session activity is now visible via kubectl logs (--all-containers) — the output reaches stdout, so the log pipeline can capture it"
exit 0
