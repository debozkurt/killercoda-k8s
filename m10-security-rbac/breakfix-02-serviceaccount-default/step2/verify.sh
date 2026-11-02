#!/bin/bash
# Checks: route-watcher's Pod template names the route-watcher ServiceAccount, the default
# ServiceAccount was NOT granted endpoint access, and the Deployment is Available again.
SA=$(kubectl get deploy route-watcher -n call-routing \
  -o jsonpath='{.spec.template.spec.serviceAccountName}' 2>/dev/null)
if [ "$SA" != "route-watcher" ]; then
  echo "route-watcher's Pods still run as '${SA:-default}'. Set the bound ServiceAccount:" >&2
  echo "  kubectl set serviceaccount deployment route-watcher route-watcher -n call-routing" >&2
  exit 1
fi
DEF=$(kubectl auth can-i list endpoints -n call-routing \
  --as=system:serviceaccount:call-routing:default 2>/dev/null)
if [ "$DEF" = "yes" ]; then
  echo "The default ServiceAccount in call-routing can now list endpoints. That grant reaches every Pod that omits serviceAccountName. Remove it:" >&2
  echo "  kubectl get rolebindings -n call-routing -o wide" >&2
  exit 1
fi
for i in 1 2 3 4 5 6; do
  AVAIL=$(kubectl get deploy route-watcher -n call-routing -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
  [ "$AVAIL" = "1" ] && break
  sleep 5
done
if [ "$AVAIL" != "1" ]; then
  echo "route-watcher is not Available yet. Watch the rollout:" >&2
  echo "  kubectl rollout status deployment route-watcher -n call-routing --timeout=60s" >&2
  exit 1
fi
kubectl get pods -n call-routing -l app=route-watcher
echo "✓ route-watcher runs as ServiceAccount route-watcher, and default holds no endpoint grant"
exit 0
