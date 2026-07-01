#!/bin/bash
# Checks: the directory Deployment now mounts the claim that exists (directory-data)
# and its Pod is Ready. Asserts the outcome, not a specific command.
CN=$(kubectl get deploy directory -n app-services \
  -o jsonpath='{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}' 2>/dev/null)
if [ "$CN" != "directory-data" ]; then
  echo "directory still mounts claim '$CN', which doesn't exist. Point it at the claim that does (directory-data), e.g.: kubectl patch deployment directory -n app-services --type=json -p '[{\"op\":\"replace\",\"path\":\"/spec/template/spec/volumes/0/persistentVolumeClaim/claimName\",\"value\":\"directory-data\"}]'" >&2
  exit 1
fi
READY=$(kubectl get deploy directory -n app-services -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ -z "$READY" ] || [ "$READY" -lt 1 ]; then
  echo "directory mounts the right claim now, but no Pod is Ready yet — give the rollout a few seconds and retry." >&2
  exit 1
fi
echo "✓ directory mounts directory-data (Bound) and has $READY Ready replica(s)"
exit 0
