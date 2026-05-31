#!/bin/bash

echo "Waiting for the Polyphone baseline + scenario mutation..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is up. The release pipeline is blocked:"
echo ""
echo "  +-----------------------------------------------+"
echo "  | BLOCKED: pre-deploy schema migration failing  |"
echo "  | job:      schema-migrate (provisioning)       |"
echo "  | symptom:  COMPLETIONS stuck at 0/1            |"
echo "  | impact:   release cannot proceed              |"
echo "  +-----------------------------------------------+"
echo ""
echo "Still retrying, or already given up? Start with:"
echo ""
echo "  kubectl get jobs -n provisioning"
echo ""
