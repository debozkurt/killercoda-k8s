#!/bin/bash

echo "Waiting for the Polyphone baseline + scenario mutation..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is up. On-call notices:"
echo ""
echo "  +-----------------------------------------------+"
echo "  | STUCK: cdr-archive Job never completes         |"
echo "  | job:      cdr-archive (cdr-storage)            |"
echo "  | symptom:  COMPLETIONS 0/1, archive step done   |"
echo "  | impact:   no archive-complete hook; dupes pile |"
echo "  +-----------------------------------------------+"
echo ""
echo "The work finished but the Job won't. Start with:"
echo ""
echo "  kubectl get job cdr-archive -n cdr-storage"
echo "  kubectl get pods -n cdr-storage -l app=cdr-archive"
echo ""
