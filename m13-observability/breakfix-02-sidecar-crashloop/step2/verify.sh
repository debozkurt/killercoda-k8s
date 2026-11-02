#!/bin/bash
# Checks: the metrics-agent sidecar has COLLECTOR_ENDPOINT set and has logged an
# export, so it survived past its 15-second check. Polls up to 45 seconds because
# the agent exports only after that check, and the Pod reads 2/2 only after it.
ENV=$(kubectl get deployment sip-monitor -n signaling \
  -o jsonpath='{.spec.template.spec.containers[?(@.name=="metrics-agent")].env[?(@.name=="COLLECTOR_ENDPOINT")].value}' 2>/dev/null)
if [ -z "$ENV" ]; then
  echo "The metrics-agent sidecar has no COLLECTOR_ENDPOINT. Set it on that container only:" >&2
  echo "  kubectl set env deployment/sip-monitor -n signaling -c metrics-agent COLLECTOR_ENDPOINT=collector.platform.svc:4317" >&2
  exit 1
fi
for i in $(seq 1 15); do
  if kubectl logs -n signaling -l app=sip-monitor -c metrics-agent --tail=20 --max-log-requests=5 2>/dev/null | grep -q "exported telemetry batch"; then
    READY=$(kubectl get pods -n signaling -l app=sip-monitor --no-headers 2>/dev/null | grep -c " 2/2 ")
    if [ "$READY" -ge 1 ]; then
      echo "✓ metrics-agent has COLLECTOR_ENDPOINT, exports telemetry, and the Pod is 2/2"
      exit 0
    fi
  fi
  sleep 3
done
echo "The sidecar has the variable, but it has not logged an export and reached 2/2 yet. The agent waits 15 seconds first." >&2
echo "  Check it with: kubectl get pods -n signaling -l app=sip-monitor; kubectl logs -n signaling deploy/sip-monitor -c metrics-agent" >&2
exit 1
