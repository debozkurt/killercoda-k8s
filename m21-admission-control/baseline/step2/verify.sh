#!/bin/bash
# Checks the ordering worked: tenant-web is Available AND its running Pod carries env=tenant,
# a label the Deployment template never set — injected by the mutating webhook, then accepted
# by the validating webhook.
AVAIL=$(kubectl get deploy tenant-web -n tenant-apps -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ -z "$AVAIL" ] || [ "$AVAIL" -lt 1 ] 2>/dev/null; then
  echo "tenant-web isn't Available yet — the fleet or the webhook may still be settling. Wait and retry." >&2
  exit 1
fi
ENV=$(kubectl get pods -n tenant-apps -l app=tenant-web -o jsonpath='{.items[0].metadata.labels.env}' 2>/dev/null)
if [ "$ENV" = "tenant" ]; then
  echo "✓ tenant-web is up and its Pod carries the injected env=tenant label (mutate → validate)"
  exit 0
fi
echo "tenant-web's Pod isn't showing env=tenant yet — the mutating webhook may not be registered, or the Pod predates it. Wait and retry." >&2
exit 1
