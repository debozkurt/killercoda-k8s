# M07 — Workloads II — Answer Key

> Self-grading reference. Try each scenario first, then come back here to check your diagnostic path against the canonical one. Instructors running the lab live can use the same sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline: one tainted control-plane node and one worker. The baseline reads the fleet's StatefulSets and the `sbc-edge` DaemonSet. Each break/fix layers one small workload that breaks one guarantee.

## Lesson summary

M07 covers the two workload controllers a Deployment cannot replace. A **StatefulSet** adds three guarantees: a stable **ordinal name** (`<name>-0`), a stable **per-Pod DNS name** (`<pod>.<serviceName>.<ns>.svc.cluster.local`, served by a headless Service you create), and a stable **claim per ordinal** from a `volumeClaimTemplate`<sup><a href="https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/">[1]</a></sup>. Under the default `OrderedReady` policy it also works in order, and it never acts while a Pod it created is un-Ready. A **DaemonSet** guarantees one Pod per eligible node. A node is eligible when the Pod's selector and affinity match it and the Pod tolerates its taints<sup><a href="https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/">[3]</a></sup>. `desiredNumberScheduled` is the coverage number.

The five break/fix scenarios each produce one signature:

- `breakfix-01-headless-service-missing` — **Pods `Running`, per-Pod name returns `NXDOMAIN`**: nobody created the governing Service
- `breakfix-02-ordered-rollout-stall` — **`READY 0/3`, one Pod**: a probe on the wrong port, and a repair that needs a manual delete
- `breakfix-03-daemonset-node-coverage` — **`DESIRED 1` on 2 nodes**: a missing toleration for the control-plane taint
- `breakfix-04-statefulset-update-halt` — **`READY 2/3`, two revisions in one set**: a release with a bad image halted at the highest ordinal
- `breakfix-05-daemonset-selector-mismatch` — **`DESIRED 0`, no Pod, no event**: a selector for a label no node carries

The through-line: **these controllers fail with a healthy-looking status.** Four of the five scenarios leave nothing red. The Pods run, or no Pod exists to be red. You find the fault by checking that the guarantee held: does the name resolve, do all ordinals exist, is every node that needs the agent covered?

## Baseline tour reference

No broken state. Expected output per step:

- **Step 1 (Two controllers):** `kubectl get statefulset -A` lists four (`media-engine`, `reg-proxy`, `presence`, `pstn-gateway`). Their Pods carry ordinal names (`media-engine-0`, `-1`), unlike a Deployment's random suffix. `kubectl get daemonset -A` lists `sbc-edge`, and `get pods -o wide` shows one Pod per node.
- **Step 2 (Identity):** `serviceName: media-engine` appears in the StatefulSet YAML. `describe svc media-engine` shows `IP: None` and one endpoint per Pod. From a `busybox` Pod, `nslookup media-engine-0.media-engine.media.svc.cluster.local` resolves to ordinal 0's Pod IP, and `-1` resolves to a different IP<sup><a href="https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/">[2]</a></sup>.
- **Step 3 (Storage):** `get pvc -n media` shows `state-media-engine-0` and `-1`, both `Bound`. `describe statefulset media-engine` shows a `Volume Claims:` block with the template `state`. `describe pod media-engine-0` shows `ClaimName: state-media-engine-0` under `Volumes:`.
- **Step 4 (Delete a Pod):** after `kubectl delete pod media-engine-0`, the replacement has the same name, a new `AGE`, and usually a new IP. The marker file `/var/state/role` survives, and the DNS name resolves to the new IP. After the scale-down to 1, `state-media-engine-1` stays `Bound`. After the scale-up, ordinal 1 returns with its marker. If `kubectl wait` reports `not found`, the controller has not yet created the replacement. Run the command again.
- **Step 5 (DaemonSet):** `describe daemonset sbc-edge` shows `Desired Number of Nodes Scheduled: 2` and a `Tolerations:` line that names `node-role.kubernetes.io/control-plane`. The control-plane node carries `node-role.kubernetes.io/control-plane:NoSchedule`, and the worker carries no taint<sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/">[4]</a></sup>.

---

## Break/fix 01 — Headless Service Missing

**Symptom:** `session-store`, a 3-replica StatefulSet in `app-services`, has all three Pods `Running`, `READY 3/3`, with correct names. Its members cannot reach each other. `nslookup session-store-0.session-store.app-services.svc.cluster.local` returns `NXDOMAIN`.

**Root cause:** The StatefulSet names `serviceName: session-store`, and no such Service exists. The docs state: "StatefulSets currently require a Headless Service to be responsible for the network identity of the Pods. You are responsible for creating this Service."<sup><a href="https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#limitations">[1]</a></sup> Without a headless Service that selects the Pods, cluster DNS has nothing from which to publish the per-Pod records<sup><a href="https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/">[2]</a></sup>. Ordinal identity and storage are intact, so the Pods look healthy.

**Diagnostic commands (the canonical path):**

```bash
# 1. The Pods are up: not a crash, not a scheduling problem
kubectl get statefulset session-store -n app-services       # READY 3/3
kubectl get pods -n app-services -l app=session-store       # -0, -1, -2 Running

# 2. The per-Pod name does not resolve
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \
  nslookup session-store-0.session-store.app-services.svc.cluster.local   # NXDOMAIN

# 3. The Service the StatefulSet expects, and its absence
kubectl get statefulset session-store -n app-services -o yaml | grep serviceName   # session-store
kubectl get svc -n app-services                              # no session-store
```

**Fix:** Create the governing Service, headless, with a selector for the Pods:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: session-store
  namespace: app-services
  labels: { app: session-store, plane: app, tier: lab }
spec:
  clusterIP: None
  selector: { app: session-store }
  ports: [{ port: 80, name: http }]
EOF
```

**Verify:**

```bash
kubectl describe svc session-store -n app-services           # IP: None; Endpoints: three addresses
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \
  nslookup session-store-0.session-store.app-services.svc.cluster.local   # Pod IP
```

**What this scenario tests:** Whether you treat identity as a guarantee to check, not an assumption. Self-grading questions:

- Did you test name resolution, rather than stop at `get pods`?
- Did you find the Service through `serviceName` plus `get svc`, rather than suspect CoreDNS or the Pods?
- Did you create the Service headless? A ClusterIP Service gives one virtual IP and publishes no per-Pod records.

**Expected time:** 3–6 min once "StatefulSet identity needs a headless Service" is a reflex; 10–15 min the first time. Lost time usually goes to the healthy Pods and to CoreDNS.

**Production thinking:** This is the commonest StatefulSet mistake. The manifest ships the StatefulSet and forgets the Service, misnames it, or gives it a ClusterIP. It passes every "are the Pods up?" check and fails when peers look for each other, which may be minutes into a bootstrap. Ship the StatefulSet and its headless Service in one chart or one Kustomize base (M16, M17) so they cannot drift. Make the application resolve a peer name in its startup or readiness check, so a DNS gap becomes a failing probe.

---

## Break/fix 02 — Ordered Rollout Stall

**Symptom:** `session-store` (3 replicas, headless Service present) reads `READY 0/3`. One Pod, `session-store-0`, exists, `Running` and `0/1`. Ordinals 1 and 2 were never created.

**Root cause:** The readiness probe targets port 8080, and the container serves port 80. Every probe is refused, so the kubelet never marks ordinal 0 Ready. Under `OrderedReady`, the controller creates ordinal `N+1` only after ordinal `N` is Running and Ready<sup><a href="https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#deployment-and-scaling-guarantees">[1]</a></sup>. The controller therefore never creates ordinals 1 and 2. A Deployment would have created all three Pods at once.

**Diagnostic commands (the canonical path):**

```bash
# 1. One Pod and a 0/3 set: a StatefulSet-shaped stall
kubectl get statefulset session-store -n app-services       # READY 0/3
kubectl get pods -n app-services -l app=session-store       # only session-store-0, 0/1

# 2. One describe shows the cause
kubectl describe pod session-store-0 -n app-services
#    Conditions:  Ready False
#    Readiness:   http-get ... :8080/ ...
#    Events:      Readiness probe failed ... connection refused
#    Port: 80 (container); probe on 8080
```

**Fix:** Correct the probe port, then delete the Pod that runs the old template:

```bash
kubectl patch statefulset session-store -n app-services --type=json -p \
  '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":80}]'
kubectl rollout status statefulset/session-store -n app-services --timeout=20s   # times out: ordinal 0 unchanged
kubectl delete pod session-store-0 -n app-services           # recreated from the corrected template
```

**Verify:**

```bash
kubectl rollout status statefulset/session-store -n app-services --timeout=120s
kubectl get statefulset session-store -n app-services       # READY 3/3
kubectl get pods -n app-services -l app=session-store       # -0, -1, -2 all 1/1
```

**What this scenario tests:** Reading the ordered lifecycle, and knowing the repair the controller skips. Self-grading questions:

- Did you read one Pod and two absences as "the gate never opened", rather than look for three failed Pods?
- Did you diagnose ordinal 0's probe, not restart the whole set?
- Did you expect the patch alone to fix ordinal 0, and what showed you it did not?

<details>
<summary>📖 Going deeper: why the patch alone does not replace ordinal 0<sup><a href="https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#forced-rollback">[1]</a></sup></summary>

The docs call this case "Forced rollback". In `stateful_set_control.go`<sup><a href="https://github.com/kubernetes/kubernetes/blob/master/pkg/controller/statefulset/stateful_set_control.go">[5]</a></sup>, the loop over the existing Pods runs first. For each Pod under `OrderedReady`, the controller returns early when the Pod "has been created but is not running and ready". The code comment gives the reason: the controller must ensure that all predecessors of a Pod it creates are Running and Ready. The reverse-ordinal update loop comes later in the same function, so the controller never reaches it while ordinal 0 is un-Ready. The template changed, and nothing deletes the Pod that carries the old one.

A Pod in phase `Failed` or `Succeeded` is the exception. The controller deletes and recreates it before it reaches the early return. A Running Pod that is not Ready is not an exception.

</details>

**Expected time:** 5–8 min. The first time takes longer: learners expect the patch to roll the Pod, and then wonder why `AGE` has not changed.

**Production thinking:** `OrderedReady` suits an application that must bootstrap a seed before its peers join. It also converts one wrong health check into a total stall, and the repair needs a human to delete a Pod. Know the options. `podManagementPolicy: Parallel` removes the creation gate and keeps names and storage stable, for applications that do not need ordered startup. Test readiness probes against the real container port in CI, because a StatefulSet gates far more than one Pod on that probe.

---

## Break/fix 03 — DaemonSet Node Coverage

**Symptom:** `rtp-probe`, a DaemonSet in `edge` that should run on every node, reports `DESIRED 1` on a 2-node cluster. Its Pod runs on the worker. The control-plane node has none. Nothing is `Pending`, and no event appears.

**Root cause:** The Pod template lacks a toleration for `node-role.kubernetes.io/control-plane:NoSchedule`. The controller counts a node in `desiredNumberScheduled` only when the Pod matches the node's selector and affinity and tolerates its taints<sup><a href="https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/">[3]</a></sup><sup><a href="https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/">[4]</a></sup>. The control-plane node is ineligible, so the controller never creates a Pod for it. The fleet's `sbc-edge` reaches both nodes because it carries the toleration.

**Diagnostic commands (the canonical path):**

```bash
# 1. DESIRED is the coverage number, and it is short
kubectl get daemonset -n edge                # sbc-edge DESIRED 2; rtp-probe DESIRED 1
kubectl get pods -n edge -o wide             # rtp-probe only on the worker

# 2. The uncovered node is tainted
kubectl describe nodes | grep -E '^Name:|^Taints:'
#    control-plane: node-role.kubernetes.io/control-plane:NoSchedule

# 3. One DaemonSet tolerates the taint and the other does not
kubectl describe daemonset sbc-edge rtp-probe -n edge | grep -E '^Name:|Tolerations:'
```

**Fix:** Add the toleration that `sbc-edge` uses:

```bash
kubectl patch daemonset rtp-probe -n edge --type=json -p \
  '[{"op":"add","path":"/spec/template/spec/tolerations","value":[{"key":"node-role.kubernetes.io/control-plane","operator":"Exists","effect":"NoSchedule"}]}]'
# or: kubectl edit daemonset rtp-probe -n edge   → add the tolerations block
```

**Verify:**

```bash
kubectl get daemonset rtp-probe -n edge                      # DESIRED 2, CURRENT 2, READY 2
kubectl get pods -n edge -l app=rtp-probe -o wide            # a Pod on the control-plane node
```

**What this scenario tests:** Reading `DESIRED` as a coverage check. Self-grading questions:

- Did you treat `DESIRED 1` as the defect, instead of looking for a crashed or `Pending` Pod that does not exist?
- Did you compare the node's taint with both DaemonSets' tolerations?
- Did you match key and effect, rather than guess at resources or affinity?

**Expected time:** 3–6 min. The hard part is trusting `DESIRED 1` as a defect when no status is red.

**Production thinking:** Node-local agents (log shippers, security agents, CNI and CSI plugins, node exporters) miss nodes this way. A taint arrives on a node pool after the DaemonSet shipped, or the DaemonSet never tolerated the control-plane taint. Because the failure is silent, alert when a critical DaemonSet's `desiredNumberScheduled` is below the count of nodes that need it, and check the control-plane and tainted pools first. When an agent must run everywhere, `tolerations: [{ operator: Exists }]` tolerates every taint. Prefer specific tolerations, so the agent does not land on a node that is cordoned or under pressure for a reason.

---

## Break/fix 04 — StatefulSet Update Halt

**Symptom:** After a release, `session-store` reads `READY 2/3`. `kubectl rollout status` waits and then times out. `kubectl get pods -L controller-revision-hash` shows `session-store-0` and `-1` on one hash, and `session-store-2` on another, in `ErrImagePull` or `ImagePullBackOff`.

**Root cause:** The release set the image to `nginx:1.25.99`, a tag that does not exist. `RollingUpdate` replaces Pods from the highest ordinal down<sup><a href="https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#update-strategies">[1]</a></sup>. It replaced `session-store-2` first. That Pod cannot pull its image and never becomes Ready, so the controller stops. Ordinals 0 and 1 stay on the old revision and keep serving. The reverse order contained the failure to one Pod.

**Diagnostic commands (the canonical path):**

```bash
# 1. The rollout does not finish
kubectl rollout status statefulset/session-store -n app-services --timeout=15s   # times out

# 2. Two revisions in one set
kubectl get pods -n app-services -l app=session-store -L controller-revision-hash
#    -0, -1: Running, hash A.  -2: ImagePullBackOff, hash B.

# 3. Why ordinal 2 fails
kubectl describe pod session-store-2 -n app-services
#    Image:   nginx:1.25.99
#    Events:  Failed to pull image ... not found
```

**Fix:** Roll the template back, then delete the Pod that runs the bad one:

```bash
kubectl rollout undo statefulset/session-store -n app-services
kubectl get pods -n app-services -l app=session-store -L controller-revision-hash   # -2 unchanged
kubectl delete pod session-store-2 -n app-services
```

**Verify:**

```bash
kubectl rollout status statefulset/session-store -n app-services --timeout=120s
kubectl get pods -n app-services -l app=session-store -L controller-revision-hash   # one hash; -0 and -1 older
```

**What this scenario tests:** The update-time form of the wait rule, and the blast radius of a StatefulSet release. Self-grading questions:

- Did you find the revision split with `controller-revision-hash`, and name ordinal 2 as the first Pod the rollout touched?
- Did you expect `rollout undo` alone to repair ordinal 2, and what showed you it did not?
- Did you leave ordinals 0 and 1 running?

<details>
<summary>📖 Going deeper: containing a release with partition<sup><a href="https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#partitions">[1]</a></sup></summary>

`partition` turns the reverse-ordinal order into a staged release. Set `rollingUpdate.partition: 2` before you push, and only ordinal 2 receives the new template. Ordinals 0 and 1 stay on the old revision, and the docs state that "even if they are deleted, they will be recreated at the previous version." You verify ordinal 2, then lower the partition to 1 and then to 0. With this release, the bad image would have stopped at the canary, and the pipeline could check `readyReplicas` for ordinal 2 before it widened.

The operational signals: a pager rule on `kube_statefulset_status_replicas_ready` below `kube_statefulset_replicas` for more than a few minutes, and a rollout check that fails the pipeline when `status.updatedReplicas` stops moving. Both catch a halted release that no alert on "Pods Running" would catch. A partition larger than `replicas` blocks all template changes, which is also a way to freeze a set.

</details>

**Expected time:** 5–8 min. Lost time usually goes to the Deployment instinct: waiting for the controller to retry.

**Production thinking:** A StatefulSet release halts by design, and the halted state serves traffic with a mixed revision. Decide in advance whether your application tolerates two revisions in one cluster, because every halted release lives in that state until a human acts. Pre-pull or pin images by digest, so a typo fails in CI instead of in the rollout. Use `partition` for stores where one wrong member is expensive.

---

## Break/fix 05 — DaemonSet Selector Mismatch

**Symptom:** `disk-exporter`, a DaemonSet in `media`, reports `DESIRED 0`, and no Pod of it exists. The rollout reports success. Nothing is `Pending`, and no event appears.

**Root cause:** The Pod template's `nodeSelector` asks for `disktype=nvme`, a label from another region's node pool. The worker carries `disktype=ssd`, and the control-plane node carries no `disktype` label. The controller creates Pods "on nodes which match that node selector"<sup><a href="https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/">[3]</a></sup>, so it finds no eligible node and creates no Pod. A Deployment with the same selector would leave a `Pending` Pod and a `FailedScheduling` event, because the Deployment creates the Pod first and lets the scheduler refuse it.

**Diagnostic commands (the canonical path):**

```bash
# 1. DESIRED is zero, and the selector column names the label
kubectl get daemonset -A                     # disk-exporter 0 0 0 ... disktype=nvme

# 2. The template's selector, and the lack of events
kubectl describe daemonset disk-exporter -n media
#    Desired Number of Nodes Scheduled: 0
#    Node-Selectors: disktype=nvme

# 3. What the nodes carry
kubectl get nodes -L disktype                # worker: ssd; control-plane: empty
```

**Fix:** Correct the selector to the label the hardware carries:

```bash
kubectl patch daemonset disk-exporter -n media \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"disktype":"ssd"}}}}}'
# or: kubectl edit daemonset disk-exporter -n media   → nodeSelector.disktype: ssd
```

**Verify:**

```bash
kubectl get daemonset disk-exporter -n media                 # DESIRED 1, READY 1
kubectl get pods -n media -l app=disk-exporter -o wide       # one Pod, on the worker
```

**What this scenario tests:** Separating "no eligible node" from "a Pod that cannot start". Self-grading questions:

- Did you compare `DESIRED` with the nodes the agent belongs on? Here the correct value is 1, not 2.
- Did you fix the selector rather than relabel the worker `disktype=nvme`? A node label is a claim about hardware, and a false one misleads every workload that reads it.
- Can you say why this DaemonSet shows no `Pending` Pod, while M06's Deployment with the same selector did?

**Expected time:** 3–5 min. The same label mismatch as M06 appears in a different place, and learners lose time looking for a `Pending` Pod.

**Production thinking:** Selector mismatches arrive with copied manifests and with rebuilt node pools. A DaemonSet hides them, because `rollout status` succeeds when the desired count is zero. Alert on DaemonSets whose `desiredNumberScheduled` is 0 for longer than a deployment window. Keep node labels in one vocabulary across clusters, use the well-known labels where they fit, and run `kubectl get nodes -L <key>` in each target cluster before a rollout. Use `preferred` node affinity when the label is an optimization and not a requirement.

## References

1. Kubernetes — StatefulSets: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
2. Kubernetes — DNS for Services and Pods: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
3. Kubernetes — DaemonSet: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/
4. Kubernetes — Taints and Tolerations: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
5. Kubernetes source — StatefulSet controller: https://github.com/kubernetes/kubernetes/blob/master/pkg/controller/statefulset/stateful_set_control.go
