#!/bin/bash
# Checks: sip-edge declares hostPort 5060 and keeps a normal (non-host) pod IP.
# Defensive baseline check.
HP=$(kubectl get pod -n edge -l app=sip-edge -o jsonpath='{.items[0].spec.containers[0].ports[0].hostPort}' 2>/dev/null)
PODIP=$(kubectl get pod -n edge -l app=sip-edge -o jsonpath='{.items[0].status.podIP}' 2>/dev/null)
HOSTIP=$(kubectl get pod -n edge -l app=sip-edge -o jsonpath='{.items[0].status.hostIP}' 2>/dev/null)
if [ "$HP" != "5060" ]; then
  echo "sip-edge doesn't expose hostPort 5060 yet (got '$HP'). It may still be scheduling — wait and retry." >&2
  exit 1
fi
if [ -z "$PODIP" ] || [ "$PODIP" = "$HOSTIP" ]; then
  echo "sip-edge isn't on the pod network yet (podIP='$PODIP', hostIP='$HOSTIP'). Wait for it to be Running and retry." >&2
  exit 1
fi
echo "✓ sip-edge maps node:5060 -> container while keeping pod IP $PODIP"
exit 0
