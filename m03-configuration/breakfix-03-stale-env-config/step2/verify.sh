#!/bin/bash
# Checks: the running session-broker container now serves LOG_LEVEL=debug — i.e.
# it was restarted to pick up the edited ConfigMap. Asserts the OUTCOME (the env
# reflects the current config), not the method — rollout restart, deleting the
# pod, or any roll that re-reads the config all get here.
GOT=$(kubectl exec deploy/session-broker -n media -- printenv LOG_LEVEL 2>/dev/null)
if [ "$GOT" != "debug" ]; then
  echo "session-broker's env LOG_LEVEL is '${GOT:-<unset/notready>}', but the ConfigMap says 'debug'." >&2
  echo "Env is frozen at container start — restart the consumers so they re-read the config:" >&2
  echo "  kubectl rollout restart deployment session-broker -n media" >&2
  exit 1
fi
echo "✓ session-broker now serves LOG_LEVEL=debug — it re-read the updated ConfigMap"
exit 0
