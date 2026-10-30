# M09 — Resilience & Autoscaling — Answer Key

> Self-grading reference. Try each scenario first, then check your diagnostic path against the canonical one.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline: one tainted control-plane node, one worker. The baseline ships a healthy HPA (`sip-router`) and PDB (`route-engine`). Each break/fix layers one workload whose resilience control is broken in exactly one way.

## Lesson summary

M09 covers how Kubernetes keeps a service available across three kinds of change: **demand** (the HPA scales replicas), **version** (rolling updates replace Pods, and rollback rewinds), and **disruption** (a PDB paces voluntary disruption, and graceful shutdown drains each Pod). Each control is quiet when healthy and quiet when broken. Read its own status instead of waiting for the downstream symptom. The six scenarios break one control each:

- `breakfix-01-pdb-blocks-drain`: **allowed disruptions 0** because `minAvailable` equals the replica count
- `breakfix-02-hpa-no-requests`: **HPA `<unknown>/50%`** because the target has no CPU request
- `breakfix-03-rollout-stuck`: **`ProgressDeadlineExceeded`** because a bad image stalls the rollout
- `breakfix-04-pdb-unready-pods`: **allowed disruptions 0** on a sane budget because no replica is Ready
- `breakfix-05-sigterm-ignored`: **a Pod stuck `Terminating`** for the whole grace period
- `breakfix-06-hpa-quota-capped`: **an HPA that wants 4 and gets 2** because a ResourceQuota refuses the Pods

The through-line: **read the control, not the symptom.** `kubectl get pdb`, `kubectl get hpa`, and `kubectl rollout status` name the failure directly<sup><a href="https://kubernetes.io/docs/concepts/workloads/pods/disruptions/">[4]</a></sup>.

## Baseline tour reference

No broken state. Expected output per step:

- **Step 1 (Rolling updates and rollback):** `describe deployment route-engine` shows `StrategyType: RollingUpdate` and `RollingUpdateStrategy: 25% max unavailable, 25% max surge`<sup><a href="https://kubernetes.io/docs/concepts/workloads/controllers/deployment/">[3]</a></sup>. After `rollout restart`, `rollout status` reports success, one ReplicaSet holds the replica count, and older ones sit at 0. `rollout undo` rewinds to the previous revision.
- **Step 2 (The HPA):** `get hpa -n signaling` shows `sip-router` with a real percentage such as 3%/50%. `describe hpa` shows `ScalingActive True` and `resource cpu on pods (as a percentage of request)`<sup><a href="https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/">[1]</a></sup>.
- **Step 3 (Push the HPA past its target):** with a busybox loop on a port-80 Service, `TARGETS` rises above 50% and `REPLICAS` climbs from 2 toward 6. `describe hpa` shows `SuccessfulRescale` with `cpu resource utilization (percentage of request) above target`. After the load stops, replicas stay high for the 5-minute scale-down stabilization window.
- **Step 4 (PodDisruptionBudgets):** `route-engine` shows `MIN AVAILABLE 1` and `ALLOWED DISRUPTIONS 1`. `describe pdb` shows `Allowed disruptions: 1`, `Current: 2`, `Desired: 1`, `Total: 2`<sup><a href="https://kubernetes.io/docs/tasks/run-application/configure-pdb/">[5]</a></sup>. Two back-to-back evictions: the first returns Success, and the second returns `TooManyRequests` until the replacement is Ready<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/api-eviction/">[6]</a></sup>.
- **Step 5 (Graceful shutdown):** `terminationGracePeriodSeconds: 30`. Deleting one Pod returns in about a second and the Deployment replaces it. Deleting both with one selector sends both Pods to `Terminating` at once. The PDB does not stop it, because `kubectl delete` bypasses the eviction API<sup><a href="https://kubernetes.io/docs/concepts/workloads/pods/disruptions/">[4]</a></sup>.

---

## Break/fix 01 — PDB Blocks Drain

**Symptom:** A drain of the worker for a kernel patch hangs. The eviction returns `TooManyRequests: Cannot evict pod as it would violate the pod's disruption budget`. `sip-registrar` in `signaling` is healthy at 2/2 Running.

**Root cause:** The PDB has `minAvailable: 2`, equal to the replica count. Allowed disruptions is `currentHealthy − desiredHealthy = 2 − 2 = 0`, so the eviction API permits no voluntary eviction<sup><a href="https://kubernetes.io/docs/concepts/workloads/pods/disruptions/">[4]</a></sup>. A drain is a series of evictions, and it retries a refusal without end<sup><a href="https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/">[7]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
# 1. Read the budget, not the Pods
kubectl get pdb -n signaling                       # sip-registrar: ALLOWED DISRUPTIONS 0
kubectl describe pdb sip-registrar -n signaling    # Min available: 2; Allowed disruptions: 0; Current: 2; Desired: 2

# 2. See the refusal against the real eviction API (one Pod, nothing cordoned)
POD=$(kubectl get pod -n signaling -l app=sip-registrar -o jsonpath='{.items[0].metadata.name}')
cat <<EOF > /tmp/evict.json
{"apiVersion":"policy/v1","kind":"Eviction","metadata":{"name":"$POD","namespace":"signaling"}}
EOF
kubectl create --raw "/api/v1/namespaces/signaling/pods/$POD/eviction" -f /tmp/evict.json
#    Error ... TooManyRequests ... Cannot evict pod ... disruption budget
```

**Fix:** Give the budget headroom:

```bash
kubectl patch pdb sip-registrar -n signaling --type merge -p '{"spec":{"minAvailable":1}}'
# or maxUnavailable: 1, which holds up better when an HPA moves the replica count
```

**Verify:**

```bash
kubectl get pdb sip-registrar -n signaling         # ALLOWED DISRUPTIONS 1
# the eviction from step 2, repeated, now succeeds and the Deployment restores 2/2
```

<details>
<summary>📖 Going deeper: why the fixed budget still does not finish a drain here<sup><a href="https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/">[7]</a></sup></summary>

A drain cordons the node, then evicts each Pod. After the first eviction passes, the budget reads 0 until the replacement is Ready. On a cluster with spare nodes the replacement lands elsewhere within seconds, and the drain moves on. This cluster has one schedulable node. With the worker cordoned, the replacement stays `Pending`, `Current` stays at 1 against `Desired: 1`, and the second eviction is refused again. The budget is no longer the blocker, and capacity is. In production, size spare capacity for the largest drain you plan, or the budget and the drain will deadlock.

</details>

**What this scenario tests:** Recognizing that a blocked drain is a budget problem, and the allowed-disruptions arithmetic. Self-grading questions:

- Did you read the PDB's status instead of hunting for an unhealthy Pod (there is none)?
- Did you connect `minAvailable == replicas` to allowed disruptions 0?
- Did you lower the floor or switch to `maxUnavailable`, instead of deleting the PDB, which removes the protection?
- Can you say what the fix did not unblock?

**Expected time:** 3–6 minutes; 8–15 the first time (the lost time goes to inspecting healthy Pods before the budget).

**Production thinking:** A blocked drain is more often a bad budget than a bad node. `kubectl get pdb -A` with `ALLOWED DISRUPTIONS 0` is the fast check when maintenance stalls. Express budgets as `maxUnavailable` for HPA-driven workloads, never set the floor at the replica count, and alert on drains that exceed a timeout. Node autoscalers also remove nodes through the eviction API, so the same budget guards a service from scale-down<sup><a href="https://kubernetes.io/docs/concepts/cluster-administration/node-autoscaling/">[10]</a></sup>.

---

## Break/fix 02 — HPA Can't Read Its Metric

**Symptom:** `transcode-scaler` in `media` has an HPA, but `get hpa` shows `<unknown>/50%` and the count never leaves 1. metrics-server is healthy: `kubectl top pods -n media` returns live CPU.

**Root cause:** The HPA targets CPU *utilization*, which is usage divided by request<sup><a href="https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/">[1]</a></sup>. The container declares no CPU request, so utilization is undefined. The HPA sets `ScalingActive False` with reason `FailedGetResourceMetric` and the message `missing request for cpu in container app of Pod <name>`. The metrics pipeline is fine. The gap is on the target.

**Diagnostic commands (the canonical path):**

```bash
# 1. Unknown means no number, not 0% load
kubectl get hpa -n media                           # <unknown>/50%, REPLICAS 1
kubectl top pods -n media                          # metrics-server works

# 2. The HPA states the reason in Conditions
kubectl describe hpa transcode-scaler -n media     # ScalingActive False, FailedGetResourceMetric

# 3. Confirm the target, and contrast with the working one
kubectl describe deployment transcode-scaler -n media   # Limits: memory 128Mi; no Requests block
kubectl describe deployment sip-router -n signaling     # Requests: cpu 25m
```

**Fix:**

```bash
kubectl set resources deployment/transcode-scaler -n media --requests=cpu=100m
```

**Verify:**

```bash
# allow 30 seconds for a metrics sample from the new Pod
kubectl get hpa transcode-scaler -n media          # a real percentage, such as 1%/50%
kubectl describe hpa transcode-scaler -n media     # ScalingActive True
```

**What this scenario tests:** Reading an HPA's condition to find why it is dead, and the request-is-the-denominator rule. Self-grading questions:

- Did you treat `<unknown>` as "cannot read the metric" and go to `describe hpa`, instead of assuming a metrics outage?
- Did you connect the condition message to the missing request?
- Did you fix the request, and can you say why the memory limit was irrelevant?
- Can you name the second cause of `<unknown>`, with requests set?

**Expected time:** 3–6 minutes; 8–15 the first time (the lost time goes to debugging a healthy pipeline).

**Production thinking:** Enforce requests on autoscaled workloads with a `LimitRange` or admission policy (M20), so a Deployment cannot ship without one. Size the request honestly: the target percentage is relative to it, so a request that is too small over-scales and one that is too large under-scales. If you cannot size it by hand, VPA recommends requests from observed usage<sup><a href="https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler">[11]</a></sup>, but do not run VPA and an HPA on the same resource. A CPU HPA cannot see a queue backlog. That is KEDA's job<sup><a href="https://keda.sh/docs/latest/concepts/">[12]</a></sup>. Remove `spec.replicas` from the manifest once an HPA owns the count, or the next apply resets it.

---

## Break/fix 03 — Stuck Rollout

**Symptom:** A `portal-web` release in `admin-portal` has rolled out for minutes and `rollout status` never returns. Users are unaffected. `get deployment` shows `READY 2/2`, `AVAILABLE 2`, `UP-TO-DATE 1`.

**Root cause:** Revision 2 sets the image to `nginx:1.25-doesnotexist`, a tag that is not in the registry. The new ReplicaSet's Pod sits in `ImagePullBackOff`. With 2 replicas, `maxUnavailable` rounds down to 0, so the Deployment cannot retire an old Pod until the new one is Ready<sup><a href="https://kubernetes.io/docs/concepts/workloads/controllers/deployment/">[3]</a></sup>. After `progressDeadlineSeconds` (60 here) the Deployment reports `Progressing=False` with `ProgressDeadlineExceeded`. Kubernetes takes no action beyond that report.

**Diagnostic commands (the canonical path):**

```bash
# 1. Partial rollout, old version serving
kubectl get deployment portal-web -n admin-portal            # READY 2/2, UP-TO-DATE 1
kubectl rollout status deployment/portal-web -n admin-portal --timeout=10s
#    Waiting ... 1 out of 2 new replicas have been updated

# 2. The broken new ReplicaSet
kubectl get rs -n admin-portal -l app=portal-web
kubectl get pods -n admin-portal -l app=portal-web           # one ImagePullBackOff

# 3. The cause, on the Deployment
kubectl describe deployment portal-web -n admin-portal       # Image: nginx:1.25-doesnotexist; Progressing False, ProgressDeadlineExceeded
kubectl rollout history deployment/portal-web -n admin-portal
```

**Fix:** Roll back to the last good revision:

```bash
kubectl rollout undo deployment/portal-web -n admin-portal
kubectl rollout status deployment/portal-web -n admin-portal   # successfully rolled out
# roll-forward alternative: kubectl set image deployment/portal-web app=nginx:1.25 -n admin-portal
```

**Verify:**

```bash
kubectl get deployment portal-web -n admin-portal            # READY 2/2, UP-TO-DATE 2, AVAILABLE 2
kubectl describe deployment portal-web -n admin-portal       # Image: nginx:1.25
```

**What this scenario tests:** Diagnosing a stalled rollout on the Deployment's own state, and knowing rollback is the fast recovery. Self-grading questions:

- Did "service fine, rollout stuck" send you to the new ReplicaSet's Pods, not the running old ones?
- Did you read `ProgressDeadlineExceeded` and the bad image, instead of deleting Pods that the ReplicaSet recreates on the same image?
- Did you note that Kubernetes never rolled back on its own?
- Can you say what would differ with 10 replicas and the default `maxUnavailable`?

**Expected time:** 4–8 minutes; 10–20 the first time (the lost time goes to deleting the stuck Pod).

**Production thinking:** The stall is the feature that saved you, and it also hides a half-rolled deploy. Alert on `Progressing=False` and `ProgressDeadlineExceeded`, because the old version masks error rate. With a larger fleet the controller retires up to `maxUnavailable` old Pods first, so capacity dips before the stall. Prevent it upstream: a readiness probe so a bad Pod never counts as Ready, a canary, and a pipeline that checks the image exists (M02) and rolls back on a missed deadline. Roll forward when the fix is trivial and you want to keep the revision's other changes.

---

## Break/fix 04 — PDB With No Ready Pods

**Symptom:** A drain stalls on `trunk-monitor` in `signaling`. The PDB asks for 1 of 2 replicas, but `ALLOWED DISRUPTIONS` reads 0 and the eviction is refused. Both Pods are `Running` and read 0/1.

**Root cause:** The readiness probe requests `/healthz`, which nginx answers with 404, so no Pod is Ready. `currentHealthy` is 0, so allowed disruptions is `max(0, 0 − 1) = 0`. The budget is sane. The workload is unhealthy<sup><a href="https://kubernetes.io/docs/tasks/run-application/configure-pdb/">[5]</a></sup>. The default `unhealthyPodEvictionPolicy` (`IfHealthyBudget`) evicts an unready Pod only while `currentHealthy ≥ desiredHealthy`, so the broken Pods block their own removal.

**Diagnostic commands (the canonical path):**

```bash
# 1. The budget's inputs, not only its result
kubectl get pdb -n signaling
kubectl describe pdb trunk-monitor -n signaling    # Min available: 1; Allowed disruptions: 0; Current: 0; Desired: 1; Total: 2

# 2. Why nothing is healthy
kubectl get pods -n signaling -l app=trunk-monitor # Running, READY 0/1
POD=$(kubectl get pods -n signaling -l app=trunk-monitor -o name | head -1)
kubectl describe $POD -n signaling                 # Readiness probe failed: HTTP probe failed with statuscode: 404

# 3. The refusal, on an unready Pod
#    (evict as in breakfix-01) -> TooManyRequests
```

**Fix:** Repair the probe, not the budget:

```bash
kubectl patch deployment trunk-monitor -n signaling --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/"}]'
kubectl rollout status deployment/trunk-monitor -n signaling
```

**Verify:**

```bash
kubectl get pods -n signaling -l app=trunk-monitor  # 1/1 Ready
kubectl get pdb trunk-monitor -n signaling          # ALLOWED DISRUPTIONS 1
```

<details>
<summary>📖 Going deeper: unhealthyPodEvictionPolicy as a safety net<sup><a href="https://kubernetes.io/docs/tasks/run-application/configure-pdb/">[5]</a></sup></summary>

`unhealthyPodEvictionPolicy: AlwaysAllow` lets the eviction API remove unready Pods regardless of the budget. The field is beta and on by default since v1.27, so this cluster has it. It fits workloads that may crash-loop: it keeps a broken app from blocking a drain of its own broken Pods. It does not change `ALLOWED DISRUPTIONS` for Ready Pods, and it does not repair the workload. Reach for it after the fix, as a net. Pods in `Pending`, `Succeeded`, or `Failed` phase are always eligible for eviction either way.

</details>

**What this scenario tests:** Reading both inputs of the allowed-disruptions formula, and refusing to loosen a sane budget. Self-grading questions:

- Did you read `Current:` before you edited `minAvailable`?
- Did you notice that `Running` is not `Ready`, and read the probe events on one named Pod?
- Did you repair the probe, instead of lowering the floor to 0?
- Can you say why the eviction of an unready Pod was still refused?

**Expected time:** 4–8 minutes; 10–15 the first time.

**Production thinking:** `ALLOWED DISRUPTIONS 0` has two sources, the floor you set and the health you have, so triage the second before the first. Alert on a workload with `Current` below `Desired`, because it blocks maintenance silently. Set `unhealthyPodEvictionPolicy: AlwaysAllow` on workloads where a stuck drain costs more than evicting a broken Pod. Lowering the floor to unblock one drain leaves the protection gone for the next.

---

## Break/fix 05 — SIGTERM Ignored

**Symptom:** Drains of `announce-player` in `media` take 45 seconds per Pod, and old Pods linger in `Terminating` after every deploy. Nothing errors and no alert fires. A deleted Pod reads `Terminating` for the whole wait.

**Root cause:** The container runs `trap '' TERM; while true; do sleep 1; done`, which ignores `SIGTERM`. The kubelet sends `SIGTERM` and nothing happens. The runtime sends `SIGKILL` only when `terminationGracePeriodSeconds` (45) expires<sup><a href="https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/">[8]</a></sup>. Real apps do the same with no signal handler, or behind a shell wrapper that does not forward the signal.

**Diagnostic commands (the canonical path):**

```bash
# 1. Time a termination
POD=$(kubectl get pods -n media -l app=announce-player -o name | head -1)
kubectl delete $POD -n media --wait=false
kubectl get pods -n media -l app=announce-player -w --request-timeout=60s   # Terminating for ~45s

# 2. Read the countdown and the budget on a terminating Pod
kubectl describe pod <pod> -n media     # Status: Terminating (lasts ...); Termination Grace Period: 45s; Events: Killing

# 3. Read what the container does with the signal
kubectl describe deployment announce-player -n media   # Command: sh -c "trap '' TERM; ..."
```

**Fix:** Install a handler:

```bash
kubectl patch deployment announce-player -n media --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/containers/0/command","value":["sh","-c","trap exit TERM; while true; do sleep 1; done"]}]'
kubectl rollout status deployment/announce-player -n media --timeout=120s
```

The rollout finishes before the old Pods are gone, because they still ignore `SIGTERM` and linger in `Terminating` for 45 seconds each.

**Verify:**

```bash
kubectl get pods -n media -l app=announce-player    # no Pod reads Terminating
POD=$(kubectl get pods -n media -l app=announce-player --no-headers | grep Running | head -1 | cut -d' ' -f1)
time kubectl delete pod $POD -n media                # a few seconds
```

**What this scenario tests:** Reading a slow change as a duration, and the `SIGTERM` handler as the fix. Self-grading questions:

- Did you time a termination and compare it with the grace period?
- Did you find the signal handling in the container command, instead of blaming the node or the registry?
- Did you resist shortening `terminationGracePeriodSeconds` as the fix?
- Can you say why `SIGKILL` at the end still costs in-flight work?

**Expected time:** 4–8 minutes; 10–15 the first time (the grace period itself is a wait).

**Production thinking:** Test shutdown in CI: send `SIGTERM` to the container and assert it exits within a bound. The grace period is one budget that starts at deletion and covers `preStop` and the drain<sup><a href="https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/">[9]</a></sup>. Size it for the longest request plus the `preStop` sleep. Add a short `preStop` sleep so late traffic still finds a live process, because endpoint removal races the shutdown. Watch for entrypoints that run the app as a child of a shell, since the shell holds PID 1 and never forwards the signal. A shorter grace period only caps the cost.

---

## Break/fix 06 — HPA Capped by Quota

**Symptom:** `caption-engine` in `captions` has an HPA with `MINPODS 4`, but `REPLICAS` reads 2 and `get deploy` reads `READY 2/4`. The HPA shows a real percentage and `ScalingActive True`. No Pod is `Pending`.

**Root cause:** A ResourceQuota `pod-cap` caps the namespace at 2 Pods<sup><a href="https://kubernetes.io/docs/concepts/policy/resource-quotas/">[2]</a></sup>. The ReplicaSet creates 2 Pods, and admission refuses the rest: `FailedCreate ... exceeded quota: pod-cap, requested: pods=1, used: pods=2, limited: pods=2`. The HPA writes the desired count and has no view of whether the Pods arrive<sup><a href="https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/">[1]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
# 1. The HPA is healthy and wants more
kubectl get hpa -n captions
kubectl describe hpa caption-engine -n captions    # Deployment pods: 2 current / 4 desired; ScalingActive True

# 2. The Deployment is short, and no Pod is Pending
kubectl get deployment caption-engine -n captions  # READY 2/4
kubectl get pods -n captions

# 3. The refusal, then the cap
kubectl get events -n captions --sort-by=.lastTimestamp   # FailedCreate ... exceeded quota
kubectl describe resourcequota pod-cap -n captions        # pods: Used 2, Hard 2
```

**Fix:** Raise the cap above the HPA maximum, with room for surge, then nudge the ReplicaSet:

```bash
kubectl patch resourcequota pod-cap -n captions --type merge -p '{"spec":{"hard":{"pods":"10"}}}'
kubectl rollout restart deployment/caption-engine -n captions
kubectl rollout status deployment/caption-engine -n captions
```

The ReplicaSet controller retries a failed create with a growing delay, and a quota change does not wake it. The restart creates a fresh ReplicaSet.

**Verify:**

```bash
kubectl get deployment caption-engine -n captions   # READY 4/4
kubectl get hpa -n captions                         # REPLICAS 4
```

**What this scenario tests:** Walking the chain from a desired count to a running Pod. Self-grading questions:

- Did you notice that a healthy HPA with a short Deployment points below the HPA?
- Did you see that no Pod was `Pending`, so the scheduler was not the refuser?
- Did you read the ReplicaSet's `FailedCreate` events and the quota?
- Can you name the symptom that points at a full node instead of a quota?

**Expected time:** 4–8 minutes; 10–15 the first time.

**Production thinking:** A quota below the HPA maximum turns the autoscaler's ceiling into a lie, so size quotas from `maxReplicas` plus surge. Alert on Deployments whose ready count stays below the HPA desired count. A `Pending` Pod with `FailedScheduling` is the node-capacity sibling of this fault, and node autoscalers (Cluster Autoscaler, Karpenter) answer it<sup><a href="https://kubernetes.io/docs/concepts/cluster-administration/node-autoscaling/">[10]</a></sup>. A quota refusal needs a human or a policy decision, because no autoscaler adds quota.

## References

1. Kubernetes — Horizontal Pod Autoscaling: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
2. Kubernetes — Resource Quotas: https://kubernetes.io/docs/concepts/policy/resource-quotas/
3. Kubernetes — Deployments (rolling update, rollback, progress deadline): https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
4. Kubernetes — Disruptions (voluntary, involuntary, PDB scope): https://kubernetes.io/docs/concepts/workloads/pods/disruptions/
5. Kubernetes — Specifying a Disruption Budget for your Application: https://kubernetes.io/docs/tasks/run-application/configure-pdb/
6. Kubernetes — API-initiated Eviction: https://kubernetes.io/docs/concepts/scheduling-eviction/api-eviction/
7. Kubernetes — Safely Drain a Node: https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/
8. Kubernetes — Pod Lifecycle (Termination of Pods): https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
9. Kubernetes — Container Lifecycle Hooks (preStop): https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/
10. Kubernetes — Node Autoscaling (Cluster Autoscaler, Karpenter): https://kubernetes.io/docs/concepts/cluster-administration/node-autoscaling/
11. Kubernetes Autoscaler — Vertical Pod Autoscaler: https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler
12. KEDA — Concepts: https://keda.sh/docs/latest/concepts/
