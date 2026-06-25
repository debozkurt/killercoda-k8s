#!/bin/bash
# Checks: account-provisioner's BROKER_ENDPOINT now uses a namespace-qualified
# name for the cross-namespace call (contains session-broker.media), so it
# resolves from provisioning. Asserts the outcome, not a specific command.
VAL=$(kubectl get deploy account-provisioner -n provisioning \
  -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="BROKER_ENDPOINT")].value}' 2>/dev/null)
case "$VAL" in
  *session-broker.media*) ;;
  *) echo "BROKER_ENDPOINT is '$VAL'. A bare name won't resolve cross-namespace — qualify it, e.g.: kubectl set env deployment/account-provisioner -n provisioning BROKER_ENDPOINT=http://session-broker.media.svc.cluster.local/" >&2; exit 1 ;;
esac
echo "✓ BROKER_ENDPOINT is qualified for cross-namespace resolution: $VAL"
exit 0
