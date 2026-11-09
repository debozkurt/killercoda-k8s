# M18 — Flux (GitOps Delivery) — Answer Key

> Self-grading reference. Try each scenario first, then compare your diagnostic path with the canonical one. Instructors can use these sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` (Kubernetes about v1.30) with the Polyphone fleet, Flux v2.9.6 (`flux install`: source, kustomize and helm controllers), Helm v4.3.1, an in-cluster Gitea server, and a clone of `polyphone-config` at `/root/polyphone-config`. The Flux 2.9 release notes list Kubernetes 1.34 to 1.36 as supported, and the `flux check` CLI accepts `>=1.33.0-0`, so the check fails its version line here. Every command in these labs was checked on Kubernetes v1.30.10. The Flux objects are applied by hand (no bootstrap), so a fix to a Flux object is a `kubectl patch`. In a bootstrapped fleet the same fix is a commit.

## Lesson summary

M18 teaches Flux delivery as a loop with four stages: **fetch** (source-controller), **build**, **apply** and **health** (kustomize-controller and helm-controller). Two controls sit across the stages: the **order gate** (`dependsOn`) and the **suspend** switch. A failure stops one stage and leaves the later stages on the last good result. So the diagnosis reads the Flux objects in pipeline order and compares revisions:

| Stage | Trace | First command | Scenario |
|-------|-------|---------------|----------|
| Fetch | Workloads absent; consumers say `Source artifact not found` | `flux get sources git` | `breakfix-01-source-ref-not-found` |
| Suspend | Drift stays; `READY True`, `SUSPENDED True` | `flux get kustomizations` | `breakfix-02-kustomization-suspended` |
| Order gate | `DependencyNotReady`: `unable to get ... dependency` | `flux get helmreleases` | `breakfix-03-helmrelease-dependency` |
| Build | Source has the commit; `apps` revision trails; `kustomization path not found` | `flux get kustomizations` | `breakfix-04-path-not-found` |
| Health | `health check failed`; a hand fix reverts | `kubectl describe kustomization`, then git | `breakfix-05-health-check-fix-in-git` |

Five labs is above the usual count. The set is one differential: one lab each for fetch, build and health, one for the order gate and one for the suspend switch. The apply stage, drift correction, is baseline step 3. bf05 is the only lab where the fix must be a commit.

## Baseline tour reference

- **Step 1 (Flux and its source):** `flux check` shows green controllers and CRDs and ends `check failed`, from two lines: `Kubernetes version v1.30.10 does not match >=1.33.0-0` and `new CLI version is available`. `flux get sources git` shows `polyphone-config` `READY True`, revision `main@sha1:<8 chars>`, which matches `git log --oneline`.
- **Step 2 (the Kustomization):** `apps` is `READY True`, `Applied revision` equal to the source revision. `describe` shows `Path: ./apps`, `Prune: true`, `Target Namespace: app-services`, `Wait: true`, `Timeout: 1m`. `flux tree kustomization apps` lists `ConfigMap/app-services/dialplan-routes` and `Deployment/app-services/dialplan`.
- **Step 3 (drift):** `kubectl scale dialplan --replicas=5`, then `flux reconcile kustomization apps`, returns it to 2; `flux events` shows `Deployment/app-services/dialplan configured`. The same scale on `voicemail` stays at 3 after `flux reconcile helmrelease voicemail`: HelmRelease drift detection is disabled by default.
- **Step 4 (HelmRelease):** both releases `READY True`. `helm list -n app-services` is empty; `helm list -n flux-system` shows `app-services-voicemail` and `app-services-message-store`, `deployed`. `flux events --for HelmRelease/voicemail` shows `DependencyNotReady` before `InstallSucceeded`.
- **Step 5 (git):** a commit to `replicas: 3` and a push, then `flux reconcile kustomization apps --with-source`, move the source and `apps` to the new hash and `dialplan` to 3. `git rm` of `dialplan-routes.yaml` plus a push deletes the ConfigMap, and the inventory lists only the Deployment.

---

## Break/fix 01 — Source ref not found

**Symptom:** `dialplan`, `message-store` and `voicemail` are absent from `app-services`. No Pod fails. Every Flux object is `READY False`.

**Root cause:** the `GitRepository` names `spec.ref.branch: release-2024`, and the repo has only `main`. source-controller fails with `couldn't find remote ref "refs/heads/release-2024"` and never stores an artifact<sup><a href="https://fluxcd.io/flux/components/source/gitrepositories/">[1]</a></sup>. With no artifact, each consumer waits: `apps` on the artifact, `message-store` on its HelmChart, `voicemail` on `message-store`.

**Diagnostic commands (the canonical path):**

```bash
# 1. The consumers: every message points up the pipeline
flux get kustomizations      # apps: Source artifact not found, retrying in 30s
flux get helmreleases        # message-store: HelmChart ... not ready: no artifact available ...
                             # voicemail: dependency 'flux-system/message-store' is not ready
# 2. The source: red, empty REVISION, the git error names the ref
flux get sources git
kubectl describe gitrepository polyphone-config -n flux-system   # Ref: Branch: release-2024, no Artifact
# 3. What the server has
git -C /root/polyphone-config ls-remote --heads origin           # refs/heads/main only
```

**Fix:**

```bash
kubectl patch gitrepository polyphone-config -n flux-system \
  --type=merge -p '{"spec":{"ref":{"branch":"main"}}}'
flux reconcile source git polyphone-config
```

**Verify:** `flux get all` shows every object `READY True`. `apps` applied the same revision the source stored. The three Deployments are ready within about a minute, `voicemail` last.

**What this scenario tests:**

- Did you read the source before you looked for a broken Pod?
- Did you see that all three consumer messages describe waiting, not failing?
- Did you confirm the branch list on the server, instead of guessing a branch name?

**Expected time:** 3–6 min.

**Production thinking:** this case is the loud one: the workloads never existed. The quiet case is a fetch failure after a good fetch, where every consumer stays green on the old artifact. Alert on source `Ready False` and on the age of the source's last artifact update, not on consumer status alone. In a bootstrapped fleet, the `GitRepository` manifest lives in git, so the fix is a reviewed commit, and a CI check can run `git ls-remote` for every ref the manifests name.

---

## Break/fix 02 — Kustomization suspended

**Symptom:** `dialplan` runs 5 replicas against `replicas: 2` in git. The source is current. `apps` reads `READY True` and `Applied revision` equal to the source.

**Root cause:** `apps` has `spec.suspend: true`, left from an incident. kustomize-controller skips every pass of a suspended object: no drift correction, no new revision, no prune<sup><a href="https://fluxcd.io/flux/components/kustomize/kustomizations/">[2]</a></sup>. The object keeps the conditions of its last pass, which succeeded, so only the `SUSPENDED` column shows the state.

**Diagnostic commands (the canonical path):**

```bash
kubectl get deploy dialplan -n app-services                 # 5/5
grep replicas /root/polyphone-config/apps/dialplan.yaml      # replicas: 2
flux get sources git                                         # READY True, newest commit
flux get kustomizations                                      # apps  SUSPENDED True  READY True
kubectl describe kustomization apps -n flux-system           # Suspend: true
flux reconcile kustomization apps                            # ✗ resource is suspended
```

**Fix:**

```bash
flux resume kustomization apps
```

**Verify:** `apps` reads `SUSPENDED False`, `READY True`. `dialplan` is back at 2. A second `kubectl scale` reverts on the next `flux reconcile`.

**What this scenario tests:**

- Did you read the `SUSPENDED` column, or stop at `READY True`?
- Did you rule out the source first by comparing its revision with `git log`?
- Did you resume, rather than scale `dialplan` back by hand? A hand scale hides the drift and leaves delivery off.

**Expected time:** 2–5 min. The slow part is trusting the green `READY`.

**Production thinking:** suspend is the right tool before a deliberate hand change, and the runbook needs a matching exit: put the change in git, then resume. If 5 replicas was correct, the commit sets `replicas: 5` before the resume, or the resume reverts it. Alert on any Flux object with `spec.suspend: true` for longer than an incident window. Flux's monitoring example configures kube-state-metrics to export `gotk_resource_info` with a `suspended` label for every Flux object.

---

## Break/fix 03 — HelmRelease dependency

**Symptom:** `voicemail` never installs. The source, `apps` and `message-store` are `READY True`, and the chart renders with `helm template`.

**Root cause:** `voicemail` lists `dependsOn: [{name: message-cache}]`. The store's HelmRelease is `message-store`; the reference kept the old name after a rename. helm-controller checks every dependency at the start of each pass and stops before the chart. It sets `DependencyNotReady` with the message `unable to get 'flux-system/message-cache' dependency: helmreleases.helm.toolkit.fluxcd.io "message-cache" not found`, and retries every 30 seconds<sup><a href="https://fluxcd.io/flux/components/helm/helmreleases/">[3]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
flux get helmreleases                                   # voicemail: unable to get 'flux-system/message-cache' dependency ...
kubectl describe helmrelease voicemail -n flux-system   # Depends On: Name: message-cache; Reason: DependencyNotReady
kubectl get helmreleases -n flux-system                 # message-store, voicemail. No message-cache.
helm template /root/polyphone-config/charts/voicemail   # renders: the chart is fine
```

**Fix:**

```bash
kubectl patch helmrelease voicemail -n flux-system \
  --type=merge -p '{"spec":{"dependsOn":[{"name":"message-store"}]}}'
flux reconcile helmrelease voicemail
```

**Verify:** `voicemail` reads `Helm install succeeded for release app-services/app-services-voicemail.v1`. `helm list -n flux-system` shows it `deployed`, and the Deployment runs 2/2.

**What this scenario tests:**

- Did you read the message, not only the reason? `is not ready` means a red dependency; `unable to get ... not found` means a wrong reference.
- Did you list HelmReleases, the kind that `dependsOn` names, rather than Kustomizations or Deployments?
- Did you keep the gate? Deleting `dependsOn` installs `voicemail`, and it also removes the order the release needs.

**Expected time:** 3–6 min.

**Production thinking:** the durable fix is a commit to the HelmRelease manifest. Catch the class in CI: for every `dependsOn` entry in the repo, assert that an object of the same kind with that name exists in the same render. Keep `dependsOn` to real ordering needs. The gate runs on every pass, so a red dependency later blocks upgrades and drift correction of its dependents, even though their workloads keep running.

---

## Break/fix 04 — Path not found

**Symptom:** the newest commit asks for 3 `dialplan` replicas, and the cluster runs 2, all ready. `flux get sources git` shows the newest commit. `apps` shows `READY False`, and its `REVISION` is the seed commit.

**Root cause:** the commit moved `apps/` to `deploy/apps/`, and `apps` still has `spec.path: ./apps`. The build fails with `kustomization path not found: stat /tmp/kustomization-<n>/apps: no such file or directory` (reason `ArtifactFailed`)<sup><a href="https://fluxcd.io/flux/components/kustomize/kustomizations/">[2]</a></sup>. A failed build applies nothing and prunes nothing, so the objects from the last good build keep running, and `lastAppliedRevision` stays on the seed commit.

**Diagnostic commands (the canonical path):**

```bash
kubectl get deploy dialplan -n app-services      # 2/2, healthy
git -C /root/polyphone-config log --oneline      # restructure commit on top
flux get sources git                             # revision = restructure commit
flux get kustomizations                          # apps revision = seed commit; path not found
kubectl describe kustomization apps -n flux-system   # Path: ./apps
ls /root/polyphone-config/deploy                 # apps
```

**Fix (point the build at the new path):**

```bash
kubectl patch kustomization apps -n flux-system \
  --type=merge -p '{"spec":{"path":"./deploy/apps"}}'
flux reconcile kustomization apps
```

Moving the directory back in git, with a commit and a push, is also correct.

**Verify:** `apps` reads `READY True`, and its revision equals the source revision. `dialplan` runs 3/3. `flux tree kustomization apps` lists the same two objects, so prune deleted nothing.

**What this scenario tests:**

- Did you compare the consumer revision with the source revision, rather than look at colors?
- Did you name the stage from the message, build, before you touched the workload?
- Did you avoid `kubectl scale --replicas=3`? It matches the commit for one pass and leaves the build broken.

**Expected time:** 3–6 min.

**Production thinking:** in a bootstrapped fleet the `Kustomization` is a manifest in git too. Move the directory and the `spec.path` in the same pull request, and run `flux build kustomization` (or `kustomize build` on every `path`) in CI, so a missing path fails the pull request instead of the cluster. Alert when a consumer's `lastAppliedRevision` trails its source for longer than a few intervals; that catches this case and the quiet fetch case.

---

## Break/fix 05 — Health check, fix in git

**Symptom:** `apps` alternates between `READY False`, `health check failed after 1m0s: timeout waiting for: [Deployment/app-services/dialplan status: 'InProgress']`, and `READY Unknown`, `Reconciliation in progress`. After the Deployment's 600-second progress deadline, the status in that message reads `'Failed'` instead of `'InProgress'`. Two old `dialplan` Pods serve; one new Pod is in `ImagePullBackOff`. A `kubectl set image` back to `nginx:1.25` lasts about one minute.

**Root cause:** the release commit set `image: nginx:1.25-polyphone`, a tag the registry does not have. kustomize-controller applied it, and `wait: true` timed out on the rollout<sup><a href="https://fluxcd.io/flux/components/kustomize/kustomizations/">[2]</a></sup>. `lastAttemptedRevision` is the release commit; `lastAppliedRevision` stays on the seed commit, because it moves only when a whole pass succeeds. Each retry applies the manifest from git again with forced server-side apply, so it takes the image field back from any hand change<sup><a href="https://kubernetes.io/docs/reference/using-api/server-side-apply/">[4]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
flux get kustomizations                              # health check failed / Reconciliation in progress
kubectl describe kustomization apps -n flux-system   # Last Attempted = release commit, Last Applied = seed
kubectl get pods -n app-services -l app=dialplan     # 2 Running, 1 ImagePullBackOff
kubectl describe deployment dialplan -n app-services # Image: nginx:1.25-polyphone
git -C /root/polyphone-config log --oneline          # "dialplan: roll to build 1.25-polyphone"
```

**Fix:**

```bash
cd /root/polyphone-config
git revert --no-edit HEAD
git push
flux reconcile kustomization apps --with-source
```

A fix forward, a commit that sets a tag the registry has, is also correct.

**Verify:** `git log --oneline -1`, `flux get sources git` and `flux get kustomizations` show the same hash, and `apps` reads `READY True`. Two `dialplan` Pods run `nginx:1.25`, and no Pod is in `ImagePullBackOff`.

**What this scenario tests:**

- Did you read `Last Attempted Revision` and `Last Applied Revision`, and see that the release commit was applied and then refused?
- Did the hand fix teach you something? It shows which controller owns the field and why it cannot last.
- Did you fix the desired state in git, and confirm the fix with revisions rather than Pod status alone?

**Expected time:** 5–10 min, including one wasted minute on the hand fix.

**Production thinking:** when a bad commit is in git, the fastest durable recovery is a revert commit, and the revert must go through the same review shortcut that incidents use. When the fix cannot wait for a commit, `flux suspend kustomization apps` first, then fix by hand, then revert in git, then resume, in that order. Keep tags that the registry lacks out of git: a CI step that resolves every image reference before merge, or an admission policy that rejects unresolvable tags (M20).

## References

1. Flux — GitRepositories: https://fluxcd.io/flux/components/source/gitrepositories/
2. Flux — Kustomizations (path, wait, suspend, inventory): https://fluxcd.io/flux/components/kustomize/kustomizations/
3. Flux — HelmReleases (dependsOn, release name, storage namespace): https://fluxcd.io/flux/components/helm/helmreleases/
4. Kubernetes — Server-Side Apply: https://kubernetes.io/docs/reference/using-api/server-side-apply/
