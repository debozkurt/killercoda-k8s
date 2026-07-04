#!/bin/bash
# Checks: rtp-relay now uses dnsPolicy ClusterFirstWithHostNet, so a hostNetwork Pod
# gets cluster DNS. Asserts the outcome (the field), not a specific command.
DP=$(kubectl get deploy rtp-relay -n media -o jsonpath='{.spec.template.spec.dnsPolicy}' 2>/dev/null)
HN=$(kubectl get deploy rtp-relay -n media -o jsonpath='{.spec.template.spec.hostNetwork}' 2>/dev/null)
if [ "$HN" != "true" ]; then
  echo "rtp-relay is no longer on hostNetwork (hostNetwork='$HN'). The fix is to keep it on the host network and set dnsPolicy: ClusterFirstWithHostNet — not to remove hostNetwork." >&2
  exit 1
fi
if [ "$DP" != "ClusterFirstWithHostNet" ]; then
  echo "dnsPolicy is '$DP', expected ClusterFirstWithHostNet. Run: kubectl patch deployment rtp-relay -n media --type=merge -p '{\"spec\":{\"template\":{\"spec\":{\"dnsPolicy\":\"ClusterFirstWithHostNet\"}}}}'" >&2
  exit 1
fi
echo "✓ rtp-relay is on hostNetwork with dnsPolicy=ClusterFirstWithHostNet — cluster DNS restored"
exit 0
