#!/bin/bash
# Checks: trunk-monitor's replicas are all Ready and its PDB now allows a disruption.
# Asserts the outcome (workload healthy AND allowed >= 1), so lowering minAvailable to 0 or
# setting an eviction policy alone does not pass: the fault was unready Pods.
for i in 1 2 3 4 5 6; do
  READY=$(kubectl get deploy trunk-monitor -n signaling -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  DESIRED=$(kubectl get deploy trunk-monitor -n signaling -o jsonpath='{.spec.replicas}' 2>/dev/null)
  ALLOWED=$(kubectl get pdb trunk-monitor -n signaling -o jsonpath='{.status.disruptionsAllowed}' 2>/dev/null)
  [ -n "$READY" ] && [ "$READY" = "$DESIRED" ] && [ -n "$ALLOWED" ] && [ "$ALLOWED" -ge 1 ] && break
  sleep 5
done
if [ -z "$READY" ] || [ "$READY" != "$DESIRED" ]; then
  echo "trunk-monitor has ${READY:-0}/${DESIRED:-?} Ready replicas. The readiness probe still fails. Point it at a path nginx serves:" >&2
  echo "  kubectl patch deployment trunk-monitor -n signaling --type=json -p '[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/readinessProbe/httpGet/path\",\"value\":\"/\"}]'" >&2
  exit 1
fi
if [ -z "$ALLOWED" ] || [ "$ALLOWED" -lt 1 ]; then
  echo "All replicas are Ready but the PDB allows ${ALLOWED:-0} disruptions. Wait a few seconds for the disruption controller, then retry." >&2
  exit 1
fi
echo "✓ trunk-monitor is $READY/$DESIRED Ready and its PDB allows $ALLOWED disruption(s)"
exit 0
