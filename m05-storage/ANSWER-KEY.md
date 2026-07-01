# M05 — Storage: PersistentVolumes, Claims & StorageClasses — Answer Key

> Self-grading reference. Try each scenario first, then come back here to check your diagnostic path against the canonical one. Instructors running the lab live can use the same sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline. No new workloads — the scenarios mutate the fleet's existing PVC-backed workloads (`cdr-writer`, `directory`). The class throughout is `local-path` (dynamic, `WaitForFirstConsumer`, RWO, `Delete`-policy).

## Lesson summary

M05 is about durable storage: how a Pod gets a volume that outlives it, and the three places a Pod stops before it ever runs. The `baseline/` scenario tours healthy mechanics — a `Bound` PVC and the PV a StorageClass provisioned, `WaitForFirstConsumer` binding, data surviving a Pod delete, and the `get pvc` triage. The three break/fix scenarios walk the storage differential top to bottom, one `get pvc` signature each:

- `breakfix-01-pvc-storageclass-missing` — **claim `Pending`**: the claim can't bind because its StorageClass doesn't exist
- `breakfix-02-pvc-claim-missing` — **claim absent**: the Pod names a `claimName` that was never created
- `breakfix-03-rwo-multi-attach` — **claim `Bound`, Pod still stuck**: an RWO volume asked to back Pods on two nodes

The single through-line: **a Pod stuck on storage is a claim that isn't delivering its volume — run `kubectl get pvc` first and read the claim, not the Pod.** The claim's state (`Pending` / absent / `Bound`) is the whole differential; the Pod's `Pending` only tells you it's stuck.

## Baseline tour reference

No broken state. Expected output per step:

- **Step 1 (a claim, a volume, a class):** `kubectl get pvc -A` shows the fleet's claims `Bound`. `describe pvc cdr-data -n cdr-storage` shows `Status: Bound`, `Capacity: 1Gi`, `Access Modes: RWO`, `StorageClass: local-path`, and the `Volume:` (PV) it bound to. `kubectl get pv` shows that PV with `CLAIM: cdr-storage/cdr-data`. `kubectl get storageclass` shows one class, `local-path`. Teaching point: PVC = request, PV = volume, SC = the recipe that provisioned it; the Pod names only the claim.
- **Step 2 (dynamic provisioning & WaitForFirstConsumer):** `get storageclass local-path -o yaml` shows `provisioner: rancher.io/local-path`, `reclaimPolicy: Delete`, `volumeBindingMode: WaitForFirstConsumer`. A freshly-created PVC with no consumer sits `Pending` with event `waiting for first consumer to be created before binding` — **healthy, not broken**. Teaching point: `Pending` means "broken" only once a Pod is using the claim and it still won't bind.
- **Step 3 (access modes & persistence):** `get pv` shows `ACCESS MODES: RWO`; `describe pv` shows the PV's node affinity pinning it to one node. Writing a file into `cdr-writer`'s `/data`, deleting the Pod, and reading it from the replacement Pod shows the data survived — it lives in the PV, not the Pod.
- **Step 4 (the get pvc triage):** `kubectl get pvc -A` is the first look; `STATUS` splits every storage-stuck Pod into `Bound` / `Pending` / absent. `describe pod` shows the Pod's `Volumes:` referencing the claim by `ClaimName` — the only storage reference the Pod holds.

---

## Break/fix 01 — PVC won't bind (missing StorageClass)

**Symptom:** `cdr-writer` in `cdr-storage` is stuck `Pending` from cluster start, with no logs and nothing crashing. Its container never ran — it's waiting on storage.

**Root cause:** The `cdr-data` PVC sets `storageClassName: fast-ssd`, and no such class exists on the cluster. With no StorageClass there is no provisioner to call, so no PV is ever created and the claim stays `Pending` forever<sup><a href="https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/">[1]</a></sup>. A Pod that mounts a `Pending` claim can't be scheduled, so `cdr-writer` is `Pending` too. The claim is where the diagnosis lives — the Pod is one object downstream.

**Diagnostic commands (the canonical path):**

```bash
# 1. The Pod is Pending; its events point at storage, not a crash
kubectl get pods -n cdr-storage
kubectl describe pod -n cdr-storage -l app=cdr-writer | grep -A5 Events
#    ... pod has unbound ... PersistentVolumeClaims

# 2. First look — the claim's status is the diagnosis
kubectl get pvc -n cdr-storage
#    cdr-data   Pending

# 3. Why can't it bind? Ask the claim directly
kubectl describe pvc cdr-data -n cdr-storage | grep -A3 Events
#    storageclass.storage.k8s.io "fast-ssd" not found

# 4. Confirm the class doesn't exist
kubectl get storageclass
#    only local-path — there is no fast-ssd
```

A Pod IS using this claim, so `Pending` here is broken, not the healthy `WaitForFirstConsumer` case.

**Fix:** Point the claim at the real class, `local-path`. `storageClassName` is **immutable**, so this is a delete-and-recreate, not an edit — safe because the claim never bound (no data). Drain the consumer first so the delete doesn't block on it:

```bash
kubectl scale deployment cdr-writer -n cdr-storage --replicas=0
kubectl delete pvc cdr-data -n cdr-storage
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: cdr-data, namespace: cdr-storage }
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: local-path
  resources: { requests: { storage: 1Gi } }
EOF
kubectl scale deployment cdr-writer -n cdr-storage --replicas=1
```

**Verify:**

```bash
kubectl get pvc cdr-data -n cdr-storage        # Bound
kubectl wait --for=condition=Ready pod -l app=cdr-writer -n cdr-storage --timeout=60s
```

**What this scenario tests:** The `get pvc` reflex and the dynamic-provisioning chain (PVC → StorageClass → PV). Self-grading questions:

- Was `kubectl get pvc` one of your first three commands, rather than describing the Pod in circles?
- Did you read `describe pvc` for the *reason* (`storageclass ... not found`) instead of guessing?
- Did you hit the immutability of `storageClassName` and recreate the claim, rather than fighting a rejected `edit`/`patch`?

**Expected time:** 3–6 min once `get pvc` is a reflex; 10–15 the first time (lost time goes to `describe pod`/logs on a container that never started, and to trying to edit an immutable field).

**Production thinking:** A `storageClassName` typo or an uninstalled class fails *every* claim that names it, silently, at apply time — the workload just never comes up. Guard it by pinning workloads to StorageClasses that exist in every target cluster (or leaning on a well-known default), and by alerting on PVCs `Pending` beyond a threshold with a consumer present. The immutability of `storageClassName` is the sharp edge: fixing a wrong class on a claim that already holds data isn't a one-liner — it's a data migration (provision a new PVC on the right class, copy, cut over), which is why getting the class right at creation matters.

---

## Break/fix 02 — Pod names a claim that isn't there

**Symptom:** `directory` in `app-services` is stuck `Pending`. Looks like break/fix 01 — a Pod waiting on storage — but `describe pod` names a different cause: the claim the Pod mounts isn't present at all.

**Root cause:** The `directory` Deployment's Pod template mounts a volume with `claimName: directory-store`, but no PVC by that name exists — the real claim is `directory-data`. A Pod references a PVC by exact name within its own namespace; a name that matches nothing means the Pod waits for a volume that was never requested<sup><a href="https://kubernetes.io/docs/concepts/storage/persistent-volumes/">[2]</a></sup>. This is the *absent-claim* leaf, distinct from break/fix 01's *Pending-claim* leaf.

**Diagnostic commands (the canonical path):**

```bash
# 1. Pending Pod — this time the event names the exact claim
kubectl describe pod -n app-services -l app=directory | grep -A5 Events
#    persistentvolumeclaim "directory-store" not found

# 2. What is the Pod actually mounting?
kubectl describe pod -n app-services -l app=directory | grep -A6 Volumes
#    ClaimName:  directory-store

# 3. First look — list the claims that exist
kubectl get pvc -n app-services
#    directory-data   Pending    <-- exists; healthy WaitForFirstConsumer (no consumer yet)
#    (no directory-store at all — that's the claim the Pod named)
```

The discriminator vs break/fix 01: there the named claim (`cdr-data`) was present but `Pending`; here the named claim (`directory-store`) is not in the list at all. Don't be thrown that `directory-data` shows `Pending` — that's the healthy `WaitForFirstConsumer` (the mis-pointed Pod never consumed it); the bug is that the Pod names a claim that was never created. Correlate the Pod's `claimName` with the list, not just the claim statuses.

**Fix:** Point the Deployment's `claimName` at the claim that exists. Unlike `storageClassName`, `claimName` is freely mutable — editing the Pod template rolls a new Pod:

```bash
kubectl patch deployment directory -n app-services --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/volumes/0/persistentVolumeClaim/claimName","value":"directory-data"}]'
# or: kubectl edit deployment directory -n app-services   → claimName: directory-data
```

**Verify:**

```bash
kubectl wait --for=condition=Ready pod -l app=directory -n app-services --timeout=60s
kubectl get deploy directory -n app-services \
  -o jsonpath='{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}'; echo   # directory-data
```

**What this scenario tests:** That the Pod↔PVC link is by name+namespace, and that `get pvc` distinguishes *absent* from *Pending*. Self-grading questions:

- Did you correlate the Pod's `claimName` with the `get pvc` list — noticing `directory-store` is absent — rather than fixating on `directory-data` showing `Pending`?
- Did you read `describe pod`'s `persistentvolumeclaim "..." not found` as "wrong/missing name," not "provisioning failure"?
- Did you fix the reference rather than creating a redundant `directory-store` PVC to satisfy the typo?

**Expected time:** 2–4 min; 6–10 the first time (lost time usually goes to mistaking `directory-data`'s healthy `WaitForFirstConsumer` `Pending` for the bug).

**Production thinking:** This ships from a rename that touched one side and not the other — someone renamed the PVC, or copy-pasted a volume block from another workload, and the Deployment's `claimName` drifted from reality. No storage is unhealthy; the Pod just points at nothing. Keep the PVC and the `claimName` in one templated source (Kustomize/Helm, M16–M17) so they can't diverge, and remember that creating a second PVC to match a typo'd name "fixes" the symptom while doubling your volumes and splitting your data — correct the reference, don't duplicate the claim.

---

## Break/fix 03 — RWO volume can't span two nodes

**Symptom:** `directory` in `app-services` was scaled to 2 replicas. One is `Running`, the other is stuck (`Pending`/won't schedule). `kubectl get pvc` shows `directory-data` `Bound` — the storage exists and bound cleanly, yet a Pod can't start.

**Root cause:** `directory-data` is `ReadWriteOnce` — mountable read-write by a single *node* at a time<sup><a href="https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes">[3]</a></sup>. The two replicas were forced onto two different nodes; the first attached the volume on its node, and the second, on the other node, can't attach the same RWO volume. Because this is a node-local volume, the conflict surfaces as `volume node affinity conflict` (the PV carries a hard node affinity); on a cloud block volume the identical rule appears as `Multi-Attach error for volume ... already exclusively attached to one node`. The claim being `Bound` while a Pod is stuck is the signature that the failure is at **attach**, not binding.

**Diagnostic commands (the canonical path):**

```bash
# 1. One replica up, one stuck — and they're on different nodes
kubectl get pods -n app-services -l app=directory -o wide

# 2. First look — the claim is Bound (NOT the black hole / not absent)
kubectl get pvc -n app-services
#    directory-data   Bound

# 3. Why is the second replica stuck? Read the scheduling failure
kubectl describe pod -n app-services -l app=directory | grep -A6 Events
#    ... node(s) had volume node affinity conflict ...

# 4. Where is the volume pinned?
PV=$(kubectl get pvc directory-data -n app-services -o jsonpath='{.spec.volumeName}')
kubectl describe pv "$PV" | grep -A3 'Node Affinity'
#    the PV is tied to the node running the healthy replica
```

`Bound` claim + stuck Pod = attach/access-mode problem, never a binding one.

**Fix:** Stop asking one RWO volume to back Pods on two nodes — run a single node-bound consumer:

```bash
kubectl scale deployment directory -n app-services --replicas=1
```

**Verify:**

```bash
kubectl rollout status deployment directory -n app-services --timeout=60s
kubectl get pods -n app-services -l app=directory -o wide     # one Running/Ready, none stuck
```

**What this scenario tests:** The access modes, and reading the `Bound`-but-stuck signature as an attach problem. Self-grading questions:

- Did the `Bound` claim stop you from chasing a provisioning bug (there wasn't one) and point you at the access mode instead?
- Did you read `ReadWriteOnce` as "one *node*," not "one Pod" — and recognize `volume node affinity conflict` / `Multi-Attach` as the same rule?
- Did you land on scaling to one node-bound consumer (or a genuine RWX / `volumeClaimTemplates` design), rather than deleting the stuck Pod and watching it come back?

**Expected time:** 4–8 min; 10–15 the first time (lost time goes to re-checking the `Bound` claim and restarting the healthy replica).

**Production thinking:** This is the failure that hides in a single-node dev cluster and detonates in a multi-node one: two replicas on one node share an RWO volume fine, so it "works" in test, then the moment the scheduler spreads them the second replica jams. The design question is what the workload actually needs — a *shared* multi-writer volume means RWX (network file storage, or a CSI driver that advertises RWX), while a *per-replica* durable volume means a StatefulSet with `volumeClaimTemplates` (M07), one PVC per Pod, no sharing. Scaling to one is the incident fix; picking the right access mode and volume topology for the access pattern is the durable one. And `ReadWriteOncePod` is worth knowing as the stricter cousin — one *Pod*, not one node — for volumes that must never be shared even on the same machine.

## References

1. Kubernetes — Dynamic Volume Provisioning: https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/
2. Kubernetes — Persistent Volumes: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
3. Kubernetes — Access Modes: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes
