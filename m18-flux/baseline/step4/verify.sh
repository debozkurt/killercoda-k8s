#!/bin/bash
# Checks: both HelmReleases are Ready and the helm CLI sees the release record in flux-system.
for hr in message-store voicemail; do
  READY=$(kubectl get helmrelease "$hr" -n flux-system \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  [ "$READY" = "True" ] || { echo "HelmRelease $hr is not Ready (got: ${READY:-none}). Run:" >&2; echo "  flux reconcile helmrelease $hr" >&2; exit 1; }
done

command -v helm >/dev/null 2>&1 || { echo "helm CLI not found on PATH. Setup did not finish; reload the scenario." >&2; exit 1; }
helm status app-services-voicemail -n flux-system >/dev/null 2>&1 \
  || { echo "No release app-services-voicemail in flux-system. Run:" >&2; echo "  helm list -n flux-system" >&2; exit 1; }

echo "✓ message-store and voicemail are Ready; release app-services-voicemail is recorded in flux-system"
exit 0
