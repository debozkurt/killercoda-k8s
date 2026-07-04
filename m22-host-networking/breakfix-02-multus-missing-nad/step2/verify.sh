#!/bin/bash
# Checks: media-probe in edge is now Running (Multus found the NAD and attached net1).
# Asserts the outcome — either fix (cross-ns reference, or a NAD copied into edge) lands
# the Pod in Running.
PHASE=$(kubectl get pod -n edge -l app=media-probe -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$PHASE" != "Running" ]; then
  echo "media-probe in edge is '$PHASE', not Running. Its requested network must resolve to a NAD in its namespace — reference it as media/rtp-macvlan, or create the rtp-macvlan NAD in edge." >&2
  exit 1
fi
READY=$(kubectl get pod -n edge -l app=media-probe -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
if [ "$READY" != "true" ]; then
  echo "media-probe is Running but not Ready yet — give the macvlan attach a moment and retry." >&2
  exit 1
fi
echo "✓ media-probe is Running with its second NIC attached (Multus found the NAD)"
exit 0
