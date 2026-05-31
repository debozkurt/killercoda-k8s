#!/bin/bash
# Checks: schema-migrate completed (succeeded>=1) with a Job-legal restartPolicy.
POLICY=$(kubectl get job schema-migrate -n provisioning -o jsonpath='{.spec.template.spec.restartPolicy}' 2>/dev/null)
case "$POLICY" in
  OnFailure|Never) : ;;
  *) echo "restartPolicy is '$POLICY', expected OnFailure or Never (a Job forbids Always)" >&2; exit 1 ;;
esac

SUCCEEDED=$(kubectl get job schema-migrate -n provisioning -o jsonpath='{.status.succeeded}' 2>/dev/null)
[ "$SUCCEEDED" = "1" ] || { echo "schema-migrate succeeded=$SUCCEEDED, expected 1 — the Job may still be running; re-check in a few seconds" >&2; exit 1; }

echo "✓ Run-to-completion healthy: schema-migrate succeeded=1, restartPolicy=$POLICY"
exit 0
