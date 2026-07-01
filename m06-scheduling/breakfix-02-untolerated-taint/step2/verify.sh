#!/bin/bash
# Checks: pstn-probe now tolerates the worker's taint and has an available replica
# (scheduled + Running). Asserts the outcome, not the exact command used.
AVAIL=$(kubectl get deploy pstn-probe -n edge -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "$AVAIL" != "1" ]; then
  echo "pstn-probe still has no available replica — it isn't scheduled. Add a toleration for the worker's taint, e.g.: kubectl patch deployment pstn-probe -n edge --type=json -p '[{\"op\":\"add\",\"path\":\"/spec/template/spec/tolerations\",\"value\":[{\"key\":\"dedicated\",\"value\":\"telephony\",\"operator\":\"Equal\",\"effect\":\"NoSchedule\"}]}]'" >&2
  exit 1
fi
echo "✓ pstn-probe is Available (1/1) — its toleration lets it land on the tainted worker"
exit 0
