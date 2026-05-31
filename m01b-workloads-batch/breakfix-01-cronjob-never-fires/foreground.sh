#!/bin/bash

echo "Waiting for the Polyphone baseline + scenario mutation..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is up. A data engineer reports:"
echo ""
echo "  +-----------------------------------------------+"
echo "  | REPORT: CDR rollup output is stale            |"
echo "  | cronjob:   cdr-rollup (cdr-storage)           |"
echo "  | symptom:   no recent rollup Jobs at all       |"
echo "  | impact:    billing reconciliation drifting    |"
echo "  +-----------------------------------------------+"
echo ""
echo "No errors, no pods. Why is it creating nothing? Start with:"
echo ""
echo "  kubectl get cronjob -n cdr-storage"
echo ""
