# Step 4 — PodDisruptionBudgets

Two kinds of disruption remove Pods. **Involuntary** disruption just happens: a node crashes. **Voluntary** disruption is one you start: draining a node for a kernel patch. A **PodDisruptionBudget** (PDB) limits how many replicas voluntary disruption may take down at once. The baseline ships one on `route-engine`.

## Read the budget

```bash
kubectl get pdb -n call-routing
```{{exec}}

`ALLOWED DISRUPTIONS` is the number that matters. With 2 healthy replicas and a floor of 1, it reads 1. The budget lets one replica go at a time.

```bash
kubectl describe pdb route-engine -n call-routing
```{{exec}}

Read the `Status:` block: `Allowed disruptions:`, `Current:`, and `Desired:`. Current counts healthy Pods. The rule is allowed disruptions = current − desired, floored at 0. Here that is 2 − 1 = 1.

## Watch the eviction API enforce it

`kubectl drain` does not delete Pods. It calls the **eviction API**, which checks every budget first. Call that API on each `route-engine` Pod in a row. The first eviction passes. The second arrives before the replacement is Ready:

```bash
for POD in $(kubectl get pods -n call-routing -l app=route-engine -o name | cut -d/ -f2); do
  echo "{\"apiVersion\":\"policy/v1\",\"kind\":\"Eviction\",\"metadata\":{\"name\":\"$POD\",\"namespace\":\"call-routing\"}}" > /tmp/evict.json
  kubectl create --raw "/api/v1/namespaces/call-routing/pods/$POD/eviction" -f /tmp/evict.json; echo
done
```{{exec}}

The first call returns a Status object with Success. The second returns `TooManyRequests: Cannot evict pod as it would violate the pod's disruption budget`. A drain retries that refusal until the budget opens. Read the state, then wait for the replacement:

```bash
kubectl get pods -n call-routing -l app=route-engine
kubectl wait --for=condition=Ready pod -l app=route-engine -n call-routing --timeout=60s
```{{exec}}

This is how a rolling drain stays safe: evict one Pod, wait for its replacement, evict the next. A budget whose floor equals the replica count reads 0 allowed disruptions, and no eviction ever passes. Next: what a Pod does when told to stop.
