# M19 — Multi-cluster Fleet — Answer Key

> Self-grading reference. Try each scenario first, then check your diagnostic path against the canonical one. Instructors running the lab live can use these sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline + the `edge-relay` fleet repo at `/root/fleet`.

## Lesson summary

M19 scales M16's base/overlay model<sup><a href="https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/">[1]</a></sup> to a fleet: one repo, composed **base → region → cluster** into many clusters that differ along two axes — *where* (region) and *how ripe* (tier). The whole module rests on one skill: `kubectl kustomize clusters/<cluster>` renders exactly what a cluster receives, and any value is attributed by grepping its **layer path** — the last layer to set a field wins (composition order). The `baseline/` scenario tours the healthy fleet. Three break/fix scenarios then fault the same symptom shape — *a value is wrong for one cluster* — in three different layers:

- `breakfix-01-stale-cluster-var` — the value is **stale in its owning layer** (a cloned region overlay)
- `breakfix-02-shadowed-override` — the owning layer is right; a **later layer shadows** it
- `breakfix-03-promotion-wrong-overlay` — the value is right, in the **wrong layer** (wrong blast radius)

The through-line: your first move is always to render the cluster and trace the value to its layer. The layer decides the fix — correct the owning layer, remove the shadow, or move the value to the right layer.

## Baseline tour reference

The baseline has no broken state. Each step has a `verify.sh`; here's what "correct" looks like.

- **Step 1 (the layout):** `kubectl kustomize clusters/prod-us-east-1` renders a composed path — `replicas: 3` (leaf patch), `REGION: us-east-1` and `MAX_SESSIONS: "8000"` (region overlay), and a hash-suffixed `edge-relay-config-<hash>` the Deployment's `envFrom` was rewritten to reference. The leaf's `resources:` names its region; the region's names the base.
- **Step 2 (cluster vars and trace):** `diff <(kubectl kustomize clusters/prod-us-east-1) <(kubectl kustomize clusters/prod-eu-central-1)` shows region-owned vars flipping together (`REGION` us-east-1 → eu-central-1, `MAX_SESSIONS` 8000 → 4000) while leaf-owned `tier: prod` and `replicas: 3` stay identical. `grep -rn MAX_SESSIONS base regions/us-east-1 clusters/prod-us-east-1` shows base=500 (floor) then region=8000 (wins) — the trace algorithm.
- **Step 3 (promotion):** `1.27` renders in lab and stage, `1.25` in prod — a monotonic ladder (no tier behind the one after it). Lab and stage each carry an `images:` pin; prod has none and inherits the base default; the base carries no `images:` transformer (per-tier rollout stays in the leaves).
- **Step 4 (apply and observe):** `kubectl apply -k clusters/prod-us-east-1` lands `edge-relay` at `3/3` on `nginx:1.25`; the live Deployment's `envFrom` names a ConfigMap that exists. The cluster holds only the rendered objects — it has no concept of the fleet.

---

## Break/fix 01 — Stale Cluster Variable

**Symptom:** `edge-relay` in `eu-central-1` is healthy and `Running`, but it emits `us-east-1` in its telemetry. The `prod-eu-central-1` cluster renders and applies cleanly; only the `REGION` value is wrong, and only for this region. The rest of the fleet is fine.

**Root cause:** `regions/eu-central-1/kustomization.yaml` was created by cloning `regions/us-east-1/` and its `REGION` generator literal was never changed — it still reads `us-east-1`. The region overlay is the **owning layer** for `REGION` (a region-scoped cluster variable), so every cluster in `eu-central-1` inherits the stale value<sup><a href="https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/configmapgenerator/">[3]</a></sup>. The `region:` label<sup><a href="https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/labels/">[5]</a></sup> was updated in the clone; the `REGION` config literal was the one line missed. The render is valid and the workload runs — the value is simply stale in the layer that owns it.

**Diagnostic commands (the canonical path):**

```bash
# 1. Confirm healthy, not crashing — this is a wrong value, not a failure
kubectl get pods -n edge -l app=edge-relay          # Running

# 2. Read what the affected cluster actually renders
cd /root/fleet
kubectl kustomize clusters/prod-eu-central-1 | grep -E 'REGION|region:'
#   region: eu-central-1  (label, correct)   REGION: us-east-1  (config, WRONG)

# 3. Trace REGION up the layer path — which layer owns it?
grep -rn REGION base regions/eu-central-1 clusters/prod-eu-central-1
#   only regions/eu-central-1 sets it, and it says us-east-1 — the owning layer is stale

# 4. See the drift against the sibling it was cloned from
diff regions/us-east-1/kustomization.yaml regions/eu-central-1/kustomization.yaml
#   differ on label + MAX_SESSIONS (correct); agree on REGION=us-east-1 (the miss)
```

**Fix:** Correct the value in its owning layer.

```bash
sed -i 's/REGION=us-east-1/REGION=eu-central-1/' regions/eu-central-1/kustomization.yaml
# (us-east-1 appears only on the stale literal in this file, so the substitution is precise.
#  Fix it once here and every cluster in eu-central-1 inherits the correction.)
```

**Verify:**

```bash
kubectl kustomize clusters/prod-eu-central-1 | grep -E 'REGION|region:'   # both eu-central-1
kubectl apply -k clusters/prod-eu-central-1
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
REF=$(kubectl get deploy edge-relay -n edge -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}')
kubectl get configmap "$REF" -n edge -o jsonpath='REGION={.data.REGION}{"\n"}'   # eu-central-1
```

**What this scenario tests:**

- When a fleet value is wrong but the workload is healthy, did you render the cluster instead of reaching for `describe`/`logs` (which have nothing to show)?
- Did you trace the value up its layer path and land on the *one* file that owns it, rather than editing the leaf or the base at random?
- Do you understand that fixing the owning layer corrects every cluster that inherits it — the payoff of one home per variable?

The anti-pattern: patch the live ConfigMap by hand. The next render regenerates the stale value and the drift returns.

**Expected time:** 2–4 min once "healthy but wrong → render and trace" is a reflex; 6–10 min the first time.

**Production thinking:** This is invisible to every runtime check — the Pod is `Ready`, events are clean, `describe` is silent. It's caught at the render, so the guard belongs in CI: assert that each `regions/<r>/` overlay renders `REGION=<r>` (the folder name and the variable must agree). A cloned overlay whose `REGION` still names the sibling then fails the pipeline instead of a customer's telemetry. The fix belongs in git, not a live `kubectl edit` — a GitOps controller (M18) re-renders the committed overlay and would overwrite an out-of-band patch on the next reconcile.

---

## Break/fix 02 — Shadowed Override

**Symptom:** Capacity planning raised the `us-east-1` session ceiling to `8000` in the region overlay, but `prod-us-east-1` still renders `MAX_SESSIONS=5000`. The region file plainly reads `8000`; the render disagrees with it. The cluster is healthy, running on the shadowed `5000`.

**Root cause:** `clusters/prod-us-east-1/kustomization.yaml` carries a leftover per-cluster `configMapGenerator` merge pinning `MAX_SESSIONS=5000`, from before capacity moved to the region layer. Composition order is base → region → cluster, and the **last layer to set a field wins**<sup><a href="https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/">[2]</a></sup>. The cluster overlay writes after the region, so its `5000` shadows the region's new `8000`. The owning layer is correct; a more-specific layer overrides it<sup><a href="https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/configmapgenerator/">[3]</a></sup>. Editing the region changes nothing, because the shadow sits on top of it.

**Diagnostic commands (the canonical path):**

```bash
# 1. The layer you'd fix is already correct; the render disagrees
cd /root/fleet
grep MAX_SESSIONS regions/us-east-1/kustomization.yaml     # 8000
kubectl kustomize clusters/prod-us-east-1 | grep MAX_SESSIONS   # 5000 — the render wins

# 2. Grep the whole path, take the last writer
grep -rn MAX_SESSIONS base regions/us-east-1 clusters/prod-us-east-1
#   base=500, region=8000, cluster=5000 — the cluster writes last, so 5000 wins

# 3. Read the shadow
cat clusters/prod-us-east-1/kustomization.yaml
#   a per-cluster configMapGenerator merge pinning MAX_SESSIONS=5000
```

**Fix:** Remove the shadow so the owning layer's value flows through.

```bash
# delete the leftover per-cluster override block
sed -i '/^# Leftover/,$d' clusters/prod-us-east-1/kustomization.yaml
# (or reconcile it to 8000 if per-cluster capacity were intended — here the
#  standard is regional, so removing the shadow is the correct fix)
```

**Verify:**

```bash
kubectl kustomize clusters/prod-us-east-1 | grep MAX_SESSIONS   # 8000
kubectl apply -k clusters/prod-us-east-1
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
REF=$(kubectl get deploy edge-relay -n edge -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}')
kubectl get configmap "$REF" -n edge -o jsonpath='MAX_SESSIONS={.data.MAX_SESSIONS}{"\n"}'   # 8000
```

**What this scenario tests:**

- When editing the layer that "owns" a value doesn't change the render, did you grep the *whole* path and take the last writer — instead of assuming the region file was being ignored?
- Do you understand composition order well enough to know a cluster overlay always wins over its region, and that a stale per-cluster override therefore shadows every regional update silently?
- Did you remove the shadow rather than duplicate the region's value into the leaf (which would leave two homes for one variable and re-create the drift risk)?

**Expected time:** 3–6 min; longer if you keep re-editing the region file and re-rendering, waiting for it to take.

**Production thinking:** A shadow is a landmine — it silently defeats every future change to the owning layer, forever, with no error. After you move any value to a shared layer (base or region), the operational follow-up is to sweep for leftovers that still set it more specifically: `grep -rn MAX_SESSIONS clusters/` across the fleet. That's a good standing lint, not a one-time cleanup — new overlays clone old ones, and the shadow comes back. This is also the argument for keeping overlays *thin*: the less a leaf sets, the less it can shadow.

---

## Break/fix 03 — Promotion in the Wrong Overlay

**Symptom:** `nginx:1.27` was promoted to stage, but stage still runs `1.25` while prod renders `1.27`. The promotion ladder is non-monotonic — stage is *behind* prod. Two symptoms at once: the target tier didn't advance, and a later tier overshot to a tag it was never approved for.

**Root cause:** The `images:` pin for `1.27` was written into `clusters/prod-us-east-1/kustomization.yaml` instead of `clusters/stage-us-east-1/`. Prod's overlay is supposed to carry no image pin and inherit the base default `1.25`<sup><a href="https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/images/">[4]</a></sup>; the stray pin makes it overshoot the gate to `1.27`, and stage — where the pin belonged — was left on `1.25`. The value is correct; it's in the wrong layer, and **the layer you edit is the blast radius**<sup><a href="https://fluxcd.io/flux/guides/repository-structure/">[6]</a></sup>. Promotion is *moving* a pin one tier at a time, not editing an arbitrary overlay.

**Diagnostic commands (the canonical path):**

```bash
# 1. Read the ladder — it should be monotonic (no tier behind the one after it)
cd /root/fleet
for t in lab stage prod; do echo -n "$t: "; kubectl kustomize clusters/$t-us-east-1 | grep -m1 'image: nginx'; done
#   lab 1.27, stage 1.25, prod 1.27 — stage is behind prod: wrong

# 2. The applied stage cluster confirms the stall
kubectl get deploy edge-relay -n edge -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'   # nginx:1.25

# 3. Find where the pin actually landed
grep -rn 'newTag' clusters/lab-us-east-1 clusters/stage-us-east-1 clusters/prod-us-east-1
#   lab 1.27 (ok), stage 1.25 (never advanced), prod 1.27 (should have NO pin)
cat clusters/prod-us-east-1/kustomization.yaml   # the images: block that doesn't belong
```

**Fix:** Move the pin — advance stage, unpin prod.

```bash
sed -i 's/newTag: "1.25"/newTag: "1.27"/' clusters/stage-us-east-1/kustomization.yaml
sed -i '/^images:/,/newTag/d' clusters/prod-us-east-1/kustomization.yaml
# (by hand: set stage's newTag to 1.27, and delete the whole images: block from prod)
```

**Verify:**

```bash
for t in lab stage prod; do echo -n "$t: "; kubectl kustomize clusters/$t-us-east-1 | grep -m1 'image: nginx'; done
#   lab 1.27, stage 1.27, prod 1.25 — monotonic again
kubectl apply -k clusters/stage-us-east-1
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
kubectl get deploy edge-relay -n edge -o jsonpath='stage running {.spec.template.spec.containers[0].image}{"\n"}'   # nginx:1.27
```

**What this scenario tests:**

- Did you read the *ladder* rather than one tier in isolation? The bug is only visible as a relationship — stage behind prod — not as a single wrong value.
- Do you understand that the layer sets the blast radius, so a per-tier pin in the wrong tier both fails to advance the target and overshoots another?
- Did you *move* the pin (advance one, remove the other) rather than just bumping stage — which would leave prod wrongly on `1.27`?

**Expected time:** 3–6 min; longer if you only fix the tier that's "too low" and miss that prod overshot.

**Production thinking:** A monotonic-ladder check is a cheap, high-value CI gate: render every tier of a workload and assert the promotion order (prod's tag is never ahead of stage's, stage's never ahead of lab's). It catches both a stalled promotion and an overshoot in one assertion. The deeper discipline: promotion is a *move*, ideally a reviewed diff whose only change is the one pin advancing one tier — anything else in the diff is a mistake. And keep per-tier rollouts out of the base entirely; a tag in the base hands every tier the change at once and there is no gate left to catch it. Drift where someone edited a tier directly (rather than promoting into it) is exactly what M18's drift detection exists to surface.

## References

1. Kubernetes — Declarative Management of Kubernetes Objects Using Kustomize: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
2. Kustomize — `kustomization` reference (resources, composition, accumulation order): https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/
3. Kustomize — `configMapGenerator` field reference (`behavior: merge`, name match): https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/configmapgenerator/
4. Kustomize — `images` field reference: https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/images/
5. Kustomize — `labels` / `commonLabels` field reference: https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/labels/
6. Flux — Ways of structuring your repositories (fleet layout, environments, promotion): https://fluxcd.io/flux/guides/repository-structure/
