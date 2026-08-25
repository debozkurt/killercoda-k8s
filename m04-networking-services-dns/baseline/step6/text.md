# Step 6 — Three ways to the same backend

The same Pod answers on three different paths. Each one crosses a different set of layers, which is what makes a failed call locatable.

## Collect the two addresses

```bash
POD_IP=$(kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{.items[0].status.podIP}')
SVC_IP=$(kubectl get svc session-broker -n media -o jsonpath='{.spec.clusterIP}')
echo "pod=$POD_IP  service=$SVC_IP"
```{{exec}}

## Call all three from one client

```bash
kubectl run probe --rm -i --restart=Never --image=busybox:1.36 -n media -- sh -c "
  echo -n 'pod IP    : '; wget -qO- -T3 http://$POD_IP/       | grep -o '<title>.*</title>'
  echo -n 'ClusterIP : '; wget -qO- -T3 http://$SVC_IP/       | grep -o '<title>.*</title>'
  echo -n 'DNS name  : '; wget -qO- -T3 http://session-broker/ | grep -o '<title>.*</title>'"
```{{exec}}

Three identical answers, three different amounts of machinery:

| Path | What it crossed | What it proves when it works |
|------|-----------------|------------------------------|
| Pod IP | the pod network only | the process is listening; the network is up |
| ClusterIP | + kube-proxy's rules and the EndpointSlice | the Service has backends and the ports line up |
| DNS name | + cluster DNS | the name resolves in this namespace |

Read it as a ladder. The first one that fails names the layer at fault: Pod IP works but ClusterIP doesn't, and the fault is the Service; ClusterIP works but the name doesn't, and the fault is DNS.

`kubectl port-forward` (step 3) sits below all three — it reaches the Pod through the apiserver, so it proves the process is listening without proving anything about the Service.
