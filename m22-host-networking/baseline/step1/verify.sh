#!/bin/bash
# Checks: rtp-relay is a hostNetwork Pod whose Pod IP equals the node IP (so it truly
# shares the node netns). Defensive baseline check — the fleet may still be settling.
HN=$(kubectl get pod -n media -l app=rtp-relay -o jsonpath='{.items[0].spec.hostNetwork}' 2>/dev/null)
PODIP=$(kubectl get pod -n media -l app=rtp-relay -o jsonpath='{.items[0].status.podIP}' 2>/dev/null)
HOSTIP=$(kubectl get pod -n media -l app=rtp-relay -o jsonpath='{.items[0].status.hostIP}' 2>/dev/null)
if [ "$HN" != "true" ]; then
  echo "rtp-relay is not on hostNetwork yet (hostNetwork='$HN'). The relay may still be coming up — wait and retry." >&2
  exit 1
fi
if [ -z "$PODIP" ] || [ "$PODIP" != "$HOSTIP" ]; then
  echo "rtp-relay's Pod IP ('$PODIP') doesn't match the node IP ('$HOSTIP') yet — wait for it to be Running and retry." >&2
  exit 1
fi
echo "✓ rtp-relay shares the node netns: Pod IP == node IP ($PODIP)"
exit 0
