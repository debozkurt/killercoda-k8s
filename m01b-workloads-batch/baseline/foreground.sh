#!/bin/bash

echo "Waiting for the Polyphone baseline + batch workloads to finish spinning up..."
echo "(installs local-path-provisioner, metrics-server, k9s; provisions 10 namespaces and the"
echo " 17-workload fleet, plus the batch workloads: schema-migrate, usage-export, cdr-rollup)"
echo ""

while [ ! -f /tmp/.setup-complete ]; do
  sleep 3
  echo -n "."
done
echo ""
echo ""
echo "Cluster is ready. Start by looking at the batch owner chains:"
echo ""
echo "  kubectl get jobs -A"
echo "  kubectl get cronjob -n cdr-storage"
echo ""
echo "(The cdr-rollup CronJob may show LAST SCHEDULE <none> for up to a minute"
echo " until the next minute boundary — that's normal.)"
echo ""
