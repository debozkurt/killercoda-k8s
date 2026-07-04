#!/bin/bash
# Checks: the rtp-macvlan NAD exists in `media` and media-probe is Running (so Multus
# attached its second NIC). Defensive baseline check — Multus + macvlan take a moment.
NAD=$(kubectl get network-attachment-definition rtp-macvlan -n media -o jsonpath='{.metadata.name}' 2>/dev/null)
PHASE=$(kubectl get pod -n media -l app=media-probe -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ -z "$NAD" ]; then
  echo "NetworkAttachmentDefinition rtp-macvlan not found in media — Multus may still be installing. Wait and retry." >&2
  exit 1
fi
if [ "$PHASE" != "Running" ]; then
  echo "media-probe isn't Running yet (phase='$PHASE'). Its macvlan attach may still be in progress — wait and retry." >&2
  exit 1
fi
echo "✓ media-probe is Running with the rtp-macvlan NAD attached (second NIC net1)"
exit 0
