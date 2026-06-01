#!/bin/bash
# Checks: media-recorder is Ready again — the authenticated pull succeeded.
# Asserts the outcome; a regcred secret + attached imagePullSecret (on the pod
# or the ServiceAccount) are both valid ways to get there.
READY=$(kubectl get pod -n media -l app=media-recorder -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
if [ "$READY" != "true" ]; then
  echo "media-recorder is not Ready yet — the pull is still unauthenticated or the new pod is pulling." >&2
  echo "Create the pull secret and attach it:" >&2
  echo "  kubectl create secret docker-registry regcred --docker-server=localhost:5000 --docker-username=polyphone --docker-password=reg-pass -n media" >&2
  echo "  kubectl patch deployment media-recorder -n media -p '{\"spec\":{\"template\":{\"spec\":{\"imagePullSecrets\":[{\"name\":\"regcred\"}]}}}}'" >&2
  exit 1
fi
echo "✓ media-recorder is Ready — the kubelet authenticated to the private registry"
exit 0
