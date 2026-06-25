#!/bin/bash
# Checks: both portal-ui pods are Ready again. Asserts the OUTCOME (the mount
# resolves and the pods run), not the method — creating the Secret with any
# valid keys, or restoring it from a manifest, all get here.
NOTREADY=$(kubectl get pods -n admin-portal -l app=portal-ui \
  -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{"\n"}{end}' 2>/dev/null | grep -vc '^true$')
if [ "$NOTREADY" != "0" ]; then
  echo "Not all portal-ui pods are Ready yet (the mount is still failing)." >&2
  echo "Create the Secret the volume references in this namespace:" >&2
  echo "  kubectl create secret generic portal-secrets --from-literal=SESSION_SECRET=s3ssion-signing-key --from-literal=ADMIN_API_KEY=adm-9f2a1c7e -n admin-portal" >&2
  exit 1
fi
echo "✓ portal-ui pods are Running — the mounted Secret now exists"
exit 0
