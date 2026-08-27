# Step 5 — The diagnostic loop

Four commands, in order, will solve most problems you encounter in this curriculum:

```text
get → describe → events → logs
```

Each tells you something the previous one can't. You're going to walk through them against a healthy workload — `portal-ui` in `admin-portal` — so you know what each one looks like when nothing is wrong. Later modules drop you into broken environments where you'll run the same loop without the safety net.

## 1. get — what's there?

```bash
kubectl get pods -n admin-portal
```{{exec}}

You should see two `portal-ui-*` pods, both `Running`. The `READY` column should show `1/1`, the `RESTARTS` column should show `0`.

Add `-o wide` for more:

```bash
kubectl get pods -n admin-portal -o wide
```{{exec}}

Now you see which node each pod is on, and its pod IP.

That IP comes from the **CNI plugin** — the node component that attaches a Pod to the network. The kubelet calls it when the Pod starts, and it hands back one IP the Pod's containers share; every Pod reaches every other Pod at that address, on any node, with nothing translating it. The IP lasts exactly as long as the Pod, which is why M04 puts a Service in front of it.

## 2. describe — what does the API server know?

```bash
kubectl describe pod -n admin-portal -l app=portal-ui
```{{exec}}

`describe` is the most information-dense command in the kit. It shows:

- All of `metadata` (labels, annotations, owner references)
- All of `spec` (image, ports, volumes, resources)
- All of `status` (current conditions, container state, recent restart reasons)
- **Events** filtered to this specific pod — every controller decision that touched it

For a healthy pod, the Events section should show a clean sequence: `Scheduled` → `Pulled` → `Created` → `Started`. When things go wrong, this section is the first place to look.

## 3. events — what's happening in the neighborhood?

`describe` shows you events for *one* object. `get events` shows you events for an entire namespace — including events on objects you wouldn't have thought to describe:

```bash
kubectl get events -n admin-portal --sort-by='.lastTimestamp'
```{{exec}}

For a healthy namespace this is sparse. For a broken one this is where the answer often is — especially when a ReplicaSet, Service, or PVC has the event the Pod doesn't.

Cluster-wide:

```bash
kubectl get events -A --sort-by='.lastTimestamp' | tail -20
```{{exec}}

This is the command for "something is broken somewhere on the cluster, I don't know where." Bookmark it.

## 4. logs — what does the application say?

```bash
POD=$(kubectl get pod -n admin-portal -l app=portal-ui -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n admin-portal $POD
```{{exec}}

`portal-ui` is just an `nginx` placeholder so the logs are spartan. For a real app this is where you'd see the application's own view of itself: which requests are succeeding, which dependencies are reachable.

Useful variants:

```bash
kubectl logs -n admin-portal -l app=portal-ui --tail=20    # logs across all matching pods
kubectl logs -n admin-portal $POD --previous              # last terminated container (after a crash)
kubectl logs -n admin-portal $POD -f                      # follow live
```

## The pattern

You just did the canonical diagnostic loop on a healthy workload. Whenever you suspect something is wrong:

1. `kubectl get pods -n <ns>` — is it even there? what's its phase?
2. `kubectl describe pod <name> -n <ns>` — what happened to it?
3. `kubectl get events -n <ns> --sort-by='.lastTimestamp'` — what's happening around it?
4. `kubectl logs <pod> -n <ns>` (+ `--previous` if it crashed) — what does it say?

The remaining M00 break/fix scenarios drill the same loop from different angles. Each one isolates one missing piece:

- **`breakfix-01-context-blindness`** — *suspect your own view before suspecting the cluster.* The simplest, and where you'll start.
- **`breakfix-02-namespace-blindness`** — *scan cluster-wide when you don't know where.* The `-A` instinct.
- **`breakfix-03-event-only-failure`** — *climb the owner chain when Pod-level checks come up empty.* The hardest reflex of the three.

You're done with the baseline tour. See `finish.md`.
