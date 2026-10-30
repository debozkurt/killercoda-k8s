# M08 — CRDs & Operators — Answer Key

> Self-grading reference. Try each scenario first, then check your diagnostic path against the canonical one here. Instructors running the lab live can use the same sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline plus the `MediaTenant` CRD, the `tenant-operator` and two tenants (`orion`, `lyra`). The baseline tours a healthy operator. Each break/fix breaks one link: the type, the loop, the CRD version, the owner reference or the finalizer.

## Lesson summary

M08 covers the two parts that deliver every capability above the built-in types. A **CustomResourceDefinition** registers a new type, with a schema, so a **custom resource**<sup><a href="https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/">[1]</a></sup> is validated at admission, governed by RBAC and served to `kubectl`<sup><a href="https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/">[2]</a></sup>. A **controller**, paired with the CRD as an **operator**, runs a level-triggered **reconcile loop**: it reads each custom resource's `.spec`, moves the cluster to match and reports in `.status`<sup><a href="https://kubernetes.io/docs/concepts/architecture/controller/">[3]</a></sup>. The operator stamps an **ownerReference** on each child, so the garbage collector removes the children when the custom resource goes. A **finalizer** holds the custom resource until its controller finishes cleanup.

The five break/fix scenarios each produce one signature:

- `breakfix-01-cr-schema-rejected` — **a tenant never appears**: its tier is outside the CRD's enum, so admission rejects it
- `breakfix-02-reconcile-stuck-rbac` — **`Provisioning` and `forbidden`**: the operator's ServiceAccount cannot create Deployments
- `breakfix-03-unserved-crd-version` — **blank `.status` and a list error**: the operator reads a CRD version that a release stopped serving
- `breakfix-04-orphaned-owner-reference` — **a child outlives its tenant**: the Deployment has no ownerReference
- `breakfix-05-finalizer-stuck-terminating` — **`Terminating` forever**: the controller that owns the finalizer is scaled to zero

The through-line: **operators fail quietly.** No scenario leaves a red status. A resource never appears, never progresses, never leaves or never finishes leaving. You catch each one by checking that the link held.

## Baseline tour reference

No broken state. Expected output per step:

- **Step 1 (The CRD):** `kubectl get crd` lists `mediatenants.polyphone.example`. `kubectl describe crd` shows the `Established` condition as `True` and one version, `v1`, with `Served` and `Storage` both true. `kubectl api-resources` shows `MediaTenant` (short name `mt`, group `polyphone.example`, namespaced). `kubectl explain mediatenant.spec` reads the schema: `tier` and `replicas`.
- **Step 2 (Custom resources):** `kubectl get mediatenants -A` shows `orion` (gold, desired 2) and `lyra` (silver, desired 1), both `Ready`. The YAML of `orion` shows `spec`, a `status` the operator wrote through the `/status` subresource, and `metadata.finalizers` with `polyphone.example/media-cleanup`.
- **Step 3 (The operator):** `kubectl get pods -n platform` shows `tenant-operator` as `Running`. The deployments `orion-media` (2) and `lyra-media` (1) exist. The logs show one `phase=Ready readyReplicas=… desired=…` line per tenant, and a first line that names the version the loop reads, `v1`.
- **Step 4 (Owner references):** the YAML of `orion-media` shows an `ownerReferences` entry with `kind: MediaTenant`, `name: orion` and `controller: true`. Its `uid` equals the `uid` of the `orion` tenant<sup><a href="https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/">[4]</a></sup>.
- **Step 5 (Self-heal and cascade):** after `kubectl delete deployment orion-media`, the operator re-creates it within about 15 seconds, and its log shows `creating child deployment orion-media`. After `kubectl delete mediatenant lyra`, the command waits for the operator's `cleanup done, finalizer removed` line, and the garbage collector then removes `lyra-media`, its ReplicaSet and its Pods<sup><a href="https://kubernetes.io/docs/concepts/architecture/garbage-collection/">[5]</a></sup>.

---

## Break/fix 01 — Custom Resource Rejected by Schema

**Symptom:** A new tenant, `vega`, never appears. `kubectl get mediatenants -A` lists two tenants, and no `vega-media` Deployment exists. The operator is healthy and logged nothing about `vega`. The manifest is at `/root/vega-tenant.yaml`.

**Root cause:** The manifest sets `spec.tier: platinum`. The CRD's schema limits `spec.tier` to `gold`, `silver` and `bronze`. The API server validates every custom resource against the schema at admission, so it rejects `vega` and never stores it<sup><a href="https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/">[2]</a></sup>. The operator reconciles only objects that exist. The fault sits upstream of the operator.

**Diagnostic commands (the canonical path):**

```bash
# 1. vega is absent, and so is its child
kubectl get mediatenants -A
kubectl get deployments -n media -l managed-by=tenant-operator

# 2. The rejection names the field, the value and the allowed values
kubectl apply -f /root/vega-tenant.yaml
#    The MediaTenant "vega" is invalid: spec.tier: Unsupported value: "platinum": supported values: "gold", "silver", "bronze"

# 3. Read the schema you must satisfy
kubectl explain mediatenant.spec.tier
```

**Fix:** Set a valid tier and apply again.

```bash
sed -i 's/tier: platinum/tier: gold/' /root/vega-tenant.yaml
kubectl apply -f /root/vega-tenant.yaml
```

**Verify:**

```bash
kubectl get mediatenants -A
sleep 15
kubectl get deployment vega-media -n media     # 3 replicas
```

**What this scenario tests:** That the schema is real validation and that a rejection leaves no downstream trace. Self-grading questions:

- Did you apply the manifest before you looked at the operator, so the API server's message told you the cause?
- Could you say why the operator's logs held nothing about `vega`?
- Did you pick a tier from the enum, and not edit the CRD to accept `platinum`?

<details>
<summary>📖 Going deeper: catch schema errors before the cluster does<sup><a href="https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#field-pruning">[2]</a></sup></summary>

`kubectl apply --dry-run=server` sends the object through admission without storing it, so a pipeline can surface the same error that you read here. Schema validation has a quiet sibling: **pruning**. A field that the schema does not list is removed before the object is stored, with no error. Recent `kubectl` versions reject unknown fields by default. A GitOps controller or a client library may not request that check, so a misspelled optional field can pass and have no effect. When a setting does nothing, compare `kubectl get <kind> -o yaml` with your manifest.

</details>

**Expected time:** 5–8 min.

**Production thinking:** Validate manifests against the CRD's schema in CI, and keep the server-side dry run in the deploy step. A pipeline that discards `kubectl apply` output hides a rejected custom resource, and the first sign is a missing capability. Version the schema with the operator, so an enum widens only when the operator can handle the new value.

---

## Break/fix 02 — Reconciliation Stuck (Operator RBAC)

**Symptom:** `orion` and `lyra` exist and apply cleanly. Both read `PHASE Provisioning` and `READY 0`. The `media` namespace has no child Deployments. The operator Pod is `Running` with no restarts.

**Root cause:** The `tenant-operator` ClusterRole grants only `get`, `list` and `watch` on `deployments`. The loop reads the tenants and tries to create each child, and the API server returns `403 Forbidden`<sup><a href="https://kubernetes.io/docs/concepts/architecture/controller/">[3]</a></sup>. The Pod is alive and the controller makes no progress. The tenants show `Provisioning` because the loop writes that status each pass.

**Diagnostic commands (the canonical path):**

```bash
# 1. Stalled, with nothing built
kubectl get mediatenants -A
kubectl get deployments -n media -l managed-by=tenant-operator

# 2. The Pod is fine, so read the logs
kubectl get pods -n platform
kubectl logs deployment/tenant-operator -n platform --tail=12
#    error: failed to create deployment: deployments.apps is forbidden: User "system:serviceaccount:platform:tenant-operator" cannot create resource "deployments" ...

# 3. Confirm, then read the role
kubectl auth can-i create deployments -n media --as=system:serviceaccount:platform:tenant-operator   # no
kubectl describe clusterrole tenant-operator    # deployments.apps: get list watch only
```

**Fix:** Add the write verbs to the `deployments` rule. The operator needs no restart.

```bash
kubectl patch clusterrole tenant-operator --type=json -p='[{"op":"replace","path":"/rules/2/verbs","value":["get","list","watch","create","update","patch","delete"]}]'
```

**Verify:**

```bash
kubectl auth can-i create deployments -n media --as=system:serviceaccount:platform:tenant-operator   # yes
sleep 15
kubectl get mediatenants -A                                  # Ready
kubectl logs deployment/tenant-operator -n platform --tail=6  # no forbidden errors
```

**What this scenario tests:** That Pod status does not measure a controller's progress, and that the logs name the failing step. Self-grading questions:

- Did you read the tenants' `.status` and the logs before you touched the Pod?
- Did you use `auth can-i --as=` to confirm the identity before you edited the role?
- Did you grant only the verbs the loop uses?

<details>
<summary>📖 Going deeper: what an operator's role should hold<sup><a href="https://kubernetes.io/docs/concepts/architecture/controller/">[3]</a></sup></summary>

List the verbs per resource from the operator's own behavior: read and watch what it reconciles, write `.status` through the `/status` subresource, and create, update and delete only the children it owns. A wildcard role hides a missing verb until an audit finds it. Ship the role next to the operator in one release, so a new feature cannot reach a cluster without its permission. M10 treats RBAC in full.

</details>

**Expected time:** 6–10 min. Lost time usually goes to the Pod: restarts, `describe pod` and image checks.

**Production thinking:** Alert on the gap, not on the Pod. A custom resource that stays `Provisioning` past its normal time is a stuck-reconcile signal. Export a metric such as "age of the oldest unreconciled resource", and page when it grows. Keep the `auth can-i` check in your runbook, because it separates this cause from the next scenario in one command.

---

## Break/fix 03 — Reconciliation Stuck (Unserved CRD Version)

**Symptom:** `orion` and `lyra` exist, but `PHASE` and `READY` are blank and no child Deployments exist. The operator Pod is `Running`. `auth can-i` returns `yes`, so RBAC is fine.

**Root cause:** A CRD release made `v2` the served and stored version and set `served: false` on `v1`. The operator reads `mediatenants.v1.polyphone.example`, so every list call fails and the loop never reaches a tenant. It writes no `.status` and creates no child. The docs warn that clients still on the old version "may begin reporting errors", and tell you to switch the old version back to `served: true`<sup><a href="https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/">[7]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
# 1. Blank status, no children, Pod Running
kubectl get mediatenants -A
kubectl get deployments -n media -l managed-by=tenant-operator
kubectl get pods -n platform

# 2. Rule out RBAC
kubectl auth can-i create deployments -n media --as=system:serviceaccount:platform:tenant-operator   # yes
kubectl auth can-i list mediatenants.polyphone.example --as=system:serviceaccount:platform:tenant-operator   # yes

# 3. The logs name the version
kubectl logs deployment/tenant-operator -n platform --tail=8
#    cannot list mediatenants.v1.polyphone.example: <error>

# 4. The CRD's versions
kubectl describe crd mediatenants.polyphone.example    # v1: Served false.  v2: Served true, Storage true
```

**Fix:** Serve `v1` again. The durable fix upgrades the operator to read `v2`.

```bash
kubectl patch crd mediatenants.polyphone.example --type=json -p='[{"op":"replace","path":"/spec/versions/0/served","value":true}]'
```

**Verify:**

```bash
kubectl describe crd mediatenants.polyphone.example    # both versions served
sleep 15
kubectl get mediatenants -A                            # Ready
kubectl logs deployment/tenant-operator -n platform --tail=6   # no list error
```

**What this scenario tests:** The third cause of stuck reconciliation, and the habit of ruling out the previous one first. Self-grading questions:

- Did you separate this from the RBAC stall with one command, and what did the blank `.status` tell you?
- Could you name the version the operator reads and the versions the CRD serves?
- Would you upgrade the operator and the CRD together next time?

<details>
<summary>📖 Going deeper: retiring a CRD version safely<sup><a href="https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/">[7]</a></sup></summary>

The docs' order: migrate every client to the new version, set `served: false` on the old one, confirm the storage version has moved and that `status.storedVersions` no longer lists the old version, then remove the old version from `spec.versions`. The kube-apiserver logs show which clients still call the old version, so check them before step two. If a consumer breaks, set `served: true` again, migrate that consumer and repeat. With the default `None` conversion the server changes only the `apiVersion` of an object. A schema change between versions needs a conversion webhook.

</details>

**Expected time:** 8–12 min.

**Production thinking:** Ship the operator and its CRD in one release, and gate the release on the operator's startup log: "list succeeded". Keep a version served for a full deprecation window, and use the CRD's deprecation warnings to find stragglers. Alert on a list or watch error rate from the operator, because the Pod's readiness will not move.

---

## Break/fix 04 — Orphaned Child (Missing Owner Reference)

**Symptom:** Tenant `vega` was offboarded and its `MediaTenant` is gone. `vega-media` still runs with two replicas. The operator is healthy, and `orion-media` and `lyra-media` are owned and running.

**Root cause:** `vega-media` carries no `ownerReferences`. An older operator created it before the operator stamped references. The garbage collector deletes objects whose `ownerReferences` name a deleted owner<sup><a href="https://kubernetes.io/docs/concepts/architecture/garbage-collection/">[5]</a></sup>. With no reference, the collector found nothing to follow when the tenant was deleted. The current operator manages only children of tenants that exist, so it never touches the orphan.

**Diagnostic commands (the canonical path):**

```bash
# 1. A child with no living parent
kubectl get mediatenants -A
kubectl get deployments -n media -l managed-by=tenant-operator

# 2. Compare owner references
kubectl get deployment orion-media -n media -o yaml | head -n 30    # ownerReferences: MediaTenant/orion, controller: true
kubectl get deployment vega-media  -n media -o yaml | head -n 30    # no ownerReferences field
```

**Fix:** Delete the orphan. The parent is gone, so no cascade can run.

```bash
kubectl delete deployment vega-media -n media
```

**Verify:**

```bash
kubectl get deployments -n media -l managed-by=tenant-operator     # vega-media gone
kubectl get deployment orion-media -n media -o yaml | head -n 30   # ownerReferences intact
```

**What this scenario tests:** That owner references are the thread the collector follows, and that orphans fail silently. Self-grading questions:

- Did you compare the suspect child with a managed sibling, and not with the operator's logs?
- Could you explain why the operator would never remove `vega-media`?
- Did you remove only the orphan?

<details>
<summary>📖 Going deeper: ways to make an orphan<sup><a href="https://kubernetes.io/docs/tasks/administer-cluster/use-cascading-deletion/">[8]</a></sup></summary>

This scenario shows one cause: a child created without a reference. Two more produce the same state. `kubectl delete --cascade=orphan` leaves the dependents behind on purpose: the API server adds an `orphan` finalizer to the owner, and the collector removes the owner references from the dependents before the owner goes. And a hand edit that clears `ownerReferences` detaches a child. To sweep for orphans, list children by the operator's label and check each one's `ownerReferences` against the owners that exist. A child that points at a deleted owner's uid has the opposite problem: the docs say it "is subject to deletion once all owners are verified absent", so the collector removes it.

</details>

**Expected time:** 5–8 min.

**Production thinking:** Make the operator the only creator of its children, and stamp the owner reference at creation. Add an orphan sweep to your cleanup jobs: a periodic list of children whose owner kind has no matching object. Check cost reports for capacity with no owner, because an orphan holds real resources.

---

## Break/fix 05 — Delete Stuck in Terminating (Finalizer)

**Symptom:** `kubectl delete mediatenant vega` never returned. `vega` still appears in `kubectl get mediatenants`, and `vega-media` still serves. The operator was scaled down for maintenance.

**Root cause:** `vega` carries the finalizer `polyphone.example/media-cleanup`. When you delete an object that has a finalizer, the API server sets `metadata.deletionTimestamp`, keeps the object and returns `202 Accepted`<sup><a href="https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/">[6]</a></sup>. The controller that manages the key must run its cleanup and remove the key. The `tenant-operator` is that controller, and it is scaled to zero, so nobody removes the key and the object stays `Terminating`. `vega-media` keeps running, because cascading deletion starts only after the owner is gone.

**Diagnostic commands (the canonical path):**

```bash
# 1. The tenant is still listed
kubectl get mediatenants -A

# 2. Read the metadata: Deletion Timestamp is set, Finalizers holds the key
kubectl describe mediatenant vega -n media

# 3. Find the controller that owns the key
kubectl get pods -n platform                             # none
kubectl get deployment tenant-operator -n platform       # READY 0/0
```

**Fix:** Restore the controller. It runs its cleanup and removes its own finalizer.

```bash
kubectl scale deployment tenant-operator -n platform --replicas=1
kubectl rollout status deployment/tenant-operator -n platform --timeout=90s
```

**Verify:**

```bash
sleep 10
kubectl logs deployment/tenant-operator -n platform --tail=8    # media/vega: cleanup done, finalizer removed
kubectl get mediatenants -A                                     # vega gone
sleep 10
kubectl get deployments -n media -l managed-by=tenant-operator  # vega-media gone
```

**What this scenario tests:** What a finalizer promises, and why you restore a controller before you edit a key. Self-grading questions:

- Did you read `Deletion Timestamp` and `Finalizers` before you chose a fix?
- Could you name the controller that owns the key, and why it was absent?
- Did you leave the finalizer alone, and what does a hand patch skip?

<details>
<summary>📖 Going deeper: when a hand patch is the right call<sup><a href="https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/">[6]</a></sup></summary>

The docs' note: avoid manually removing finalizers, because "Finalizers are usually added to resources for a reason", and a forced removal "should only be done when the purpose of the finalizer is understood and is accomplished in another way". The patch is `kubectl patch mediatenant vega -n media --type=merge -p '{"metadata":{"finalizers":null}}'`. It is the right call when the operator is gone for good and you have removed the external resource yourself. Record what you cleaned up. A namespace delete wedges the same way: it waits while the namespace holds an object with a finalizer and no controller. List the stuck objects with `kubectl api-resources --verbs=list --namespaced -o name`, and read each one's `finalizers`.

</details>

**Expected time:** 6–10 min. Lost time usually goes to the patch shortcut and its side effects.

**Production thinking:** Uninstall an operator in the right order: delete its custom resources first, wait for the finalizers to clear, then remove the controller and the CRD. Alert on objects with a `deletionTimestamp` older than a threshold. A `Terminating` object is a stuck controller until proven otherwise.

---

## References

1. Kubernetes — Custom Resources: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
2. Kubernetes — Extend the Kubernetes API with CustomResourceDefinitions: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/
3. Kubernetes — Controllers: https://kubernetes.io/docs/concepts/architecture/controller/
4. Kubernetes — Owners and Dependents: https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/
5. Kubernetes — Garbage Collection: https://kubernetes.io/docs/concepts/architecture/garbage-collection/
6. Kubernetes — Finalizers: https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/
7. Kubernetes — Versions in CustomResourceDefinitions: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/
8. Kubernetes — Use Cascading Deletion in a Cluster: https://kubernetes.io/docs/tasks/administer-cluster/use-cascading-deletion/
