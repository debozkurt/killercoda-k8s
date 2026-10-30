#!/bin/bash
# Checks: announce-player exits promptly on delete. Asserts the outcome by timing the
# termination of one Ready Pod (under 25s against the 45s grace period), after the rollout
# has completed. Deleting one Pod is harmless: the Deployment replaces it.
CMD=$(kubectl get deploy announce-player -n media -o jsonpath='{.spec.template.spec.containers[0].command}' 2>/dev/null)
if echo "$CMD" | grep -q "trap ''"; then
  echo "announce-player still ignores SIGTERM (trap '' TERM). Install a handler:" >&2
  echo "  kubectl patch deployment announce-player -n media --type=json -p '[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/command\",\"value\":[\"sh\",\"-c\",\"trap exit TERM; while true; do sleep 1; done\"]}]'" >&2
  exit 1
fi
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  UPDATED=$(kubectl get deploy announce-player -n media -o jsonpath='{.status.updatedReplicas}' 2>/dev/null)
  AVAIL=$(kubectl get deploy announce-player -n media -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
  REPL=$(kubectl get deploy announce-player -n media -o jsonpath='{.status.replicas}' 2>/dev/null)
  TERM_N=$(kubectl get pods -n media -l app=announce-player --no-headers 2>/dev/null | grep -c Terminating)
  [ "$UPDATED" = "2" ] && [ "$AVAIL" = "2" ] && [ "$REPL" = "2" ] && [ "$TERM_N" = "0" ] && break
  sleep 5
done
if [ "$UPDATED" != "2" ] || [ "$AVAIL" != "2" ] || [ "$REPL" != "2" ] || [ "$TERM_N" != "0" ]; then
  echo "The rollout is still finishing (updated ${UPDATED:-0}, available ${AVAIL:-0}, total ${REPL:-0}). Old Pods take 45s each to leave. Wait until none reads Terminating:" >&2
  echo "  kubectl rollout status deployment/announce-player -n media --timeout=120s" >&2
  exit 1
fi
POD=$(kubectl get pods -n media -l app=announce-player --no-headers 2>/dev/null | grep Running | head -1 | cut -d' ' -f1)
START=$SECONDS
if ! kubectl delete pod $POD -n media --timeout=25s >/dev/null 2>&1; then
  echo "A Pod took longer than 25s to terminate. The container still ignores SIGTERM or is slow to stop. Re-read the Command: block:" >&2
  echo "  kubectl describe deployment announce-player -n media" >&2
  exit 1
fi
echo "✓ announce-player exits promptly on SIGTERM (a Pod terminated in $((SECONDS-START))s)"
exit 0
