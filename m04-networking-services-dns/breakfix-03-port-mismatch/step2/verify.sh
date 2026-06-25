#!/bin/bash
# Checks: portal-ui forwards to a targetPort with a real listener (80), so the
# connection is no longer refused. Asserts the outcome, not the command.
TP=$(kubectl get svc portal-ui -n admin-portal -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null)
if [ "$TP" != "80" ]; then
  echo "portal-ui targetPort is '$TP', but nginx listens on 80. Point it at the listener, e.g.: kubectl patch svc portal-ui -n admin-portal -p '{\"spec\":{\"ports\":[{\"port\":80,\"targetPort\":80}]}}'" >&2
  exit 1
fi
echo "✓ portal-ui port 80 → targetPort 80, landing on the nginx listener"
exit 0
