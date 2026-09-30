# M06 — Scheduling — Answer Key

> Self-grading reference. Try each scenario first, then come back here to check your diagnostic path against the canonical one. Instructors running the lab live can use the same sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline: one tainted control-plane node and one worker. Each break/fix layers one small workload that fails for exactly one reason.

## Lesson summary

M06 is about kube-scheduler. It filters the nodes a Pod can use, scores the feasible nodes, and binds the Pod to the best one<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/">[1]</a></sup>. A Pod that no node can take stays `Pending`, and its `FailedScheduling` event lists each node's first failed filter. The baseline reads healthy placement. The five break/fix scenarios each produce one signature:

- `breakfix-01-insufficient-resources` — **`Pending`, `Insufficient memory`**: a request larger than any node's Allocatable
- `breakfix-02-untolerated-taint` — **`Pending`, `untolerated taint`**: a node that repels a Pod without the toleration
- `breakfix-03-antiaffinity-unschedulable` — **replicas `Pending`, `didn't match pod anti-affinity rules`**: a hard spread rule with too few nodes, and a rollout the old Pods' own rule then blocks
- `breakfix-04-oom-killed` — **`CrashLoopBackOff`, `OOMKilled`, exit code 137**: a memory limit below the container's working set
- `breakfix-05-node-affinity-mismatch` — **`Pending`, `didn't match Pod's node affinity/selector`**: a selector for a label no node carries

The through-line: **requests are what you fit, and limits are what kill you.** Four scenarios are placement failures that the scheduler names in one event. One is a runtime failure that the kernel records in the container's last state. On this cluster, every scheduling message carries an entry for the control-plane taint. Skip it and read the worker's entry.

## Baseline tour reference

No broken state. Expected output per step:

- **Step 1 (Where the fleet landed):** `kubectl get pods -A -o wide --sort-by=.spec.nodeName` shows the fleet on the worker. Only `sbc-edge` and system Pods run on the control-plane node. `kubectl describe nodes | grep -E '^Name:|^Taints:'` shows `node-role.kubernetes.io/control-plane:NoSchedule` on the control-plane node and `Taints: <none>` on the worker.
- **Step 2 (Requests, limits, QoS):** `describe pod` on `session-broker` shows requests of cpu 25m and memory 32Mi, limits of cpu 100m and memory 64Mi, and `QoS Class: Burstable`<sup><a href="https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/">[2]</a></sup>. The fleet-wide survey shows `Burstable` on every fleet Pod. `Allocated resources` on the worker shows reserved requests well above the live usage in `kubectl top nodes`.
- **Step 3 (Labels, affinity, tolerations):** `kubectl get nodes -L disktype` shows `ssd` on the worker. `media-engine` requires `disktype In [ssd]` through node affinity. `sbc-edge` runs `2/2` because it tolerates the control-plane taint. An ordinary Pod shows only the automatic `not-ready` and `unreachable` tolerations, each for 300s<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/">[3]</a></sup>.
- **Step 4 (Place a Pod):** `placement-demo` lands on the worker with `QoS Class: Guaranteed` and a `Scheduled` event. `Allocated resources` grows by 20m CPU and 64Mi memory, then drops back after the delete. If the Pod stays `Pending`, the worker's requests were already full; its events name `Insufficient cpu` or `Insufficient memory`.
- **Step 5 (Pending triage):** both `get pods --field-selector=status.phase=Pending` and `get events --field-selector reason=FailedScheduling` return nothing on the healthy cluster. The step maps each filter to its message entry.

---

## Break/fix 01 — Insufficient Resources

**Symptom:** `stream-analyzer` in `analytics` has zero available replicas. Its Pod is `Pending` with no node, and it never starts. No logs exist, and there is nothing to restart.

**Root cause:** The container's memory request slipped from `256Mi` to `256Gi`. The scheduler sums a Pod's requests and compares them with each node's free Allocatable<sup><a href="https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/">[4]</a></sup>. No node has 256Gi, so the worker fails the resource filter and the Pod stays `Pending` with `Insufficient memory`. The limit does not affect placement.

**Diagnostic commands (the canonical path):**

```bash
# 1. Pending, no NODE
kubectl get pods -n analytics -o wide

# 2. One command shows the request and the refusal
kubectl describe pod -n analytics -l app=stream-analyzer
#    Requests:  memory: 256Gi
#    FailedScheduling  0/2 nodes are available: 1 Insufficient memory,
#      1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. ...

# 3. What a node actually offers
kubectl describe nodes | grep -A6 Allocatable
#    memory: a few GiB at most, printed in Ki
```

**Fix:** Correct the request and its limit. The template change rolls a new Pod:

```bash
kubectl set resources deployment/stream-analyzer -n analytics \
  --requests=cpu=10m,memory=256Mi \
  --limits=cpu=200m,memory=512Mi
# or: kubectl edit deployment stream-analyzer -n analytics
```

Set the full resource contract rather than memory alone. The baseline intentionally packs one worker, and older lab sessions gave `stream-analyzer` a `100m` CPU request. In those sessions, fixing only memory reveals a second `FailedScheduling` reason: `Insufficient cpu`. A rollout restart does not repair that request.

**Verify:**

```bash
kubectl rollout status deployment/stream-analyzer -n analytics --timeout=120s
kubectl get deploy stream-analyzer -n analytics            # 1/1 available
kubectl describe pod -n analytics -l app=stream-analyzer   # running Pod includes a Scheduled event
```

**What this scenario tests:** The reflex that a `Pending` Pod means "read the event," not "read the logs." Self-grading questions:

- Did you open `describe pod` before `kubectl logs`?
- Did you read past the control-plane entry to the worker's `Insufficient memory`?
- Did you fix the request, rather than the nodes or the image?

**Expected time:** 2–4 min once "Pending, read the event" is a reflex; 8–12 min the first time. Lost time usually goes to `kubectl logs` on a Pod that never ran.

**Production thinking:** Unit slips are a leading cause of Pods that never schedule, and of quiet over-reservation. A request of `4` CPUs where `4m` was meant reserves four whole cores and starves the node. Guard it with a `LimitRange` that caps per-container requests, or an admission policy (M20). Template requests in one place (M16, M17) rather than hand-editing YAML. If the request is genuinely too large for any node, the answer is a capacity or right-sizing review (M09), not a scheduling fix.

---

## Break/fix 02 — Untolerated Taint

**Symptom:** `pstn-probe` in `edge` is `Pending` with no node. No node is short of resources. The rest of the fleet still runs on the worker.

**Root cause:** The worker carries `dedicated=telephony:NoSchedule`, and `pstn-probe` has no matching toleration. A `NoSchedule` taint stops the scheduler from placing any Pod that does not tolerate it, and it leaves running Pods in place<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/">[3]</a></sup>. The control-plane node repels the Pod with its own taint. So both nodes fail the taint filter, and the Pod stays `Pending`.

**Diagnostic commands (the canonical path):**

```bash
# 1. Pending, and the reason is a taint, not a shortage
kubectl describe pod -n edge -l app=pstn-probe
#    FailedScheduling  0/2 nodes are available:
#      1 node(s) had untolerated taint {dedicated: telephony},
#      1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. ...
#    Tolerations: only not-ready and unreachable (the automatic pair)

# 2. Taints live on the node
kubectl describe nodes | grep -E '^Name:|^Taints:'
#    worker: dedicated=telephony:NoSchedule

# 3. NoSchedule did not evict the running fleet
kubectl get pods -A -o wide --sort-by=.spec.nodeName
```

**Fix:** Add a toleration whose key, value and effect match the taint:

```bash
kubectl patch deployment pstn-probe -n edge --type=json -p \
  '[{"op":"add","path":"/spec/template/spec/tolerations","value":[{"key":"dedicated","operator":"Equal","value":"telephony","effect":"NoSchedule"}]}]'
# or: kubectl edit deployment pstn-probe -n edge
```

**Verify:**

```bash
kubectl get deploy pstn-probe -n edge         # 1/1 available
kubectl describe pod -n edge -l app=pstn-probe   # Tolerations: dedicated=telephony:NoSchedule
```

**What this scenario tests:** Reading a taint on the node rather than hunting for a problem on the Pod. Self-grading questions:

- Did the absence of `Insufficient` in the event send you to `describe node`?
- Did you notice that the running fleet stayed put, and connect that to `NoSchedule`?
- Did you add a toleration, rather than remove the platform team's taint?

**Expected time:** 3–5 min; 8–15 min the first time. Lost time usually goes to checking resources that are fine.

**Production thinking:** Node taints usually arrive from automation: a node pool provisioned with a `dedicated=` taint, a cordon, a drain, or the node controller's `NoExecute` taints on a failed node<sup><a href="https://kubernetes.io/docs/reference/labels-annotations-taints/">[5]</a></sup>. When a whole workload stops scheduling after a cluster change, read the taints across the pool first. A toleration is permission, not attraction. It lets a Pod onto a tainted node and does not pull it there. To pin a workload to a dedicated pool, pair the toleration with a node affinity to that pool.

---

## Break/fix 03 — Anti-affinity Unschedulable

**Symptom:** `sip-director` in `signaling` shows `1/3` ready. One Pod runs on the worker. Two are `Pending` with no node.

**Root cause:** The Pod template carries a `requiredDuringSchedulingIgnoredDuringExecution` pod anti-affinity on `kubernetes.io/hostname`: no two replicas on one node<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/">[6]</a></sup>. The control-plane taint leaves one schedulable node. The first replica takes it, and the other two report `didn't match pod anti-affinity rules`.

**Diagnostic commands (the canonical path):**

```bash
# 1. Some replicas run and some do not: suspect a rule between replicas
kubectl get pods -n signaling -l app=sip-director -o wide

# 2. The reason on a Pending replica
kubectl describe pod -n signaling -l app=sip-director
#    FailedScheduling  0/2 nodes are available: 1 node(s) didn't match pod anti-affinity rules,
#      1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. ...

# 3. The rule, and the node count it needs
kubectl get deploy sip-director -n signaling -o yaml | grep -A6 podAntiAffinity
kubectl get nodes
```

**Fix:** Soften the rule to `preferred`, then clear the old Pods. Required anti-affinity is symmetric: the scheduler also checks the rules of Pods already on a node. The old running replica still carries the hard rule, so it repels the new ReplicaSet's Pods with `didn't satisfy existing pods anti-affinity rules`. With 3 replicas, the default `maxUnavailable` of 25% rounds down to 0, so the Deployment controller never removes that old Pod. The rollout stalls until the old Pods go:

```bash
kubectl patch deployment sip-director -n signaling --type=json -p '[
  {"op":"remove","path":"/spec/template/spec/affinity/podAntiAffinity/requiredDuringSchedulingIgnoredDuringExecution"},
  {"op":"add","path":"/spec/template/spec/affinity/podAntiAffinity/preferredDuringSchedulingIgnoredDuringExecution","value":[{"weight":100,"podAffinityTerm":{"labelSelector":{"matchLabels":{"app":"sip-director"}},"topologyKey":"kubernetes.io/hostname"}}]}
]'
kubectl rollout status deployment/sip-director -n signaling --timeout=20s   # times out: the stall

kubectl scale deployment sip-director -n signaling --replicas=0
kubectl wait --for=delete pod -n signaling -l app=sip-director --timeout=60s
kubectl scale deployment sip-director -n signaling --replicas=3
# accepted alternative: kubectl scale deployment sip-director -n signaling --replicas=1
```

**Verify:**

```bash
kubectl get deploy sip-director -n signaling                  # 3/3 available
kubectl get pods -n signaling -l app=sip-director -o wide     # all three on the worker
```

<details>
<summary>📖 Going deeper: why the soft rule alone does not finish the rollout<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/">[6]</a></sup></summary>

Two mechanisms interlock. The scheduler's inter-pod affinity filter checks three things for each node: the incoming Pod's required affinity, its required anti-affinity, and the required anti-affinity of every Pod already on the node. The third check fails here, because the old Pod's term selects `app: sip-director` and the new Pods carry that label.

The Deployment controller, for its part, keeps at least `replicas - maxUnavailable` Pods available. Three replicas at 25% give a `maxUnavailable` of 0 after rounding down, and one old Pod is the only available one. The controller cannot remove it, and the new Pod cannot land beside it.

A spare node dissolves the stall: the new Pods land there, become available, and the controller then retires the old ones. In production, keep that headroom, raise `maxUnavailable`, or add `matchLabelKeys: [pod-template-hash]` to the anti-affinity term (stable from v1.33), so each revision only repels its own Pods.

</details>

**What this scenario tests:** Reading a rule the workload imposes on itself, and checking a rollout after the fix instead of assuming it. Self-grading questions:

- Did you compare the Pending replicas with the cluster's schedulable node count, rather than hunt for a difference between Pods?
- After the patch, did you read the rollout state and spot the new reason, `didn't satisfy existing pods anti-affinity rules`?
- Can you state what softening the rule gave up?

**Expected time:** 6–10 min; 15–25 min the first time. Lost time goes first to comparing the Pods, then to waiting on a rollout that cannot finish.

**Production thinking:** A hard spread rule is as available as the number of schedulable domains. Drain a node or lose a zone, and surplus replicas go `Pending`. The redundancy feature then blocks scale-up during the incident it exists for<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/">[7]</a></sup>. Prefer topology spread with `whenUnsatisfiable: ScheduleAnyway`, or `preferred` anti-affinity. Keep the hard form for cases where co-location is truly unacceptable, and only with enough domains plus headroom for one to fail. Alert on `Pending` Pods whose reason names anti-affinity or spread, so a drain cannot quietly under-replicate a service.

---

## Break/fix 04 — OOMKilled

**Symptom:** `media-buffer` in `media` has a node, unlike the first three scenarios, but it does not stay up. It cycles through `CrashLoopBackOff`, and its restart count climbs.

**Root cause:** The container writes about 60Mi into a memory-backed `emptyDir` at startup, and the kernel charges that memory to the container. Its memory limit is `48Mi`. The `32Mi` request was small enough to schedule. At runtime, the kernel's OOM killer ends the container on every start: `Last State: Terminated`, `Reason: OOMKilled`, exit code 137 (128 + SIGKILL)<sup><a href="https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/">[4]</a></sup>. QoS is `Burstable`. The request fit, and the limit did not hold the workload.

**Diagnostic commands (the canonical path):**

```bash
# 1. It HAS a node. This is not a scheduling failure.
kubectl get pods -n media -l app=media-buffer -o wide      # CrashLoopBackOff, RESTARTS climbing

# 2. The last state, the limit and the class, in one output
kubectl describe pod -n media -l app=media-buffer
#    Last State: Terminated   Reason: OOMKilled   Exit Code: 137
#    Limits:   memory: 48Mi
#    Requests: memory: 32Mi
#    QoS Class: Burstable
```

**Fix:** Raise the memory limit above the working set:

```bash
kubectl set resources deployment/media-buffer -n media --limits=memory=128Mi
# or: kubectl edit deployment media-buffer -n media   → limits.memory 48Mi → 128Mi
```

**Verify:**

```bash
kubectl get deploy media-buffer -n media                # 1/1 available, RESTARTS 0
kubectl top pod -n media -l app=media-buffer            # about 60Mi, under the 128Mi limit
```

**What this scenario tests:** Telling a runtime failure from a scheduling one, and the request-versus-limit split. Self-grading questions:

- Did the Pod's `NODE` stop you from treating this as a scheduling problem, and send you to `Last State:`?
- Did you raise the limit, and leave the request alone because it was fine?
- Did you avoid "just remove the limit"? With no limits and no requests, the Pod becomes `BestEffort`, the first candidate when the node runs low.

**Expected time:** 3–6 min; 8–15 min the first time. Lost time usually goes to looking for a `FailedScheduling` event that does not exist.

**Production thinking:** An OOMKill has one of three causes: a limit set below the real working set, a genuine leak, or a workload that spikes above its steady state. Set limits from observed peak usage plus headroom, never from the steady state. In-place Pod resize, stable in v1.35, widens a tight limit without recreating the Pod<sup><a href="https://kubernetes.io/docs/tasks/configure-pod-container/resize-container-resources/">[8]</a></sup>. It treats the symptom. The durable fix is right-sizing (M09) plus an alert on `OOMKilled` counts, which a plain `CrashLoopBackOff` alert can miss. Do not confuse this with node-pressure eviction. The kernel kills one container over its own limit. The kubelet evicts whole Pods when the node runs low, and it ranks them by usage over requests, then by priority<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/">[9]</a></sup>.

---

## Break/fix 05 — Node Affinity Mismatch

**Symptom:** `conference-mixer` in `media` is `Pending` with no node. No node is short of resources, and no new taint is present. Other media workloads that ask for fast disks run on the worker.

**Root cause:** The Pod's `nodeSelector` asks for `disktype=nvme`, a label from another region's node pool. The worker carries `disktype=ssd`, and the control-plane node carries no `disktype` label. Kubernetes "only schedules the Pod onto nodes that have each of the labels you specify"<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/">[6]</a></sup>. The worker passes the taint filter and fails the node-affinity filter, so the Pod stays `Pending`.

**Diagnostic commands (the canonical path):**

```bash
# 1. The reason, and what the Pod asks for, in one output
kubectl describe pod -n media -l app=conference-mixer
#    Node-Selectors: disktype=nvme
#    FailedScheduling  0/2 nodes are available: 1 node(s) didn't match Pod's node affinity/selector,
#      1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. ...

# 2. What the nodes carry
kubectl get nodes -L disktype
#    worker: ssd; control-plane: (empty). No node has nvme.

# 3. A healthy workload that asks for the right label
kubectl get statefulset media-engine -n media -o yaml | grep -A6 nodeAffinity
```

**Fix:** Correct the Pod's selector to the label the hardware carries:

```bash
kubectl patch deployment conference-mixer -n media \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"disktype":"ssd"}}}}}'
# or: kubectl edit deployment conference-mixer -n media   → nodeSelector.disktype: ssd
```

**Verify:**

```bash
kubectl get deploy conference-mixer -n media                   # 1/1 available
kubectl describe pod -n media -l app=conference-mixer          # Node-Selectors: disktype=ssd; Scheduled
```

**What this scenario tests:** Comparing what a Pod asks for with what the nodes carry, and fixing the side that is wrong. Self-grading questions:

- Did you read `Node-Selectors:` and `kubectl get nodes -L disktype` side by side?
- Did you fix the selector, rather than relabel the worker `disktype=nvme`? A node label is a claim about hardware, and a false one misleads every other workload that reads it.
- Can you name the filter this node failed, and the earlier filter the control-plane node failed?

**Expected time:** 2–4 min; 6–10 min the first time. Lost time usually goes to checking resources and taints, which are fine.

**Production thinking:** Selector mismatches arrive with copied manifests and with node-pool changes. A pool rebuilt with new labels strands every workload that selects the old ones, and `IgnoredDuringExecution` hides the problem until the next reschedule, because running Pods stay. Keep node labels in one vocabulary across regions, use the well-known labels (`topology.kubernetes.io/zone`, `kubernetes.io/arch`) where they fit, and check `kubectl get nodes -L <key>` in every target cluster before a rollout. Use `preferred` node affinity when the label is an optimization rather than a requirement.

## References

1. Kubernetes — Kubernetes Scheduler: https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/
2. Kubernetes — Pod Quality of Service Classes: https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/
3. Kubernetes — Taints and Tolerations: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
4. Kubernetes — Resource Management for Pods and Containers: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
5. Kubernetes — Well-Known Labels, Annotations and Taints: https://kubernetes.io/docs/reference/labels-annotations-taints/
6. Kubernetes — Assigning Pods to Nodes: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/
7. Kubernetes — Pod Topology Spread Constraints: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/
8. Kubernetes — Resize CPU and Memory Resources assigned to Containers: https://kubernetes.io/docs/tasks/configure-pod-container/resize-container-resources/
9. Kubernetes — Node-pressure Eviction: https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/
