#!/bin/bash
# Checks: the sip-router HPA has scaled out at least once (a SuccessfulRescale event citing
# utilization above target). Asserts the outcome, not the exact load command. Reads the event,
# not live replicas, so removing the load before the scale-down window does not fail the check.
MSG=$(kubectl get events -n signaling --field-selector involvedObject.name=sip-router,reason=SuccessfulRescale -o jsonpath='{.items[*].message}' 2>/dev/null)
if ! echo "$MSG" | grep -q "above target"; then
  echo "The sip-router HPA has not scaled out yet. Start the load and wait about a minute:" >&2
  echo "  kubectl run load -n signaling --image=busybox:1.36 --restart=Never -- /bin/sh -c 'while true; do wget -q -O- http://sip-router-load > /dev/null; done'" >&2
  exit 1
fi
echo "✓ The sip-router HPA scaled out under load"
exit 0
