#!/bin/bash
# Checks: the running account-provisioner now receives the plaintext password
# (changeme). Asserts the OUTCOME — the Secret is encoded exactly once AND the
# pod was restarted to pick it up. Both halves are required: fixing the Secret
# without rolling the consumer leaves the old (wrong) value in the running env.
GOT=$(kubectl exec deploy/account-provisioner -n provisioning -- printenv DB_PASSWORD 2>/dev/null)
if [ "$GOT" != "changeme" ]; then
  echo "account-provisioner's DB_PASSWORD is '${GOT:-<unset/notready>}', expected the plaintext 'changeme'." >&2
  echo "Recreate the Secret with single encoding, then restart the consumer (env is frozen):" >&2
  echo "  kubectl create secret generic database-creds --from-literal=DB_HOST=postgres.polyphone.example --from-literal=DB_PASSWORD=changeme -n provisioning --dry-run=client -o yaml | kubectl apply -f -" >&2
  echo "  kubectl rollout restart deployment account-provisioner -n provisioning" >&2
  exit 1
fi
echo "✓ account-provisioner receives DB_PASSWORD=changeme — the Secret is encoded once and the pod re-read it"
exit 0
