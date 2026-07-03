#!/bin/bash
# Checks: edge-relay is healthy again and its envFrom references a ConfigMap
# that actually exists — i.e. the reference was rewritten to the hashed name the
# generator produced. Asserts the outcome, not the command.
NS=edge

READY=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${READY:-0}" -lt 3 ]; then
  echo "edge-relay not healthy yet (${READY:-0}/3 ready). After aligning the names, run: kubectl apply -k /root/edge-relay/overlays/prod" >&2
  exit 1
fi

REF=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' 2>/dev/null)
case "$REF" in
  edge-relay-config-*) : ;;  # rewritten to the hashed generator name
  *) echo "The Deployment references '$REF' — expected the hashed generator name edge-relay-config-<hash>. The reference name must match the generator name." >&2; exit 1 ;;
esac

kubectl get configmap "$REF" -n "$NS" >/dev/null 2>&1 || {
  echo "The Deployment references ConfigMap '$REF' but it does not exist in $NS." >&2; exit 1; }

echo "✓ edge-relay is 3/3 and references $REF (which exists) — the name match restored the hash rewrite."
exit 0
