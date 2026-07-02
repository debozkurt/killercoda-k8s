#!/bin/bash
# Checks: route-watcher's Pod template now names the route-watcher ServiceAccount
# (not the namespace default) — the identity fix this scenario turns on. The RBAC
# was correct from the start, so this asserts the Pod finally adopts it.
SA=$(kubectl get deploy route-watcher -n call-routing \
  -o jsonpath='{.spec.template.spec.serviceAccountName}' 2>/dev/null)
if [ "$SA" != "route-watcher" ]; then
  echo "route-watcher's Pod still runs as '${SA:-default}', not the bound SA. Set it, e.g.: kubectl set serviceaccount deployment route-watcher route-watcher -n call-routing" >&2
  exit 1
fi
echo "✓ route-watcher runs as ServiceAccount 'route-watcher' — the identity its RoleBinding grants"
exit 0
