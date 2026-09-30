#!/bin/bash

echo "Waiting for the Polyphone baseline to finish spinning up..."
while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "conference-mixer (media) is stuck Pending, with no shortage and no new taint."
echo "Read the scheduler's reason:"
echo ""
echo "  kubectl describe pod -n media -l app=conference-mixer"
echo ""
