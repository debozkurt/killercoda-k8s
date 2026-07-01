#!/bin/bash
# Checks: the call-coordinator Lease exists with a holder, and the coordinator SA can
# get/create/update it — the healthy leader-election state. Defensive baseline check.
HOLDER=$(kubectl get lease call-coordinator -n call-routing -o jsonpath='{.spec.holderIdentity}' 2>/dev/null)
if [ -z "$HOLDER" ]; then
  echo "Lease call-coordinator in call-routing has no holderIdentity yet. Wait for setup to finish and retry." >&2
  exit 1
fi
for verb in get create update; do
  ANS=$(kubectl auth can-i "$verb" leases.coordination.k8s.io -n call-routing \
    --as=system:serviceaccount:call-routing:coordinator 2>/dev/null)
  if [ "$ANS" != "yes" ]; then
    echo "coordinator SA cannot '$verb' leases (got '$ANS'). The leader-election Role should grant get/create/update on leases." >&2
    exit 1
  fi
done
echo "✓ Lease call-coordinator is held by '$HOLDER'; the coordinator SA can get/create/update it"
exit 0
