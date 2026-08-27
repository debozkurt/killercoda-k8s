#!/bin/bash
# Checks: session-broker forwards to a targetPort where nginx actually listens
# (80), so the request path completes. Defensive baseline check.
TP=$(kubectl get svc session-broker -n media -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null)
if [ "$TP" != "80" ]; then
  echo "session-broker targetPort is '$TP', expected 80 (nginx listens on 80)." >&2
  exit 1
fi
echo "✓ session-broker port 80 → targetPort 80, landing on the nginx listener"
exit 0
