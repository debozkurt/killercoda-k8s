#!/bin/bash

echo "Waiting for the Polyphone baseline + scenario mutation..."
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is up. Incident report:"
echo ""
echo "  +-----------------------------------------------+"
echo "  | REPORT: session-broker drops calls on deploy  |"
echo "  | namespace: media                              |"
echo "  | impact:    in-flight sessions truncated       |"
echo "  +-----------------------------------------------+"
echo ""
echo "The pod looks healthy. The bug is in how it dies. Start by reading the"
echo "termination controls:"
echo ""
echo "  kubectl get deploy session-broker -n media -o yaml | grep -A3 -iE 'graceperiod|prestop|lifecycle'"
echo ""
