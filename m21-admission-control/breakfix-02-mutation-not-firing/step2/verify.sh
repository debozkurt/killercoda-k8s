#!/bin/bash
# Checks: the mutating webhook matches CREATE again AND orders-api rolled out with the injected
# env label — proof that mutation fired before validation. Asserts the outcome, not the command.
OPS=$(kubectl get mutatingwebhookconfiguration admission-guard -o jsonpath='{.webhooks[0].rules[0].operations}' 2>/dev/null)
case "$OPS" in
  *CREATE*) : ;;
  *) echo "The mutating webhook still doesn't match CREATE (operations=$OPS). Set operations to include CREATE so it fires when a Pod is created." >&2; exit 1 ;;
esac
AVAIL=$(kubectl get deploy orders-api -n tenant-apps -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
ENV=$(kubectl get pods -n tenant-apps -l app=orders-api -o jsonpath='{.items[0].metadata.labels.env}' 2>/dev/null)
if [ "${AVAIL:-0}" -ge 1 ] 2>/dev/null && [ "$ENV" = "tenant" ]; then
  echo "✓ mutating webhook matches CREATE; orders-api is Available and its Pod carries the injected env=tenant"
  exit 0
fi
echo "orders-api isn't up with env=tenant yet. After fixing operations, re-admit it (e.g. kubectl rollout restart deployment/orders-api -n tenant-apps), then wait and retry." >&2
exit 1
