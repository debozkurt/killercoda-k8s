# M18 — Flux (GitOps Delivery) — Answer Key

> Self-grading reference. Try each scenario first, then check your diagnostic path against the canonical one. Instructors running the lab live can use these sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline, the `flux` CLI (v2), an in-cluster Gitea git server, and a config repo mirrored at `/root/polyphone-config`. Flux is installed with `flux install` (no bootstrap), so the Flux custom resources are applied directly and are fixed with `kubectl`/`flux`, not git commits.

## Lesson summary

M18 teaches GitOps with Flux — git as declared state, an in-cluster controller reconciling the cluster to match it — and the three ways the pipeline stalls without touching your workload. The `baseline/` scenario tours a healthy pipeline: a `GitRepository` source and its artifact, an `apps` Kustomization applying the repo, drift correction reverting a hand-scaled Deployment, and a `voicemail` HelmRelease ordered after `apps` by `dependsOn`. Three break/fix scenarios isolate one failure each:

- `breakfix-01-source-ref-not-found` — *a source pointed at a non-existent branch produces no artifact; every consumer stalls on it*
- `breakfix-02-kustomization-suspended` — *a suspended consumer stops reconciling, so drift never corrects and looks healthy*
- `breakfix-03-helmrelease-dependency` — *a release blocked by a `dependsOn` naming an object that doesn't exist*

The through-line: read Flux's own objects top-down — source, then consumer, then the managed workload — because the diagnosis lives in their `Ready` conditions, not in the workload.

## Baseline tour reference

No broken state. Each step produces predictable output.

- **Step 1 (Flux and its sources):** `flux check` shows source/kustomize/helm controllers green. `flux get sources git` shows `polyphone-config` `READY True`, message `stored artifact for revision 'main@sha1:...'`. `flux get all` is the whole pipeline in one view.
- **Step 2 (the Kustomization):** `flux get kustomizations` shows `apps` `READY True`, `Applied revision: main@sha1:...`. It built `./apps` and applied `dialplan` into `app-services` (`targetNamespace`); `flux tree kustomization apps` lists what it manages. The Flux `Kustomization` CRD is not the `kustomization.yaml` file it builds.
- **Step 3 (drift correction):** `kubectl scale deployment dialplan --replicas=5` drifts it; `flux reconcile kustomization apps --with-source` (or waiting one interval) reverts it to the git-declared 2 via server-side apply. Flux owns the field; fix in git, not with `kubectl`.
- **Step 4 (HelmRelease and dependencies):** `flux get helmreleases` shows `voicemail` `READY True`; its chart is sourced from the GitRepository (`./charts/voicemail`), and `helm list -n app-services` shows the real release. `spec.dependsOn: [{name: apps}]` ordered it after the Kustomization.

---

## Break/fix 01 — Source Ref Not Found

**Symptom:** A configured Flux pipeline delivers nothing. `dialplan` and `voicemail` are absent from `app-services`, no Pod is crashing or `Pending`, and `flux get all` shows consumers that aren't ready but don't obviously *fail*.

**Root cause:** The `GitRepository` `spec.ref.branch` is `release-2024`, a branch the repo never had (it has only `main`). source-controller can't resolve `refs/heads/release-2024`, so it produces no artifact and reports `Ready: False`. Every consumer downstream (`apps` Kustomization, `voicemail` HelmRelease) has no content to apply and stalls waiting on the source<sup><a href="https://fluxcd.io/flux/components/source/gitrepositories/">[1]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
# 1. Confirm the workloads are genuinely absent (not crashing)
kubectl get deploy -n app-services -l 'app in (dialplan,voicemail)'   # nothing

# 2. Read the SOURCE first — top of the pipeline
flux get sources git
# polyphone-config  READY False  message: couldn't find remote ref 'refs/heads/release-2024'
kubectl describe gitrepository polyphone-config -n flux-system | sed -n '/Conditions:/,$p'

# 3. Confirm consumers are only *waiting*, not independently broken
flux get kustomizations        # apps: not ready, blocked on the source
flux get helmreleases          # voicemail: not ready

# 4. Read the ref the source is pointed at
kubectl get gitrepository polyphone-config -n flux-system -o jsonpath='{.spec.ref}{"\n"}'
# {"branch":"release-2024"}  -> a branch that doesn't exist
```

**Fix:** Point the source at the branch that exists, then reconcile:

```bash
kubectl patch gitrepository polyphone-config -n flux-system \
  --type=merge -p '{"spec":{"ref":{"branch":"main"}}}'
flux reconcile source git polyphone-config
flux reconcile kustomization apps --with-source
```

**Verify:**

```bash
flux get sources git                                   # READY True, stored artifact for main@sha1:...
kubectl get deploy dialplan -n app-services            # READY 2/2
```

**What this scenario tests:**

- Did you read the **source** before the consumers? A pipeline delivering nothing is almost always a stalled source, and the consumers' messages point back at it.
- Did you recognize that "nothing deployed, nothing crashing" is a *reconcile* failure, not a workload failure — so there's no Pod to describe?
- Did you read the `Ready` condition message, which names the exact failing ref?

The anti-pattern: hunt through `app-services` for a broken Pod, or blame RBAC/scheduling, when the failure is one object up the chain and the message already names it.

**Expected time:** 3–7 minutes. Fast once "source first" is a reflex; slow if you start at the missing workload.

**Production thinking:** The `kubectl patch` fixes this cluster. In a bootstrapped setup the `GitRepository` manifest lives in git, so the durable fix is a reviewed commit correcting `spec.ref.branch` — otherwise the next reconcile of Flux's own config reapplies `release-2024`. This class of failure is invisible to Pod-level alerting (nothing crashes), so alert on Flux objects: `Ready: False` on sources, or source revision lagging git HEAD.

---

## Break/fix 02 — Kustomization Suspended

**Symptom:** Drift that Flux corrected instantly in the baseline now persists. `dialplan` runs 5 replicas; git declares 2; Flux isn't pulling it back. The source is healthy and `flux get all` looks fine at a glance.

**Root cause:** The `apps` Kustomization has `spec.suspend: true`. A suspended object doesn't reconcile — no drift correction, no new commits applied, no pruning — and it reports its last (healthy-looking) state, so nothing errors<sup><a href="https://fluxcd.io/flux/components/kustomize/kustomizations/">[2]</a></sup>. The hand-scaled 5 replicas (an out-of-band change from an incident) is never reverted because the controller that would revert it is paused.

**Diagnostic commands (the canonical path):**

```bash
# 1. Confirm the drift: live vs git
kubectl get deploy dialplan -n app-services            # READY 5/5
grep replicas /root/polyphone-config/apps/dialplan.yaml # replicas: 2

# 2. Rule out the source (top-down)
flux get sources git                                   # polyphone-config READY True

# 3. Read the consumer — the SUSPENDED column is the tell
flux get kustomizations                                # apps  SUSPENDED True
kubectl get kustomization apps -n flux-system -o jsonpath='{.spec.suspend}{"\n"}'   # true
```

**Fix:** Resume reconciliation; Flux corrects the drift on the first pass:

```bash
flux resume kustomization apps
```

**Verify:**

```bash
flux get kustomizations                                # apps  SUSPENDED False  READY True
kubectl get deploy dialplan -n app-services            # READY 2/2 (drift corrected)
```

**What this scenario tests:**

- Did you notice the `SUSPENDED` column instead of trusting a green-looking `READY`? A suspended object hides in plain sight because it reports its last state.
- Did you separate "drift not corrected" (reconciliation is off) from "source broken" (fetch failed)? Different layer, different fix.
- Did you recover with `flux resume` rather than re-scaling by hand (which suspend would just... not revert, masking the real issue)?

The anti-pattern: `kubectl scale dialplan --replicas=2` to "fix" it. It papers over the symptom while reconciliation stays off — the next drift (or a needed git change) still won't apply, and you've hidden the suspended consumer.

**Expected time:** 3–6 minutes. The slow part is trusting a green dashboard and not checking the suspend state.

**Production thinking:** `flux resume` is the recovery. Two durable lessons: the emergency scale to 5 was lost because it lived only in the cluster — if 5 was correct it belonged in a git commit; and `suspend` during an incident needs a tripwire (an alert on suspended Flux objects, or a runbook step to `resume`) so it isn't silently forgotten, quietly stopping all delivery for that object.

---

## Break/fix 03 — HelmRelease Dependency

**Symptom:** The `voicemail` HelmRelease is stuck `READY False` and never installs — no `voicemail` Deployment in `app-services` — even though the source is `Ready`, the `apps` Kustomization is `Ready`, `dialplan` is running, and the chart renders.

**Root cause:** `spec.dependsOn` names a Kustomization called `platform-config` that doesn't exist; the real one applied by this repo is `apps`. `dependsOn` gates a release until every listed object is `Ready`, and an object that doesn't exist can never be ready, so helm-controller holds the release as `DependencyNotReady` indefinitely<sup><a href="https://fluxcd.io/flux/components/helm/helmreleases/">[3]</a></sup>. This is Flux waiting correctly on a reference that happens to be wrong (a typo or a stale rename).

**Diagnostic commands (the canonical path):**

```bash
# 1. Read the release's Ready condition — it says why it's waiting
flux get helmreleases
# voicemail  READY False  message: dependency 'flux-system/platform-config' is not ready
kubectl get helmrelease voicemail -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].reason}{"\n"}'   # DependencyNotReady

# 2. Does the named dependency exist?
flux get kustomizations                                # only 'apps' — no 'platform-config'
kubectl get helmrelease voicemail -n flux-system -o jsonpath='{.spec.dependsOn}{"\n"}'
# [{"name":"platform-config"}]  -> points at nothing

# 3. Rule out the other layers
flux get sources git                                   # READY True
kubectl get deploy dialplan -n app-services            # READY 2/2
```

**Fix:** Point `dependsOn` at the Kustomization that actually exists, then reconcile:

```bash
kubectl patch helmrelease voicemail -n flux-system \
  --type=merge -p '{"spec":{"dependsOn":[{"name":"apps"}]}}'
flux reconcile helmrelease voicemail
```

**Verify:**

```bash
flux get helmreleases                                  # voicemail READY True
helm list -n app-services                              # voicemail deployed
kubectl get deploy voicemail -n app-services           # READY 2/2
```

**What this scenario tests:**

- Did you read *why* the release said it wasn't ready (`DependencyNotReady`) instead of assuming a render or install failure? A blocked release is different from a failed one.
- Did you verify the named dependency exists (`flux get kustomizations`) — turning "waiting" into "waiting on nothing"?
- Did you confirm the rest of the pipeline was healthy, isolating the fault to the reference?

The anti-pattern: dig into the chart, values, or helm-controller logs looking for a render error — when the release never got as far as rendering, because its dependency gate never opened.

**Expected time:** 3–6 minutes. The `dependsOn` message is self-describing once you read the condition instead of the (absent) workload.

**Production thinking:** The `kubectl patch` fixes this cluster; the durable fix corrects the `dependsOn` name in the `HelmRelease` in git, ideally with CI that validates references so a stale rename can't ship. And keep `dependsOn` honest — list only genuine ordering needs, because every dependency is one more thing that can block the release, and `dependsOn` waits for `Ready` at install, not for continued health afterward.

## References

1. Flux — GitRepository API — https://fluxcd.io/flux/components/source/gitrepositories/
2. Flux — Kustomization API (suspend, drift) — https://fluxcd.io/flux/components/kustomize/kustomizations/
3. Flux — HelmRelease API (dependsOn) — https://fluxcd.io/flux/components/helm/helmreleases/
