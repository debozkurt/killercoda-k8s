#!/bin/bash
# Checks: the event stream is readable and the fleet is up (session-broker
# exists to attach events to). Defensive baseline check — nothing is broken.
if ! kubectl get deployment session-broker -n media >/dev/null 2>&1; then
  echo "session-broker isn't present in namespace media yet. The cluster may still be coming up — wait and retry." >&2
  exit 1
fi
if ! kubectl get events -n media >/dev/null 2>&1; then
  echo "Couldn't read events in namespace media yet. Wait for the cluster to settle and retry." >&2
  exit 1
fi
echo "✓ event stream readable and the fleet is up — you can survey events with get/describe"
exit 0
