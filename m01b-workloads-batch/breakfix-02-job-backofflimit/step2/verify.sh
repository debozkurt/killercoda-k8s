#!/bin/bash
# Checks: schema-migrate now completes (succeeded=1) and its command no longer
# carries the `ecaho` typo (i.e. it was actually recreated/corrected).
if kubectl get job schema-migrate -n provisioning -o jsonpath='{.spec.template.spec.containers[0].command}' 2>/dev/null | grep -q 'ecaho'; then
  echo "schema-migrate still has the 'ecaho' typo in its command — it will keep failing. A Job is immutable: delete and recreate with the corrected command (see step 2)." >&2
  exit 1
fi

SUCCEEDED=$(kubectl get job schema-migrate -n provisioning -o jsonpath='{.status.succeeded}' 2>/dev/null)
[ "$SUCCEEDED" = "1" ] || { echo "schema-migrate succeeded=$SUCCEEDED, expected 1. If you just recreated it, give it a few seconds: kubectl wait --for=condition=complete job/schema-migrate -n provisioning --timeout=60s" >&2; exit 1; }

echo "✓ Job fixed: schema-migrate succeeded=1 (recreated with a working command — Jobs are immutable)"
exit 0
