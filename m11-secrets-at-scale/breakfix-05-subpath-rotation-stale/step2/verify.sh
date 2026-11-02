#!/bin/bash
# Checks: partner-connector mounts the partner-api volume without subPath, and the file it
# reads holds the store's current api-token.
SUB=$(kubectl get deployment partner-connector -n media -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].subPath}' 2>/dev/null)
if [ -n "$SUB" ]; then
  echo "partner-connector still mounts the token with subPath '$SUB', so no rotation reaches it. Mount the directory:" >&2
  echo "  kubectl patch deployment partner-connector -n media --type=json -p '[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/volumeMounts/0/mountPath\",\"value\":\"/etc/partner\"},{\"op\":\"remove\",\"path\":\"/spec/template/spec/containers/0/volumeMounts/0/subPath\"}]'" >&2
  exit 1
fi
STORE=$(kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data.api-token}' 2>/dev/null | base64 -d)
LIVE=$(kubectl exec deploy/partner-connector -n media -- cat /etc/partner/API_TOKEN 2>/dev/null)
if [ "$LIVE" != "$STORE" ]; then
  echo "The file holds '$LIVE', and the store holds '$STORE'. After a store change, the operator and the kubelet need up to two minutes. Wait, then run:" >&2
  echo "  kubectl exec deploy/partner-connector -n media -- cat /etc/partner/API_TOKEN" >&2
  exit 1
fi
kubectl get pods -n media -l app=partner-connector
echo "✓ partner-connector mounts the directory and its file holds the current token"
exit 0
