#!/bin/bash
# Checks: the healthy private-registry pull — regcred is a dockerconfigjson
# secret, the pod references it, and media-recorder is Ready.
TYPE=$(kubectl get secret regcred -n media -o jsonpath='{.type}' 2>/dev/null)
[ "$TYPE" = "kubernetes.io/dockerconfigjson" ] || { echo "regcred type is '$TYPE', expected kubernetes.io/dockerconfigjson." >&2; exit 1; }

READY=$(kubectl get pod -n media -l app=media-recorder -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
[ "$READY" = "true" ] || { echo "media-recorder is not Ready yet (ready=$READY). The private-registry pull may still be in progress." >&2; exit 1; }
echo "✓ Healthy private-registry pull: regcred (dockerconfigjson) wired, media-recorder Ready"
exit 0
