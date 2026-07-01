# M06 — Scheduling — Answer Key

> Self-grading reference. Try each scenario first, then come back here to check your diagnostic path against the canonical one. Instructors running the lab live can use the same sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline — one tainted control-plane node, one worker. Each break/fix layers one small extra workload that fails to schedule (or stay up) for exactly one reason.

## Lesson summary

M06 is about the kube-scheduler: it **filters** the nodes a Pod can run on, **scores** the survivors, and **binds** the Pod to the best one. A Pod that survives no filter stays `Pending`, and its single `FailedScheduling` event lists — per node — the first filter each one failed. The `baseline/` tour reads healthy placement (the control-plane taint, the requests/limits/QoS contract, the fleet's nodeAffinity and tolerations, the `Scheduled` event and Allocatable headroom). The four break/fix scenarios split "won't run" into one signature each:

- `breakfix-01-insufficient-resources` — **`Pending`, `Insufficient memory`**: a request larger than any node's Allocatable
- `breakfix-02-untolerated-taint` — **`Pending`, `untolerated taint`**: a node repelling a Pod that lacks the toleration
- `breakfix-03-antiaffinity-unschedulable` — **replicas `Pending`, `didn't match pod anti-affinity rules`**: a hard spread rule with too few schedulable nodes
- `breakfix-04-oom-killed` — **`CrashLoopBackOff`, `OOMKilled` (exit 137)**: a memory limit below the container's working set

The through-line: **requests are what you fit; limits are what kill you.** The first three are placement failures the scheduler names in one event; the fourth is a runtime failure the kernel names in the container's last state. Read the event for a `Pending` Pod, the last state for a crashing one — and on this 2-node cluster, skip past the expected `{node-role.kubernetes.io/control-plane}` line in every scheduling message and read the *worker's* reason<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/">[9]</a></sup>.

## Baseline tour reference

No broken state. Expected output per step:

- **Step 1 (Where the fleet landed):** `kubectl get pods -A -o wide` shows the whole fleet on the worker; only `sbc-edge` (a DaemonSet) and system Pods touch the control-plane. `kubectl describe node -l node-role.kubernetes.io/control-plane | grep Taints` shows `node-role.kubernetes.io/control-plane:NoSchedule` — the taint that keeps ordinary workloads off. The worker's Taints are `<none>`.
- **Step 2 (Requests, limits, QoS):** the fleet's containers set requests *and* limits with requests below limits, so `.status.qosClass` is `Burstable` across the board<sup><a href="https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/">[2]</a></sup>. `kubectl describe node` on the worker shows an "Allocated resources" table (sum of *requests*, the scheduler's ledger); `kubectl top nodes` shows live usage far below it — reservation ≠ usage.
- **Step 3 (Steering: affinity and taints):** `kubectl get nodes --show-labels` shows the worker carries `disktype=ssd`; `media-engine`/`transcoder` require it via `requiredDuringScheduling` nodeAffinity<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/">[5]</a></sup>. `sbc-edge` runs `2/2` because it tolerates the control-plane taint<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/">[4]</a></sup>.
- **Step 4 (Scheduler decision & headroom):** `kubectl describe pod` on a fleet Pod shows a `Scheduled … Successfully assigned … to <worker>` event; `kubectl describe node` shows the worker's requested-vs-Allocatable headroom, which predicts what fits next. The node's Allocatable memory is a couple of GiB — the setup for breakfix-01.

---

## Break/fix 01 — Insufficient Resources

**Symptom:** `stream-analyzer` in `analytics` has zero available replicas; its Pod is `Pending` with no assigned node and never starts. No logs (the container never ran), nothing to restart.

**Root cause:** The container's memory **request** was fat-fingered from `256Mi` to `256Gi` (a Mi→Gi unit slip). The scheduler places a Pod by summing its **requests** and checking them against each node's **Allocatable**; no node has 256Gi, so every node fails the resource-fit filter and the Pod stays `Pending` with `Insufficient memory`<sup><a href="https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/">[1]</a></sup>. Limits are irrelevant to this — only requests are fit.

**Diagnostic commands (the canonical path):**

```bash
# 1. Pending, no NODE
kubectl get pods -n analytics -o wide

# 2. The whole diagnosis is one event
kubectl describe pod -n analytics -l app=stream-analyzer | grep -A6 Events
#    FailedScheduling ... 1 node(s) had untolerated taint {control-plane}, 1 Insufficient memory
#    (skip the control-plane line; the worker's reason is "Insufficient memory")

# 3. What is it asking for, vs. what a node has?
kubectl get pod -n analytics -l app=stream-analyzer \
  -o jsonpath='{.items[0].spec.containers[0].resources.requests}'; echo   # memory:256Gi
kubectl get nodes -o custom-columns='NODE:.metadata.name,MEM:.status.allocatable.memory'
```

**Fix:** Right-size the memory request (and its matching limit):

```bash
kubectl set resources deployment/stream-analyzer -n analytics \
  --requests=memory=256Mi --limits=memory=512Mi
# or: kubectl edit deployment stream-analyzer -n analytics  → requests.memory 256Gi → 256Mi
```

**Verify:**

```bash
kubectl get deploy stream-analyzer -n analytics                       # 1/1 available
kubectl describe pod -n analytics -l app=stream-analyzer | grep -A3 Events  # Scheduled … assigned to <worker>
```

**What this scenario tests:** The most basic scheduling reflex — a `Pending` Pod means read `describe` / the `FailedScheduling` event, not the logs. Self-grading:

- Did you go to the event, not `kubectl logs` (which is empty — the Pod never ran)?
- Did you read past the expected control-plane taint line to the worker's `Insufficient memory`?
- Did you fix the *request* (the thing scheduling fits), not the image, the node, or the limit?

**Expected time:** 2–4 min once "Pending → read the event" is a reflex; 8–12 the first time (lost time usually goes to `kubectl logs`/`--previous` on a Pod that never ran).

**Production thinking:** Unit slips (`Mi`↔`Gi`, `m`↔whole cores) are a top cause of "won't schedule" and of silent over-reservation — a Pod that requests `4` CPUs instead of `4m` reserves four whole cores and quietly starves a node. Guard it with admission policy (a `LimitRange` capping per-container requests, or an OPA/Kyverno rule — M20) and by templating requests in one place (Kustomize/Helm — M16–M17) rather than hand-editing YAML. If the request is *genuinely* too big for any node and not a typo, that's a capacity or a right-sizing conversation (M09's VPA), not a scheduling bug.

---

## Break/fix 02 — Untolerated Taint

**Symptom:** `pstn-probe` in `edge` is `Pending`. No node is short on CPU or memory, and the rest of the fleet is `Running` normally on the same cluster.

**Root cause:** The worker node was tainted `dedicated=telephony:NoSchedule` (a dedicated node pool), and `pstn-probe` has no matching **toleration**. A taint repels every Pod that doesn't tolerate it; with the worker carrying `dedicated=telephony` and the control-plane carrying its built-in taint, `pstn-probe` fits on no node and stays `Pending` with `untolerated taint`<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/">[4]</a></sup>. The running fleet stayed put because `NoSchedule` blocks only *new* scheduling — it doesn't evict Pods already on the node (a `NoExecute` taint would have).

**Diagnostic commands (the canonical path):**

```bash
# 1. Pending — read the reason
kubectl describe pod -n edge -l app=pstn-probe | grep -A6 Events
#    ... 1 node(s) had untolerated taint {dedicated: telephony}, 1 ... {control-plane}

# 2. Taints live on the NODE, not the Pod — read them there
kubectl describe node -l '!node-role.kubernetes.io/control-plane' | grep -A2 Taints
#    Taints: dedicated=telephony:NoSchedule

# 3. The Pod tolerates nothing; contrast with sbc-edge, which reaches the tainted control-plane
kubectl get deploy pstn-probe -n edge -o jsonpath='{.spec.template.spec.tolerations}'; echo   # empty
kubectl get ds sbc-edge -n edge -o jsonpath='{.spec.template.spec.tolerations}'; echo          # control-plane toleration
```

**Fix:** Add a toleration matching the taint's key, value, and effect:

```bash
kubectl patch deployment pstn-probe -n edge --type=json -p \
  '[{"op":"add","path":"/spec/template/spec/tolerations","value":[{"key":"dedicated","value":"telephony","operator":"Equal","effect":"NoSchedule"}]}]'
# or: kubectl edit deployment pstn-probe -n edge  → add the tolerations block
```

**Verify:**

```bash
kubectl get deploy pstn-probe -n edge                                   # 1/1 available
kubectl describe pod -n edge -l app=pstn-probe | grep -A3 Events        # Scheduled … assigned to <worker>
```

**What this scenario tests:** Recognizing a taint as the cause and knowing taints live on the node. Self-grading:

- Did you read the event's `untolerated taint` and then look at the *node's* Taints, not keep inspecting the Pod?
- Did you match the toleration's key/value/effect to the taint (not a partial match that still won't satisfy it)?
- Did you understand *why* the rest of the fleet wasn't evicted (`NoSchedule` ≠ `NoExecute`)?

**Expected time:** 3–5 min; 8–15 the first time (lost time goes to checking resources, which are fine, before reading "untolerated taint").

**Production thinking:** Node taints usually arrive from something automated — a node pool provisioned as `dedicated=`, a cordon (`node.kubernetes.io/unschedulable`), a drain for maintenance, or the node controller's `NoExecute` on `not-ready`/`unreachable`<sup><a href="https://kubernetes.io/docs/reference/labels-annotations-taints/">[7]</a></sup>. When a whole workload suddenly can't schedule after a cluster change, `kubectl describe node | grep Taints` across the pool is the fast check. Tolerations are a *permission*, not a *requirement* — a toleration lets a Pod onto a tainted node but doesn't pull it there; pair it with a `nodeSelector`/nodeAffinity if you actually want the Pod *on* that pool.

---

## Break/fix 03 — Anti-affinity Unschedulable

**Symptom:** `sip-director` in `signaling` wants 3 replicas but reports `1/3` — one Pod `Running`, two `Pending`. No resource shortfall, no taint blocking it, and the one running replica proves the workload schedules.

**Root cause:** `sip-director` sets a `requiredDuringSchedulingIgnoredDuringExecution` **pod anti-affinity** on `topologyKey: kubernetes.io/hostname` — a hard "no two replicas on the same node." A required per-hostname anti-affinity needs at least as many schedulable nodes as replicas. This cluster has one schedulable node (the control-plane is tainted), so the first replica takes the worker and the other two have no distinct node to land on — they stay `Pending` with `didn't match pod anti-affinity rules`<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/">[5]</a></sup>. The rule is doing exactly what it says; the cluster can't satisfy it.

**Diagnostic commands (the canonical path):**

```bash
# 1. Some scheduled, some not — a relative placement rule
kubectl get pods -n signaling -l app=sip-director -o wide             # 1 Running, 2 Pending

# 2. Why the Pending ones fail
kubectl describe pod -n signaling -l app=sip-director | grep -A6 Events
#    ... 1 node(s) didn't match pod anti-affinity rules, 1 ... {control-plane}

# 3. The rule, and the count of nodes it needs
kubectl get deploy sip-director -n signaling \
  -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity}'; echo  # required…, topologyKey hostname
kubectl get nodes                                                     # 2 nodes, only 1 schedulable
```

**Fix (canonical — soften to best-effort spread):**

```bash
kubectl patch deployment sip-director -n signaling --type=json -p '[
  {"op":"remove","path":"/spec/template/spec/affinity/podAntiAffinity/requiredDuringSchedulingIgnoredDuringExecution"},
  {"op":"add","path":"/spec/template/spec/affinity/podAntiAffinity/preferredDuringSchedulingIgnoredDuringExecution","value":[{"weight":100,"podAffinityTerm":{"labelSelector":{"matchLabels":{"app":"sip-director"}},"topologyKey":"kubernetes.io/hostname"}}]}
]'
```

Alternatives: add schedulable nodes (or tolerate more) so the `required` rule *can* be met, or `kubectl scale deploy sip-director -n signaling --replicas=1` to fit the schedulable node count.

**Verify:**

```bash
kubectl get pods -n signaling -l app=sip-director -o wide   # all Running (on the worker)
kubectl get deploy sip-director -n signaling                # 3/3 available
```

**What this scenario tests:** Reading a partial-scheduling failure as a placement-rule problem, and the hard-vs-soft trade-off. Self-grading:

- Did "some schedule, some don't" point you at an affinity/spread rule rather than resources or a taint?
- Did you connect the rule (`required`, per-hostname) to the count of schedulable nodes, and see *why* two replicas are stuck?
- Did you recognize that softening to `preferred` trades the HA guarantee for schedulability — and note it (all three now share a node)?

**Expected time:** 4–8 min; 10–20 the first time (lost time goes to comparing the Pending and Running Pods looking for a difference between them, when the difference is the cluster's node count).

**Production thinking:** This is the classic "HA rule wedges the Deployment during a node event." A `required` anti-affinity or a `DoNotSchedule` topology spread is exactly as available as the number of schedulable domains — drain a node or lose a zone and surplus replicas go `Pending`, turning a redundancy feature into an outage during scale-up<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/">[6]</a></sup>. Prefer topology spread with `whenUnsatisfiable: ScheduleAnyway` (or `preferred` anti-affinity) for graceful degradation, and reserve the hard form for cases where co-location is genuinely unacceptable *and* you keep enough domains (plus headroom for one to fail). Alert on `Pending` Pods with an anti-affinity/spread reason so a drain doesn't silently under-replicate a service.

---

## Break/fix 04 — OOMKilled

**Symptom:** `media-buffer` in `media` schedules onto a node (unlike the first three) but won't stay up — `CrashLoopBackOff`, restart count climbing.

**Root cause:** The container pre-allocates a ~60Mi in-memory buffer at startup, but its memory **limit** is set to `48Mi`. The **request** (`32Mi`) was small enough to schedule, so placement succeeded; at runtime the buffer exceeds the 48Mi limit and the kernel OOM-kills the container — `Last State: Terminated, Reason: OOMKilled`, exit code 137 (128 + SIGKILL) — which restarts into `CrashLoopBackOff`<sup><a href="https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/">[1]</a></sup>. QoS is `Burstable` (request below limit). Requests fit; the limit didn't hold.

**Diagnostic commands (the canonical path):**

```bash
# 1. It HAS a node — not a scheduling failure. It's crashing.
kubectl get pods -n media -l app=media-buffer -o wide       # Running/CrashLoopBackOff, restarts climbing

# 2. What killed it — the last terminated state, not the FailedScheduling event
kubectl describe pod -n media -l app=media-buffer | grep -A5 'Last State'
#    Reason: OOMKilled   Exit Code: 137

# 3. The limit that's too low, and the QoS
kubectl get deploy media-buffer -n media \
  -o jsonpath='{.spec.template.spec.containers[0].resources}'; echo         # limits.memory: 48Mi
kubectl get pod -n media -l app=media-buffer -o jsonpath='{.items[0].status.qosClass}'; echo  # Burstable
```

**Fix:** Raise the memory limit above the working set:

```bash
kubectl set resources deployment/media-buffer -n media --limits=memory=128Mi
# or: kubectl edit deployment media-buffer -n media  → limits.memory 48Mi → 128Mi
```

**Verify:**

```bash
kubectl get deploy media-buffer -n media                                  # 1/1 available
kubectl describe pod -n media -l app=media-buffer | grep -A3 'State:'      # State: Running, no OOMKilled
```

**What this scenario tests:** Telling a runtime failure from a scheduling one, and the request-vs-limit distinction. Self-grading:

- Did the Pod *having a node* stop you from treating this as a scheduling problem, and send you to Last State / `OOMKilled` / exit 137?
- Did you fix the **limit** (the runtime ceiling), not the request (which was fine — the Pod scheduled)?
- Did you avoid "just remove the limit," which makes the Pod BestEffort and the first thing evicted under node pressure?

**Expected time:** 3–6 min; 8–15 the first time (lost time goes to reading the `FailedScheduling` event that isn't there, since this Pod scheduled).

**Production thinking:** OOMKills are usually one of: a limit set too low for the real working set, a genuine leak, or a workload that spikes above its steady state (a big request, a batch, a cache warm). Set limits from *observed* peak usage plus headroom, not from steady-state — a limit pinned to steady-state OOMs the first time the workload does something bigger. In-place Pod resize (GA in v1.35) can widen a too-tight limit without recreating the Pod<sup><a href="https://kubernetes.io/docs/tasks/configure-pod-container/resize-container-resources/">[8]</a></sup>, but it treats the symptom — the durable fix is right-sizing (VPA recommendations, M09) and alerting on `OOMKilled` counts, which a bare `CrashLoopBackOff` alert can miss. Don't confuse this with **eviction**: OOMKill is the kernel on one container over its own limit; eviction is the kubelet on whole Pods when the *node* is out of memory, in QoS order<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/">[3]</a></sup>.

## References

1. Kubernetes — Resource Management for Pods and Containers: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
2. Kubernetes — Pod Quality of Service Classes: https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/
3. Kubernetes — Node-pressure Eviction: https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/
4. Kubernetes — Taints and Tolerations: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
5. Kubernetes — Assigning Pods to Nodes: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/
6. Kubernetes — Pod Topology Spread Constraints: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/
7. Kubernetes — Well-Known Labels, Annotations and Taints: https://kubernetes.io/docs/reference/labels-annotations-taints/
8. Kubernetes — Resize CPU and Memory Resources assigned to Containers: https://kubernetes.io/docs/tasks/configure-pod-container/resize-container-resources/
9. Kubernetes — kube-scheduler: https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/
