# M26 — Operating the Platform: Where You Go From Here

> You've run the same Polyphone cluster for twenty-five modules. This is the graduation module: the mindset for operating that cluster under real pressure, and an honest map of the terrain that lives beyond a training backend.

## What this module is

The earlier modules each handed you one diagnostic skill against a known-good, 17-workload Polyphone fleet. This one has **no new lab**, for two deliberate reasons. First, the operational skill it teaches — triaging several faults at once, under a clock — is something you *compose* from what you already have, not a new primitive. Second, the remaining advanced topics (node-level tuning, cluster failure and recovery) need hardware or destructive access that a shared training cluster can't safely provide. So this is a reference: the operating mindset first, then a pointer to each frontier and where to practice it for real.

## The toolkit you already have

Look back at what every module actually drilled. Each taught the same move in a different domain: **a symptom is a category, not a diagnosis — read the object that names the cause.**

- `ImagePullBackOff` is a category; the kubelet event message separates never-pull from no-such-host from `401` from digest-mismatch (M02).
- `connection refused` is a category; the EndpointSlice and the DNS answer say *where* it broke (M04).
- A `Pending` Pod is a category; the scheduler event separates insufficient-resources from an untolerated taint from pod anti-affinity (M06).
- A `Forbidden` is a four-field sentence — verb, resource, scope, identity (M10).
- `Running` ≠ `Ready` ≠ correct — the headline status lies; the readiness probe, the `.status` subresource, and the container logs carry the truth (M01, M07, M08).

That transferable habit — *don't trust the headline; find the object that carries the evidence* — is the whole job. Operating the platform is running that loop across many objects at once, when more than one thing is broken.

## Operating under pressure: the integrative triage

A real incident rarely arrives as one clean fault. A node goes `NotReady` and *also* a Deployment was mid-rollout and *also* a NetworkPolicy change landed an hour ago. The skill is sequencing:

1. **Stabilize before you diagnose.** Stop the bleeding first — cordon a bad node, `kubectl rollout undo` a wedged Deployment<sup><a href="https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment">[1]</a></sup> (M09), scale a hot path — *before* you fully understand root cause. A stable-but-degraded system buys you time; a still-collapsing one does not.
2. **Localize by blast radius, not by loudest alarm.** One namespace or the whole cluster? One workload, or a shared dependency — DNS, the CNI, an admission webhook, the API server? A `ValidatingWebhookConfiguration` with `failurePolicy: Fail` whose backend is down (M21), or a default-deny NetworkPolicy (M14), both present as "everything is broken." Recognize shared-dependency failures early, because they invert where you look.
3. **Run the differentials in parallel.** Now the per-module skills compound: is the workload `Pending` (M06), `ImagePullBackOff` (M02), `CrashLoopBackOff` (M01), sidecar-less (M15), or `Running`-but-dark (M04/M07)? Each has a one-command discriminator you already know cold.
4. **Change one thing, verify, write it down.** The discipline every `ANSWER-KEY.md` closed on: reason about blast radius before you act, confirm the fix with the *same* object that showed the fault, and leave a trail for the post-incident review.

That is M26. There is no new object to learn — there is a cluster you know cold and the composure to work it methodically when three alarms fire together. Re-run any break/fix scenario from M00–M24 with a stopwatch and no hints, and you are practicing exactly this.

## Frontier 1 — Node & resource tuning (the M23 topics)

Requests, limits, QoS classes, and OOM-kills you already met in M06. The layer beneath them — **pinning workloads to physical resources** — is where latency-sensitive media and RTP paths live: the **CPU Manager** `static` policy for exclusive cores<sup><a href="https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/">[2]</a></sup>, the **Topology Manager** for NUMA-aligned CPU and device placement<sup><a href="https://kubernetes.io/docs/tasks/administer-cluster/topology-manager/">[3]</a></sup>, **hugepages** for large-page memory<sup><a href="https://kubernetes.io/docs/tasks/manage-hugepages/scheduling-hugepages/">[4]</a></sup>, and real-time kernel tuning.

Honest note: **the training backend cannot demonstrate any of it.** Its nodes are single-vCPU, single-NUMA-node, zero-hugepage, non-real-time VMs. The CPU Manager `static` policy has no spare exclusive core to hand out; the Topology Manager has one NUMA node to align across (a no-op); reserving hugepages would eat the tiny RAM budget. These features only *do* something on real multi-core NUMA hardware. Learn the concepts here; practice them on a bare-metal or large cloud node where `kubectl describe node` shows many cores across multiple NUMA zones.

## Frontier 2 — Failure & recovery (the M25 topics)

Everything so far assumed a healthy control plane. The operator's hardest day is when the control plane *itself* is the patient: an **etcd** restore from snapshot<sup><a href="https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/">[5]</a></sup>, a **kubeadm control-plane upgrade** and the version-skew rules that constrain it<sup><a href="https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/">[6]</a></sup>, a CSI/volume failure, or a full application restore with a tool like **Velero**<sup><a href="https://velero.io/docs/">[7]</a></sup>.

These are read-then-do runbooks, not break/fix puzzles — and they are **destructive to the very cluster a shared lab runs on**, so there is no safe scripted version here. The shape to internalize:

- **etcd is the cluster's memory.** `etcdctl snapshot save` on a schedule; `etcdctl snapshot restore` rebuilds state onto a fresh data directory. Test the *restore*, not just the backup — an untested backup is a hope, not a plan.
- **Upgrade one minor version at a time, control plane before workers**, respecting the kubelet/apiserver skew policy<sup><a href="https://kubernetes.io/releases/version-skew-policy/">[8]</a></sup>; drain each node first<sup><a href="https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/">[9]</a></sup> — M09's PodDisruptionBudgets are what make that drain safe.
- **GitOps rollback is your calmest recovery.** You already built it in M18/M19: revert the commit, let Flux reconcile the fleet back to the last-good state. No `kubectl` heroics under pressure.

Practice these where breaking things is free: a local `kind` or `minikube` cluster you own, or a throwaway cloud cluster — never production, and never a shared training box.

## Frontier 3 — Operating at fleet scale

M19 rendered a whole fleet from one repo; *running* that fleet is its own discipline — SLOs and error budgets, on-call rotation and alert hygiene, capacity planning, progressive delivery across regions. That is less a Kubernetes topic than an SRE one, and it is where this curriculum hands off to the broader SRE literature.

## Where to go next

- **Certifications** map cleanly onto what you have done: **CKA** for cluster operations (the M25 frontier), **CKAD** for workloads and config (M01–M08), **CKS** for security (M10–M12, M20–M21)<sup><a href="https://www.cncf.io/training/certification/">[10]</a></sup>.
- The **Kubernetes documentation**<sup><a href="https://kubernetes.io/docs/home/">[11]</a></sup> is the source every module cited. You can now read it as reference, not tutorial.
- Your own incident retros are where the operating mindset in this module keeps compounding. The differentials are portable; the composure is earned one incident at a time.

You know the platform as well as you know your own production system. That was the point.

## References

1. Kubernetes — Rolling Back a Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment
2. Kubernetes — CPU Management Policies: https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/
3. Kubernetes — Control Topology Management (NUMA): https://kubernetes.io/docs/tasks/administer-cluster/topology-manager/
4. Kubernetes — Managing HugePages: https://kubernetes.io/docs/tasks/manage-hugepages/scheduling-hugepages/
5. Kubernetes — Operating etcd clusters (backup & restore): https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/
6. Kubernetes — Upgrading kubeadm clusters: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
7. Velero — Backup and Restore: https://velero.io/docs/
8. Kubernetes — Version Skew Policy: https://kubernetes.io/releases/version-skew-policy/
9. Kubernetes — Safely Drain a Node: https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/
10. CNCF — Kubernetes Certifications (CKA/CKAD/CKS): https://www.cncf.io/training/certification/
11. Kubernetes Documentation: https://kubernetes.io/docs/home/
