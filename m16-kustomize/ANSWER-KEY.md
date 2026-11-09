# M16 — Kustomize Bases & Overlays — Answer Key

> Self-grading reference. Try each scenario first, then compare your diagnostic path with the canonical one. Instructors can use these sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` (kubectl v1.30, Kustomize v5.0.4 built in) with the Polyphone fleet and the `edge-relay` tree at `/root/edge-relay`.

## Lesson summary

M16 teaches the base/overlay model and its four mechanisms: patches, generators, transformers, and components. One idea ties the diagnosis together: **Kustomize renders, it never runs**. A failure therefore lands in one stage, and the stage decides the first command:

| Stage | Trace | First command | Scenario |
|-------|-------|---------------|----------|
| Build | Error, nothing created | `kubectl kustomize <dir>` | `breakfix-01-patch-target-mismatch` |
| Apply | API server rejects an object | `kubectl diff -k <dir>` | `breakfix-03-commonlabels-immutable-selector` |
| Runtime | Pods fail at start | `get → describe → events`, then the render | `breakfix-02-generator-name-mismatch` |
| Wrong render | No error anywhere | `kubectl kustomize <dir>`, read the expected field | `breakfix-04-patch-matches-nothing`, `breakfix-05-hash-disabled-stale-config` |

Five labs is above the usual count. The set is one differential: one lab per stage, plus the two "all green, still wrong" signatures that an SRE meets most often (a change that never reached the render, and a change that reached the cluster and never reached the containers).

## Baseline tour reference

- **Step 1 (the base):** `kubectl kustomize base | grep -n edge-relay-config` prints two lines with the same hashed name: the ConfigMap's `name:` and the Deployment's `configMapRef`. The file `base/deployment.yaml` asks for the plain `edge-relay-config`. The rewrite works because the names match.
- **Step 2 (two overlays):** the lab-versus-prod diff shows `replicas` 1 → 3 (patch), `nginx:1.25` → `1.27` (`images`), `LOG_LEVEL` and `MAX_SESSIONS` (generator merge; `REGION` stays), an `affinity:` block (component), a different hash, and `tier: lab` → `tier: prod`.
- **Step 3 (compare with live):** `kubectl diff -k overlays/prod` prints nothing and exits 0. `get deploy,svc,cm -l app=edge-relay` lists the hashed ConfigMap, because the base generator sets the label through `options.labels`. `describe deploy` shows `Replicas: 3 desired`, `Image: nginx:1.27`, and the hashed name under `Environment Variables from:`.
- **Step 4 (hash contract):** after the edit to 6000, `kubectl diff -k` shows a new ConfigMap and one changed `configMapRef` line, and exits 1. The apply creates a second ReplicaSet, `printenv` reads 6000, and two ConfigMaps exist. `apply -k --prune -l app=edge-relay` prints `configmap/edge-relay-config-<old hash> pruned`, after a `Deprecated:` warning about cluster-scoped pruning.

---

## Break/fix 01 — Patch target mismatch

**Symptom:** the deploy job for the prod promotion exits non-zero. `kubectl get deploy -n edge` prints `No resources found in edge namespace.` The workload is absent, not broken.

**Root cause:** `overlays/prod/replicas-patch.yaml` is a partial Deployment named `edge-relayer`, and the base Deployment is `edge-relay`. A patch file with no `target:` selects the one resource with its own kind and name<sup><a href="https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/">[1]</a></sup>. That resource is missing, so the build fails, and `apply -k` sends nothing to the API server.

**Diagnostic commands (the canonical path):**

```bash
# 1. Nothing exists, so suspect the build
kubectl get deploy -n edge
# No resources found in edge namespace.

# 2. Run the build half and read the error
cd /root/edge-relay
kubectl kustomize overlays/prod; echo "exit=$?"
# error: no matches for Id Deployment.v1.apps/edge-relayer.[noNs];
#   failed to find unique target for patch Deployment.v1.apps/edge-relayer.[noNs]
# exit=1   (newer kubectl prefixes: no resource matches strategic merge patch "...")

# 3. Line up the two names
cat overlays/prod/replicas-patch.yaml   # name: edge-relayer
cat base/deployment.yaml                # name: edge-relay
```

**Fix:**

```bash
sed -i 's/name: edge-relayer/name: edge-relay/' overlays/prod/replicas-patch.yaml
kubectl kustomize overlays/prod | grep -n replicas   # replicas: 3
kubectl apply -k overlays/prod
```

If the base was the side that was renamed, and the rest of the tree expects `edge-relayer`, rename the base instead. Fix the side that drifted.

**Verify:** `kubectl get deploy edge-relay -n edge` reads `READY 3/3`.

**What this scenario tests:** reading a build error when the cluster has nothing to show. Self-grading questions:

- When `apply -k` left no object, did you run `kubectl kustomize` before any `describe`?
- Did you read the identity in the error (`Deployment/edge-relayer`) and compare it with the base?
- Can you say why this patch failed loudly, while the patch in break/fix 04 did not?

**Expected time:** 1–3 min once "nothing exists, read the build" is a reflex; 5–10 min the first time.

**Production thinking:** a build error is a CI gate. Render every overlay on every pull request and fail on a non-zero exit. That catches bad patch targets, wrong paths, and duplicate ids before a person waits on a deploy. Commit the fix: a GitOps controller (M18) renders the committed tree and would undo an edit made only on a machine.

---

## Break/fix 02 — Generator name mismatch

**Symptom:** the deploy job reported success, and `edge-relay` is at 0 of 3 available. Every Pod is in `CreateContainerConfigError`.

**Root cause:** the Deployment's `envFrom` references `edge-relay-conf`, and the generator is `edge-relay-config`. Kustomize rewrites a reference to the hashed name only when the reference names the generator exactly<sup><a href="https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/">[2]</a></sup>. The reference stays bare, and the render holds `edge-relay-config-<hash>` plus a Deployment that asks for a ConfigMap nothing creates. The object is valid, so the API server accepts it. The kubelet then fails the container.

**Diagnostic commands (the canonical path):**

```bash
# 1. Objects exist, so the normal loop works
kubectl get pods -n edge -l app=edge-relay        # CreateContainerConfigError x3
kubectl events -n edge --types=Warning
# (x11 over 4m) ... Error: configmap "edge-relay-conf" not found
# A single earlier "failed to sync configmap cache" line is the first attempt.

# 2. What exists
kubectl get cm -n edge -l app=edge-relay          # edge-relay-config-<hash> only

# 3. The render shows why
cd /root/edge-relay
kubectl kustomize overlays/prod | grep -n edge-relay-conf
#   11:  name: edge-relay-config-<hash>
#   63:            name: edge-relay-conf          <- not rewritten

# 4. Line up the names
grep -n edge-relay-conf base/deployment.yaml base/kustomization.yaml
```

**Fix:**

```bash
sed -i 's/name: edge-relay-conf }/name: edge-relay-config }/' base/deployment.yaml
kubectl kustomize overlays/prod | grep -n edge-relay-conf   # both lines hashed
kubectl apply -k overlays/prod
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```

**Verify:** `kubectl get pods -n edge -l app=edge-relay` shows three new Pods `Running` at 1/1. The changed reference changed the Pod template, so the Deployment rolled to a new ReplicaSet.

**What this scenario tests:** following a runtime failure back to the render. Self-grading questions:

- Did you compare the reference in the render with the generated name, instead of stopping at `describe`?
- Can you state the rewrite rule as a name match?
- Did you resist creating an `edge-relay-conf` ConfigMap by hand? That copy would never receive the next config change.

**Expected time:** 3–5 min; longer if you stop at the event, which says what is missing but not why.

**Production thinking:** a CI check that greps each render for `configMapRef` and `secretRef` names, and confirms that every name is either hashed or a known external object, catches this class before deploy. A policy engine (M20) can reject a Pod template that references a ConfigMap missing from its namespace.

---

## Break/fix 03 — commonLabels and the immutable selector

**Symptom:** `edge-relay` runs the lab spec (1/1, `nginx:1.25`). The promotion to prod exits non-zero, and calls to `edge-relay` started to fail at the same time.

**Root cause:** the prod overlay sets `tier: prod` with `commonLabels`, which writes into metadata, Pod templates, and every selector<sup><a href="https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/labels/">[3]</a></sup>. The Deployment's selector is immutable after creation<sup><a href="https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#label-selector-updates">[4]</a></sup>, so the API server rejects the Deployment. `apply -k` is not a transaction: the Service in the same apply succeeded, its selector gained `tier: prod`, and no running Pod carries that label.

**Diagnostic commands (the canonical path):**

```bash
# 1. Which spec is live
kubectl get deploy edge-relay -n edge -o wide      # 1/1, nginx:1.25, SELECTOR app=edge-relay

# 2. Ask the API server, without changing anything
cd /root/edge-relay
kubectl diff -k overlays/prod                      # exits 2
# The Deployment "edge-relay" is invalid: spec.selector: Invalid value:
#   v1.LabelSelector{MatchLabels:map[string]string{"app":"edge-relay", "tier":"prod"}, ...}: field is immutable

# 3. Live selector versus rendered selector
kubectl describe deploy edge-relay -n edge         # Selector: app=edge-relay
kubectl kustomize overlays/prod | grep -n -A3 'selector:'   # Service and Deployment gain tier: prod

# 4. Why calls fail
kubectl describe svc edge-relay -n edge            # Selector: app=edge-relay,tier=prod / Endpoints: <none>

# 5. The transformer
cat overlays/prod/kustomization.yaml               # commonLabels: tier: prod
```

**Fix:** replace `commonLabels` with the `labels:` transformer, which leaves selectors alone:

```bash
sed -i 's/^commonLabels:/labels:\n  - pairs: { tier: prod }\n    includeSelectors: false/; /^  tier: prod$/d' \
  overlays/prod/kustomization.yaml
kubectl diff -k overlays/prod        # replicas, image, labels change; Service selector loses tier
kubectl apply -k overlays/prod
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```

If the label must be in the selector, the only path is to delete and recreate the Deployment, which is an outage. Keep selector labels out of promotions.

**Verify:** `kubectl get deploy edge-relay -n edge -o wide --show-labels` shows 3/3 on `nginx:1.27`, `SELECTOR app=edge-relay`, and `tier=prod` in the labels. `kubectl describe svc edge-relay -n edge` shows `Selector: app=edge-relay` and three endpoint addresses.

**What this scenario tests:** reading an apply-stage rejection, and noticing what the partial apply already changed. Self-grading questions:

- Did you run `kubectl diff -k` before applying again?
- Did you connect the selector change to `commonLabels`, and know that `labels:` with `includeSelectors: false` is the safe form?
- Did you find the Service with no endpoints, and explain why a rejected apply changed it?

**Expected time:** 4–8 min; longer if you try to edit the live Deployment's selector.

**Production thinking:** run `kubectl diff -k` (a server-side dry run) against each environment in the pipeline before the apply, so an immutable-field rejection fails the job before any object changes. Promote through a stage environment first: the rejection then appears where the blast radius is small. Newer `kubectl` versions print a deprecation warning for `commonLabels`; treat that warning as a lint failure.

---

## Break/fix 04 — Patch matches nothing

**Symptom:** prod runs 1 replica of `edge-relay` and is planned at 3. The deploy job passed, the rollout completed, and the Pod is `Running` and `Ready`.

**Root cause:** the prod overlay's replicas change is an inline JSON 6902 patch with `target: {kind: Deployment, name: relay}`. A target is a selector, and its `name` is an anchored regular expression<sup><a href="https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/">[1]</a></sup>: `relay` means `^relay$`. No Deployment carries that name. A selector that matches zero resources is not an error, so Kustomize applied the patch to nothing and exited 0.

**Diagnostic commands (the canonical path):**

```bash
# 1. All green
kubectl get deploy edge-relay -n edge            # READY 1/1

# 2. The cluster matches the render, so the render is the problem
cd /root/edge-relay
kubectl diff -k overlays/prod; echo "exit=$?"    # no output, exit=0
kubectl kustomize overlays/prod | grep -n replicas   # replicas: 1

# 3. The mechanism that should set 3
cat overlays/prod/kustomization.yaml
# patches:
#   - target: { kind: Deployment, name: relay }
```

**Fix:**

```bash
sed -i 's/name: relay }/name: edge-relay }/' overlays/prod/kustomization.yaml
kubectl kustomize overlays/prod | grep -n replicas   # replicas: 3
kubectl apply -k overlays/prod
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```

**Verify:** `kubectl get deploy edge-relay -n edge` reads `READY 3/3`.

**What this scenario tests:** distrusting a green pipeline when an intended change is missing. Self-grading questions:

- Did `kubectl diff -k` exit 0 tell you to look at the render instead of the cluster?
- Did you read the field you expected (`replicas`) in the render before you read the overlay?
- Can you explain why break/fix 01 failed the build and this patch did not?

**Expected time:** 3–6 min once "green but wrong means read the render" is a reflex; 10–15 min the first time.

**Production thinking:** a selector patch trades loudness for reach. Keep a per-overlay assertion in CI, for example a render of prod that must contain `replicas: 3` for `edge-relay`, so a dropped patch fails the pipeline. Use a patch file with no target when the change is meant for exactly one resource; then a rename breaks the build instead of shipping without the change. Review a selector-based patch together with the list of resources it should match.

---

## Break/fix 05 — Hash disabled, stale config

**Symptom:** `MAX_SESSIONS` was raised from 5000 to 6000 and the deploy passed, and the relay still enforces 5000. Every Pod is `Running` and `Ready`.

**Root cause:** the prod overlay sets `generatorOptions: {disableNameSuffixHash: true}`<sup><a href="https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/generatoroptions/">[5]</a></sup>, so the ConfigMap keeps the fixed name `edge-relay-config`. The change updated that ConfigMap in place. The Pod template names the same ConfigMap as before, so it did not change, and the Deployment did not roll. ConfigMaps consumed as environment variables "are not updated automatically and require a pod restart"<sup><a href="https://kubernetes.io/docs/concepts/configuration/configmap/#using-configmaps-as-files-from-a-pod">[6]</a></sup>, so every container still holds 5000.

**Diagnostic commands (the canonical path):**

```bash
# 1. The containers and the ConfigMap disagree
kubectl exec -n edge deploy/edge-relay -- printenv MAX_SESSIONS   # 5000
kubectl get cm -n edge -l app=edge-relay                          # edge-relay-config, no hash
kubectl describe cm edge-relay-config -n edge                     # MAX_SESSIONS: 6000

# 2. Nothing rolled
kubectl rollout history deployment/edge-relay -n edge             # 1 revision

# 3. The render has no hash
cd /root/edge-relay
kubectl kustomize overlays/prod | grep -n edge-relay-config       # both lines bare
cat overlays/prod/kustomization.yaml                              # generatorOptions: disableNameSuffixHash: true
```

**Fix:** restore the hash, and remove the old ConfigMap with `--prune`:

```bash
sed -i '/^generatorOptions:/,/disableNameSuffixHash/d' overlays/prod/kustomization.yaml
kubectl diff -k overlays/prod     # new hashed ConfigMap; configMapRef name changes
kubectl apply -k overlays/prod --prune -l app=edge-relay
# ... configmap/edge-relay-config pruned
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```

`kubectl rollout restart deployment/edge-relay -n edge` loads 6000 today, and the next config change fails the same way. Use it only as a stopgap while the overlay fix goes through review.

**Verify:** `kubectl exec -n edge deploy/edge-relay -- printenv MAX_SESSIONS` prints 6000, and `kubectl rollout history` shows revision 2.

**What this scenario tests:** separating "the config object changed" from "the running containers changed". Self-grading questions:

- Did you compare the container's environment with the ConfigMap before you read any Kustomize file?
- Did `rollout history` tell you that nothing restarted, and did you connect that to the unchanged ConfigMap name?
- Did you fix the cause (the disabled hash) and not only the symptom (a restart)?

**Expected time:** 4–8 min; longer if you restart the Deployment and stop there.

**Production thinking:** the hash was disabled to stop old ConfigMaps from accumulating. Solve that problem with pruning instead: `apply -k --prune -l <selector>` in the pipeline, or the garbage collection of a GitOps controller (M18). If a fixed name is truly required, for example because another system reads the ConfigMap by name, add a checksum annotation to the Pod template so that each config change still changes the template. Alert when a Pod started before the last update of a ConfigMap it reads through `envFrom`; the update time is in the ConfigMap's `managedFields`.

## References

1. Kustomize — `patches` field reference: https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/
2. Kubernetes — Declarative Management of Kubernetes Objects Using Kustomize: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
3. Kustomize — `labels` field reference: https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/labels/
4. Kubernetes — Deployments, label selector updates: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#label-selector-updates
5. Kustomize — `generatorOptions` field reference: https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/generatoroptions/
6. Kubernetes — ConfigMaps (environment variables are not updated automatically): https://kubernetes.io/docs/concepts/configuration/configmap/#using-configmaps-as-files-from-a-pod
