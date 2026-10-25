# SRE Practice Lab: Answer Key and Facilitator Notes

> Solutions for the practice lab. Try the scenarios before you read them. The notes also work as a script for running the lab with a teammate.
> Environment: Killercoda kubernetes-kubeadm-2nodes with local-path-provisioner
> 8 scenarios | 20 minutes | AI tools allowed

---

## Facilitator Cheat Sheet

| # | Namespace | Symptom at a glance | Difficulty |
|---|-----------|-------------------|------------|
| 1 | `provisioning` | `CreateContainerConfigError` (wrong secret name) | Beginner |
| 2 | `call-analytics` | `CrashLoopBackOff` (OOMKilled) | Beginner |
| 3 | `cdr-storage` | Pod `Pending`, wrong volume reference | Beginner |
| 4 | `admin-portal` | Pods Running, Service has no endpoints | Intermediate |
| 5 | `call-routing` | Pods Running, endpoints exist, connection refused | Intermediate |
| 6 | `number-porting` | 2/3 replicas up, no pod errors | Intermediate |
| 7 | `media-processing` | Pod `Pending` (scheduling) | Intermediate |
| 8 | `service-mesh` | Pod Running, app broken internally | Advanced |

**Suggested set for newer engineers:** 1, 2, 3, 4, 5, 6
**Suggested set for experienced engineers:** 3, 4, 5, 6, 7, 8

---

# Step 1: Operational Tasks — Answer Key

Rapid-fire. Each should take 10-30 seconds for someone comfortable. These run BEFORE the break/fix scenarios to warm up and gauge baseline comfort.

---

### Context & Config

**1. List all kubectl contexts**
```bash
kubectl config get-contexts
```

**2. Set default namespace to admin-portal**
```bash
kubectl config set-context --current --namespace=admin-portal
```
**Watch for:** Do they know `set-context --current`? Or do they use `kubens` if available? Both fine.

**3. Switch back to default namespace**
```bash
kubectl config set-context --current --namespace=default
```

---

### Resource Inspection

**4. Show resource requests/limits for all pods in call-analytics**
```bash
kubectl describe pod -n call-analytics | grep -A3 "Limits\|Requests"
# or
kubectl get pods -n call-analytics -o custom-columns="NAME:.metadata.name,CPU_REQ:.spec.containers[*].resources.requests.cpu,MEM_REQ:.spec.containers[*].resources.requests.memory,CPU_LIM:.spec.containers[*].resources.limits.cpu,MEM_LIM:.spec.containers[*].resources.limits.memory"
```
**Watch for:** Do they use `describe` and grep, or do they know `custom-columns` / jsonpath? The latter shows deeper kubectl fluency.

**5. Check resource usage (CPU/memory) of all pods**
```bash
kubectl top pods -A
```
**Note:** Metrics-server is installed but may need ~60s after cluster setup to start reporting. If candidate gets "metrics not yet available", just wait a moment and retry.

**6. Which node is each portal-ui pod on?**
```bash
kubectl get pods -n admin-portal -o wide
```

**7. Export route-engine-svc YAML**
```bash
kubectl get svc route-engine-svc -n call-routing -o yaml
```

**8. List all ResourceQuotas across the cluster**
```bash
kubectl get resourcequota -A
```
**Watch for:** Do they know ResourceQuota is a queryable resource? Shows awareness of namespace-level governance.

**9. What ServiceAccounts exist in provisioning?**
```bash
kubectl get sa -n provisioning
```
**Watch for:** Do they know `sa` as shorthand for `serviceaccounts`?

---

### Scaling & Rollouts

**10. Scale portal-ui to 5 replicas**
```bash
kubectl scale deployment portal-ui --replicas=5 -n admin-portal
```

**11. Rolling restart of route-engine**
```bash
kubectl rollout restart deployment route-engine -n call-routing
```

**12. Check rollout status**
```bash
kubectl rollout status deployment route-engine -n call-routing
```

**13. Show rollout history for route-engine**
```bash
kubectl rollout history deployment route-engine -n call-routing
```
**Watch for:** Do they know `rollout history`? This is how you check revision history for rollbacks.

---

### Logs & Debugging

**14. Recent logs from route-engine pods**
```bash
kubectl logs -l app=route-engine -n call-routing
# or for a specific pod:
kubectl logs <pod> -n call-routing
```
**Watch for:** Do they know `-l` for label-based log queries? Do they tail with `-f`?

**15. Exec into route-engine pod and test connectivity**
```bash
kubectl exec -it <pod> -n call-routing -- curl -s route-engine-svc:80
# or if curl isn't in the image:
kubectl exec -it <pod> -n call-routing -- wget -qO- route-engine-svc:80
```
**Watch for:** Do they use the service DNS name or try the ClusterIP directly? Do they know how to handle images without curl (use wget or /dev/tcp)?

---

### Service & Networking

**16. List endpoints for route-engine-svc**
```bash
kubectl get endpoints route-engine-svc -n call-routing
```
**Watch for:** Do they know endpoints are a queryable resource? This is essential for service debugging.

**17. What ClusterIP is assigned to route-engine-svc?**
```bash
kubectl get svc route-engine-svc -n call-routing
# or precise:
kubectl get svc route-engine-svc -n call-routing -o jsonpath='{.spec.clusterIP}'
```

### Operational Tasks Scoring

| Rating | Tasks completed | Signal |
|--------|----------------|--------|
| **Fluent** | 13-17 in under 5 min | Muscle memory. Lives in K8s daily. |
| **Comfortable** | 8-12, some hesitation | Knows the commands, may need to check flags. |
| **Basic** | 4-7, slow | Can figure it out but doesn't have it memorized. |
| **Unfamiliar** | 0-3 | Not comfortable operating K8s day-to-day. |

---

# Step 2: Break/Fix Scenarios — Answer Key

---

# Beginner Scenarios

---

## 1. provisioning — Wrong Secret Name

**Symptom:** Pod `account-provisioner` in `CreateContainerConfigError`.

**Root cause:** Deployment references `secretRef: db-credentials` but the Secret in the namespace is named `database-creds`. The secret exists — it's just the wrong name.

**Diagnostic commands:**
```bash
kubectl get pods -n provisioning                      # CreateContainerConfigError
kubectl describe pod <pod> -n provisioning            # "secret db-credentials not found"
kubectl get secrets -n provisioning                   # Shows "database-creds" — close but wrong name!
```

**Fix (either works):**
```bash
# Option A: Edit the deployment to reference the existing secret name
kubectl edit deployment account-provisioner -n provisioning
# Change secretRef name from "db-credentials" to "database-creds"

# Option B: Patch it
kubectl patch deployment account-provisioner -n provisioning --type=json \
    -p '[{"op":"replace","path":"/spec/template/spec/containers/0/envFrom/0/secretRef/name","value":"database-creds"}]'
```

**What to watch for:** Does the candidate notice the secret EXISTS but has a different name? A weak candidate sees "secret not found" and tries to create one from scratch. A strong candidate runs `kubectl get secrets -n provisioning` and spots the mismatch immediately. No YAML writing required — just an edit.

**Expected time:** 1-2 min for experienced, 3-5 min for junior.

---

## 2. call-analytics — OOMKilled

**Symptom:** Pod `metrics-aggregator` in `CrashLoopBackOff`. Last state: `OOMKilled`.

**Root cause:** Memory limit is `1Mi` — clearly a typo (should be something like `128Mi` or `1Gi`). No container can run at 1Mi. Looks like someone fat-fingered `1Mi` instead of `1Gi` in the manifest.

**Diagnostic commands:**
```bash
kubectl get pods -n call-analytics                    # CrashLoopBackOff
kubectl describe pod <pod> -n call-analytics          # Last State: OOMKilled, Exit Code: 137
kubectl logs <pod> -n call-analytics --previous       # May show nothing (killed instantly)
```

**Fix:**
```bash
kubectl set resources deployment/metrics-aggregator \
    --limits=cpu=200m,memory=128Mi \
    --requests=cpu=50m,memory=64Mi \
    -n call-analytics
```
Or `kubectl edit deployment metrics-aggregator -n call-analytics` and fix the memory limit.

**What to watch for:** Does the candidate recognize OOMKilled immediately? Do they spot the `1Mi` limit and know that's impossibly low? A strong candidate sets reasonable values (128Mi-256Mi) rather than just bumping to 1Gi. Exit code 137 = SIGKILL (OOM).

**Expected time:** 1-2 min for experienced, 3-5 min for junior.

---

## 3. cdr-storage — Wrong PVC ClaimName

**Symptom:** Pod `cdr-writer` stuck in `Pending`.

**Root cause:** Deployment volume references `claimName: cdr-data-old` but the actual PVC in the namespace is named `cdr-data`. The PVC exists and is Bound — the deployment just points to the wrong name.

**Diagnostic commands:**
```bash
kubectl get pods -n cdr-storage                       # Pending
kubectl describe pod <pod> -n cdr-storage             # "persistentvolumeclaim cdr-data-old not found"
kubectl get pvc -n cdr-storage                        # Shows "cdr-data" — exists and Bound!
```

**Fix:**
```bash
kubectl edit deployment cdr-writer -n cdr-storage
# Change claimName from "cdr-data-old" to "cdr-data"
```

**What to watch for:** Does the candidate check what PVCs actually exist in the namespace? The describe output says "cdr-data-old not found" — a strong candidate immediately runs `kubectl get pvc` and spots the correct name. Simple edit, no YAML writing needed.

**Expected time:** 1-2 min for experienced, 3-5 min for junior.

---

# Intermediate Scenarios

---

## 4. admin-portal — Service Selector Mismatch

**Symptom:** Pods `portal-ui` are `Running`, but Service has no endpoints. Traffic doesn't reach the pods.

**Root cause:** Service selector is `app: portal-ui-v2` but pods have label `app: portal-ui`.

**Diagnostic commands:**
```bash
kubectl get pods -n admin-portal --show-labels        # Labels: app=portal-ui
kubectl get svc -n admin-portal                       # Service exists
kubectl get endpoints portal-ui-svc -n admin-portal   # <none> — key signal!
kubectl describe svc portal-ui-svc -n admin-portal    # Selector: app=portal-ui-v2
```

**Fix:**
```bash
kubectl patch svc portal-ui-svc -n admin-portal \
    -p '{"spec":{"selector":{"app":"portal-ui"}}}'
```

**What to watch for:** This is the **highest-signal scenario** in the lab. Strong candidates go straight to `kubectl get endpoints` — that's the instinct test. Weak candidates stare at Running pods and don't know where to look. The diagnostic path (endpoints → selector → labels) reveals how they think.

**Expected time:** 1-3 min for experienced, 5+ min for junior (many get stuck here).

---

## 5. call-routing — Wrong targetPort

**Symptom:** Pods `route-engine` Running, Service has endpoints, but `curl` to ClusterIP gets connection refused.

**Root cause:** Service `targetPort` is `8080` but container listens on `80`.

**Diagnostic commands:**
```bash
kubectl get pods -n call-routing                      # Running
kubectl get svc -n call-routing                       # Service exists
kubectl get endpoints route-engine-svc -n call-routing  # Endpoints populated (unlike admin-portal!)
kubectl describe svc route-engine-svc -n call-routing # TargetPort: 8080
kubectl describe pod <pod> -n call-routing            # containerPort: 80
# Test from inside the cluster:
kubectl run curl-test --rm -i --restart=Never --image=busybox -n call-routing \
    -- wget -qO- route-engine-svc:80
```

**Fix:**
```bash
kubectl patch svc route-engine-svc -n call-routing \
    -p '{"spec":{"ports":[{"port":80,"targetPort":80,"protocol":"TCP"}]}}'
```

**What to watch for:** Subtler than admin-portal — endpoints exist (selector is correct), so the problem is deeper. Candidate must understand `port` (what clients connect to) vs `targetPort` (what the container listens on). A strong candidate tests connectivity with `kubectl exec` or a debug pod to isolate. Pairs well with admin-portal: if they solved that via endpoints, do they apply the same pattern here and notice endpoints DO exist?

**Expected time:** 2-4 min for experienced, many juniors won't get this.

---

## 6. number-porting — Namespace Quota Exceeded

**Symptom:** Only 2 of 3 replicas running for `port-processor`. No pod-level errors visible.

**Root cause:** ResourceQuota limits namespace to 2 pods, but deployment wants 3 replicas.

**Diagnostic commands:**
```bash
kubectl get pods -n number-porting                    # Only 2 pods running
kubectl get deployment -n number-porting              # Shows 2/3 ready
kubectl describe rs <replicaset> -n number-porting    # "forbidden: exceeded quota"
kubectl get resourcequota -n number-porting           # Shows pods: 2/2
kubectl get events -n number-porting                  # quota exceeded event
```

**Fix:**
```bash
# Option A: Increase the quota
kubectl patch resourcequota pod-limit -n number-porting \
    -p '{"spec":{"hard":{"pods":"5"}}}'

# Option B: Reduce replicas to fit within quota
kubectl scale deployment port-processor --replicas=2 -n number-porting
```

**What to watch for:** This is intentionally sneaky — the error is on the **ReplicaSet**, not the Pod. Candidates who only check `kubectl describe pod` will miss it entirely. The key breakthrough is checking `kubectl get events -n number-porting` or `kubectl describe rs`. A strong candidate also asks "should I increase the quota or reduce replicas?" — showing awareness that quotas exist for a reason.

**Expected time:** 3-5 min for experienced (many need a hint), most juniors won't find it.

---

## 7. media-processing — Node Affinity (No Matching Node)

**Symptom:** Pod `transcoder` stuck in `Pending`.

**Root cause:** Deployment requires `disktype=ssd` node label, but no nodes in the cluster have this label.

**Diagnostic commands:**
```bash
kubectl get pods -n media-processing                  # Pending
kubectl describe pod <pod> -n media-processing        # "0/2 nodes are available... node affinity"
kubectl get nodes --show-labels                       # No node has disktype=ssd
```

**Fix:**
```bash
# Option A: Label a node to satisfy the affinity
kubectl get nodes                                     # Find the worker node name
kubectl label node <node-name> disktype=ssd

# Option B: Remove the affinity requirement
kubectl edit deployment transcoder -n media-processing
# Delete the affinity block
```

**What to watch for:** A strong candidate asks "should I label the node or remove the affinity?" — for media transcoding, the affinity is likely intentional (needs fast disk I/O for real-time processing) and the production fix would be to label the correct node, not weaken the constraint. Tests understanding of K8s scheduling primitives (taints, tolerations, node affinity).

**Expected time:** 2-3 min for experienced, 5+ min for junior.

---

# Advanced Scenario

---

## 8. service-mesh — DNS Resolution Broken

**Symptom:** Pod `consul-agent` is `Running` but logs show repeated "DNS lookup failed" messages in a loop. Container is `busybox` running a startup script that tries to resolve cluster DNS before starting the service.

**Root cause:** Pod has `dnsPolicy: "None"` with no `dnsConfig` block, so it has no DNS resolver configured. The container's `/etc/resolv.conf` is empty.

**Diagnostic commands:**
```bash
kubectl get pods -n service-mesh                      # Running (not crashing!)
kubectl logs <pod> -n service-mesh                    # "DNS lookup failed, retrying in 5s..."
kubectl get pod <pod> -n service-mesh -o yaml | grep -A5 dnsPolicy  # dnsPolicy: None
kubectl exec <pod> -n service-mesh -- cat /etc/resolv.conf  # Empty or no nameservers
```

**Fix:**
```bash
kubectl edit deployment consul-agent -n service-mesh
# Option A (simplest): Change dnsPolicy from "None" to "ClusterFirst"
# Option B (explicit): Keep "None" and add dnsConfig:
#   dnsConfig:
#     nameservers:
#       - <CoreDNS ClusterIP>
#     searches:
#       - svc.cluster.local
#       - cluster.local

# To find CoreDNS ClusterIP:
kubectl get svc -n kube-system kube-dns              # Usually 10.96.0.10
```

**What to watch for:** This is the hardest scenario — pod doesn't crash, it's broken internally. Candidate must think to check logs, then exec into the pod to inspect. Understanding `dnsPolicy` (`ClusterFirst` is the default, `None` disables all cluster DNS) and CoreDNS is the real test. A strong candidate knows to check `kubectl get svc -n kube-system` to find the CoreDNS ClusterIP. Most juniors won't get here.

**Expected time:** 3-5 min for experienced, most juniors won't solve it.

---

# Scoring Guide

| Rating | Scenarios Solved | What you see |
|--------|-----------------|--------------|
| **Strong** | 6-8 (including intermediates) | Methodical: describe → events → logs. Explains reasoning. Mentions production considerations. |
| **Solid** | 4-6 (beginners + some intermediate) | Solid diagnostic flow. Gets stuck on subtler issues but recovers. |
| **Developing** | 2-4 (mostly beginners) | Knows basic kubectl but lacks systematic approach. May need prompting. |
| **Getting started** | 0-1 | Cannot navigate kubectl or interpret pod status. |

## What to observe beyond "did they fix it"

| Signal | Strong | Weak |
|--------|--------|------|
| **First move** | `kubectl get pods -A` or `kubectl get events -A` | Opens one namespace randomly |
| **Diagnosis pattern** | describe → events → logs (systematic) | Guessing, random edits, repeating same command |
| **AI usage** | Pastes specific `describe` output, validates AI answer before applying | Asks vague "how to fix kubernetes" with no context, blindly applies |
| **When stuck** | Tries a different angle, checks related resources (RS, events, endpoints) | Stares, repeats same command, gives up |
| **Vocabulary** | Correct terms: PVC, selector, targetPort, affinity, OOMKilled | Vague: "the thing isn't working" |
| **Production thinking** | "I'd check the runbook" / "I'd rollback first" / "Quotas are there for a reason" | No mention of impact, process, or why things are configured a certain way |

## Suggested session flow

```
00:00-02:00   Brief the participant. "We'll start with some quick operational
              tasks, then move to troubleshooting. Think out loud.
              You can use any tools including AI."
02:00-07:00   Step 1: Operational tasks. Quick-fire, tests muscle memory.
              The participant reads from the lab, or you read them out.
07:00-18:00   Step 2: Break/fix scenarios. Observe and take notes silently.
              Offer a hint at ~12 min if stuck on one scenario.
18:00-20:00   Debrief: "What would you check next?"
              "What would you do differently in production?"
              "Why do you think that quota/affinity rule was there?"
```
