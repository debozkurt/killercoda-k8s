# M17 — Helm Fundamentals — Answer Key

> Self-grading reference. Try each scenario first, then compare your diagnostic path with the canonical one. Instructors can use these sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` (Kubernetes about v1.30) with the Polyphone fleet, Helm v4.3.1, and the `voicemail` chart at `/root/voicemail`. Helm 4.3 documents support for Kubernetes 1.34 to 1.37. Every command in these labs was checked on Kubernetes v1.30.10.

## Lesson summary

M17 teaches Helm as three steps around an apply: **render** the chart with values, **record** a revision, **apply** the manifests. Then Pods start or fail at **runtime**. Each failure lands in one stage, and the stage decides the first command:

| Stage | Trace | First command | Scenario |
|-------|-------|---------------|----------|
| Render, wrong | No error, wrong value | `helm get values -a`, then `helm get manifest` | `breakfix-01-values-key-ignored` |
| Runtime | `deployed`, Pods fail | `kubectl get deploy -o wide`, then `helm history` | `breakfix-02-bad-upgrade-rollback` |
| Render, error | `execution error at (...)`, nothing in the cluster | `helm template` | `breakfix-03-render-required-value` |
| Apply | `cannot be imported into the current release` | `kubectl describe` the named object | `breakfix-04-ownership-conflict` |
| Record | `another operation ... is in progress` | `helm history` | `breakfix-05-release-stuck-pending` |

Five labs is above the usual count. The set is one differential: one lab for each stage, and two for render, because a render can fail loudly or succeed with the wrong value. The baseline's last step adds the Helm 4 apply conflict that a hand edit causes.

## Baseline tour reference

- **Step 1 (chart and release):** `helm version --short` prints `v4.3.1`. `helm list -n app-services` shows `voicemail`, revision 1, `deployed`. `describe deployment` shows the label `app.kubernetes.io/managed-by=Helm` and the annotations `meta.helm.sh/release-name` and `meta.helm.sh/release-namespace`.
- **Step 2 (render and compare):** `helm template` with the install's values prints the same manifest as `helm get manifest`. The stored manifest answers "what should run?", because the chart on disk can change after an install.
- **Step 3 (values and an upgrade):** `helm get values` lists `replicaCount: 2` and `config.sipRealm`. `-a` adds every chart default. The upgrade with `--reuse-values --set replicaCount=3` records revision 2, and the Deployment reaches 3/3.
- **Step 4 (history and rollback):** `helm rollback voicemail 1` records revision 3, `Rollback to 1`, and the Deployment returns to 2/2. Three Secrets `sh.helm.release.v1.voicemail.v1` to `.v3` carry `status=` labels that mirror `helm history`.
- **Step 5 (hand edit):** after `kubectl scale --replicas=4`, the next `helm upgrade` fails with `conflict with "kubectl" with subresource "scale" using apps/v1: .spec.replicas`. Revision 4 is `failed`, and the Deployment still wants 4. `--force-conflicts` records revision 5 and returns it to 2.

---

## Break/fix 01 — Values key ignored

**Symptom:** the release is `deployed`, and `helm get values` shows a 3. The Deployment reads `READY 1/1`.

**Root cause:** `/root/voicemail-values.yaml` sets `replicas: 3`. The template reads `.Values.replicaCount`. Helm does not check override keys against the chart, so it stores the unused key and renders the default `replicaCount: 1`<sup><a href="https://helm.sh/docs/chart_template_guide/values_files/">[1]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
helm get values voicemail -n app-services                 # USER-SUPPLIED: replicas: 3
helm get manifest voicemail -n app-services | grep 'replicas:'   # replicas: 1
helm get values voicemail -n app-services -a              # replicaCount: 1 AND replicas: 3
helm show values /root/voicemail                          # the chart defines replicaCount
```

**Fix:** correct the file, then upgrade from it without `--reuse-values`, so the stray key leaves the release:

```bash
sed -i 's/^replicas:/replicaCount:/' /root/voicemail-values.yaml
helm upgrade voicemail /root/voicemail -n app-services -f /root/voicemail-values.yaml
```

**Verify:** `helm get values` shows `replicaCount: 3` and no `replicas`. The manifest renders `replicas: 3`, and the Deployment reaches 3/3.

**What this scenario tests:**

- Did you compare the input (`helm get values`) with the output (`helm get manifest`) before you suspected the cluster?
- Did you use `-a` to see the unused key next to the real one?
- Did you fix the file, or only the live release?

The anti-pattern is `helm upgrade --reuse-values --set replicaCount=3`. It gives 3 Pods, keeps `replicas: 3` in the release, and leaves the file wrong for the next install.

**Expected time:** 3–8 min once you compare values with the manifest; longer if you trust `helm get values` alone.

**Production thinking:** run `helm template` in CI and assert on the rendered fields that matter, such as replicas, image and resources. A chart you own can ship a `values.schema.json` with `additionalProperties: false`, which makes Helm reject an unknown key during install, upgrade, lint and template. For a chart you do not own, `helm lint --strict` and a render assertion catch most of this class.

---

## Break/fix 02 — Bad upgrade, rollback

**Symptom:** `helm status` reads `deployed`, revision 2. Two Pods run and one is in `ImagePullBackOff`. `kubectl get deploy -o wide` reads `READY 2/2`, `UP-TO-DATE 1`, `IMAGES nginx:1.25.99`.

**Root cause:** revision 2 set `image.tag: 1.25.99`, which does not exist. Helm 4 `upgrade` defaults to `--wait=hookOnly`, so it reported `deployed` once the apply succeeded<sup><a href="https://helm.sh/docs/intro/using_helm/">[2]</a></sup>. The rolling update keeps the old Pods because the new Pod never becomes ready.

**Diagnostic commands (the canonical path):**

```bash
helm status voicemail -n app-services | head -7             # deployed, revision 2
kubectl get deployment voicemail -n app-services -o wide    # UP-TO-DATE 1, IMAGES nginx:1.25.99
kubectl describe pod <stuck-pod> -n app-services            # Failed to pull image ... not found
helm history voicemail -n app-services                      # revision 1 is the target
helm get values voicemail -n app-services --revision 2      # adds image.tag: 1.25.99
```

**Fix:**

```bash
helm rollback voicemail 1 -n app-services
kubectl rollout status deployment/voicemail -n app-services --timeout=60s
```

**Verify:** `helm history` shows revision 3, `deployed`, `Rollback to 1`. `IMAGES` reads `nginx:1.25`, and `UP-TO-DATE` equals `READY`.

**What this scenario tests:**

- Did you read past `deployed` to the Deployment and the Pods?
- Did you find the change by comparing the values of two revisions, instead of guessing?
- Did you recover through Helm, so that the release record and the cluster agree?

The anti-pattern is `kubectl rollout undo`. It restores the Pods, leaves the release on revision 2, and gives `kubectl` ownership of the image field. The next `helm upgrade` then fails with `conflict with "kubectl" ... .spec.template.spec.containers[name="app"].image`, and with `--force-conflicts` it applies the bad tag again.

**Expected time:** 3–7 min. The slow part is trusting the green status.

**Production thinking:** the rollback is the incident action. The durable fix corrects the tag in the values file in git and rolls forward to a new good revision. Deploy jobs that must grade readiness run `helm upgrade --rollback-on-failure --timeout 5m`. That flag implies `--wait=watcher`, so a bad tag fails the job and Helm returns to the last successful revision<sup><a href="https://helm.sh/docs/helm/helm_upgrade/">[3]</a></sup>. `--atomic` is the deprecated Helm 3 name for the same flag.

---

## Break/fix 03 — Render required value

**Symptom:** the install exits 1. `helm list` shows no release in any status, and the namespace has no `voicemail` objects and no release Secret.

**Root cause:** the install omitted `config.sipRealm`. The template wraps it in `required`, which stops the render<sup><a href="https://helm.sh/docs/chart_template_guide/function_list/">[4]</a></sup>. Helm renders before it creates the release record, so nothing reached the cluster.

**Diagnostic commands (the canonical path):**

```bash
helm list -n app-services                                   # no voicemail row
kubectl get secret -n app-services -l owner=helm            # no release Secret
helm install voicemail /root/voicemail -n app-services --set replicaCount=2
# Error: INSTALLATION FAILED: execution error at (voicemail/templates/deployment.yaml:25:24):
#   voicemail: .Values.config.sipRealm is required (the SIP realm to register under)
helm template voicemail /root/voicemail --set replicaCount=2   # same error, offline
helm show values /root/voicemail                               # sipRealm: ""
```

**Fix:**

```bash
helm install voicemail /root/voicemail -n app-services \
  --set replicaCount=2 --set config.sipRealm=polyphone.example
```

**Verify:** `helm list` shows `deployed`. `describe deployment` shows `SIP_REALM: polyphone.example` under `Environment:`, and `READY` reads 2/2.

**What this scenario tests:**

- Did you recognize "no release, no objects, no events" as a render failure and stop looking in the cluster?
- Did you read the error for the template, the line and the value?
- Did you reproduce it with `helm template` instead of retrying the install?

The anti-pattern is to search events, nodes and RBAC for a failure that happened on the client.

**Expected time:** 2–5 min.

**Production thinking:** put every required input in the values file that the deploy job applies, and run `helm template` with that file as a CI gate, so a render error never reaches a deploy. As a chart author, use `required` for a value with no safe default, such as a realm that differs per environment. Use a `values.yaml` default when a safe one exists.

---

## Break/fix 04 — Ownership conflict

**Symptom:** the install exits 1 with `Service "voicemail" in namespace "app-services" exists and cannot be imported into the current release: invalid ownership metadata`. `helm template` succeeds. No release exists, and a `voicemail` Service does.

**Root cause:** someone created the Service with `kubectl apply` before the move to Helm. It carries no `app.kubernetes.io/managed-by: Helm` label and no `meta.helm.sh/release-*` annotations. Helm adopts an existing object only when that metadata names the release, so the install stopped before it applied anything.

**Diagnostic commands (the canonical path):**

```bash
kubectl get deploy,svc -n app-services -l app=voicemail      # a Service, no Deployment
helm install voicemail /root/voicemail -n app-services \
  --set replicaCount=2 --set config.sipRealm=polyphone.example   # names the object and the missing keys
helm template voicemail /root/voicemail \
  --set replicaCount=2 --set config.sipRealm=polyphone.example | head -20   # render is clean
kubectl describe service voicemail -n app-services | head -8 # Labels: app=voicemail, Annotations: <none>
```

**Fix (adopt in place):**

```bash
kubectl label service voicemail -n app-services app.kubernetes.io/managed-by=Helm
kubectl annotate service voicemail -n app-services \
  meta.helm.sh/release-name=voicemail meta.helm.sh/release-namespace=app-services
helm install voicemail /root/voicemail -n app-services \
  --set replicaCount=2 --set config.sipRealm=polyphone.example
```

`helm install --take-ownership` skips the check and adopts in one command<sup><a href="https://helm.sh/docs/helm/helm_install/">[5]</a></sup>. Use it only after you confirm that no other release owns the object. Delete-and-recreate also works, but it drops the Service for a moment and gives it a new ClusterIP.

**Verify:** the release is `deployed`, the Service has the same `CLUSTER-IP` as before, and `Endpoints:` lists two Pod addresses.

**What this scenario tests:**

- Did you rule out the render with `helm template` before you edited anything?
- Did you read the object's metadata and compare it with a Helm-owned object?
- Did you keep the Service in place, instead of deleting an object that callers use?

**Expected time:** 3–6 min.

**Production thinking:** a migration from raw manifests to a chart meets this error once for every object that already exists, one object per attempt. Script the adoption from a list of the chart's objects, or render the chart and annotate each object first. Before `--take-ownership`, check the `meta.helm.sh/release-name` annotation: if another release owns the object, two releases now fight over it.

---

## Break/fix 05 — Release stuck pending

**Symptom:** every `helm upgrade` fails at once with `another operation (install/upgrade/rollback) is in progress`. No Helm process runs. One `voicemail` Pod is `Pending` with `Insufficient memory`.

**Root cause:** a deploy job ran `helm upgrade --wait` with a 64Gi memory request. Helm recorded revision 2 as `pending-upgrade` before it applied. The new Pod could not schedule, so the wait continued until the runner was killed. Nothing changed revision 2's status after that, and an upgrade refuses while the latest revision is pending<sup><a href="https://helm.sh/docs/helm/helm_rollback/">[6]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
helm status voicemail -n app-services | head -7      # STATUS: pending-upgrade, Preparing upgrade
helm history voicemail -n app-services               # revision 2 pending-upgrade
pgrep -a helm || echo 'no helm process'    # nothing is running
kubectl get secret -n app-services -l owner=helm --show-labels   # status=pending-upgrade on v2
kubectl get pods -n app-services -l app=voicemail    # one Pending (64Gi request)
```

**Fix:**

```bash
helm rollback voicemail 1 -n app-services
helm upgrade voicemail /root/voicemail -n app-services --reuse-values \
  --set config.greeting="Please leave a message after the tone."
```

A rollback does not check for a pending revision. It writes revision 3 as `deployed`, which removes the `Pending` Pod and the lock. The greeting upgrade then runs as revision 4.

**Verify:** the latest revision is `deployed`. Two Pods run with a 32Mi memory request, and `GREETING` shows the new text.

**What this scenario tests:**

- Did you read the release record before you retried the upgrade?
- Did you confirm that no Helm process still runs before you broke the lock?
- Did you use `helm rollback`, instead of deleting revision Secrets?

The anti-pattern is `kubectl delete secret sh.helm.release.v1.voicemail.v2`. It works here, but it deletes history, and a wrong choice deletes the record of the revision that runs now.

**Expected time:** 4–8 min.

**Production thinking:** prefer `--rollback-on-failure` with a `--timeout` shorter than the CI job's own timeout, so Helm ends the operation before the runner dies. Alert on any release whose latest status starts with `pending-` for longer than the deploy timeout: `helm list -A --pending` lists them. Run only one deploy job per release at a time. The pending check is a guard against concurrent upgrades, not a lease that expires.

## References

1. Helm — Values Files (order of specificity): https://helm.sh/docs/chart_template_guide/values_files/
2. Helm — Using Helm (install, upgrade, revisions): https://helm.sh/docs/intro/using_helm/
3. Helm — `helm upgrade` (`--wait`, `--rollback-on-failure`): https://helm.sh/docs/helm/helm_upgrade/
4. Helm — Template Function List (`required`): https://helm.sh/docs/chart_template_guide/function_list/
5. Helm — `helm install` (`--take-ownership`): https://helm.sh/docs/helm/helm_install/
6. Helm — `helm rollback`: https://helm.sh/docs/helm/helm_rollback/
