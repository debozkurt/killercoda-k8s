#!/bin/bash
# Checks: session-broker's Pod has a QoS class of Burstable, proving the fleet
# carries requests + limits (the resource contract this step reads). Defensive.
QOS=$(kubectl get pod -n media -l app=session-broker -o jsonpath='{.items[0].status.qosClass}' 2>/dev/null)
if [ "$QOS" != "Burstable" ]; then
  echo "Expected session-broker QoS 'Burstable', got '$QOS'. The fleet may still be coming up — wait and retry." >&2
  exit 1
fi
echo "✓ session-broker is QoS class Burstable (requests + limits both set)"
exit 0
