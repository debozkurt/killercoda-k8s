#!/bin/bash
# Checks: the multi-container call-recorder Pod is Ready, so both containers are
# execable and the shared-namespace demo in this step works. Defensive baseline check.
READY=$(kubectl get pod -n media -l app=call-recorder \
  -o jsonpath='{.items[0].status.containerStatuses[*].ready}' 2>/dev/null)
case "$READY" in
  *true*true*) ;;
  *) echo "call-recorder is not showing two Ready containers (got '$READY'). It may still be starting — wait and retry." >&2
     exit 1 ;;
esac
IP=$(kubectl get pod -n media -l app=call-recorder -o jsonpath='{.items[0].status.podIP}' 2>/dev/null)
echo "✓ call-recorder has two Ready containers sharing one namespace at $IP"
exit 0
