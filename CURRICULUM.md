# Polyphone Kubernetes Curriculum — Master Plan

The long-term curriculum, organized as four tiers. Tier 1 and Tier 2 are strictly linear and required for everyone. Tier 3 splits into three branchable tracks that can be taken in any order. Tier 4 is the capstone.

## Persona

You are an SRE at **Polyphone**, a fictional real-time communications SaaS. Polyphone operates a global fleet of Kubernetes clusters across regions (`us-east-1`, `us-west-2`, `eu-central-1`, `ap-southeast-1`) and tiers (`dev`, `lab`, `stage`, `prod`). The platform delivers voice, video, and messaging via a stack of media servers, SIP signaling components, telephony application logic, edge gateways, and the usual control/data/admin planes.

## The Polyphone fleet (17 workloads, 10 namespaces)

| Namespace        | Workload              | Role                                            |
|------------------|-----------------------|-------------------------------------------------|
| `media`          | `media-engine`        | RTP media processing (StatefulSet)              |
| `media`          | `session-broker`      | Allocates media resources                       |
| `media`          | `transcoder`          | Codec conversion (CPU-affinity)                 |
| `signaling`      | `sip-router`          | SIP request routing                             |
| `signaling`      | `sip-proxy`           | Front-edge SIP proxy                            |
| `signaling`      | `reg-proxy`           | Endpoint registration (StatefulSet)             |
| `app-services`   | `sip-app`             | SIP application server (call logic)             |
| `app-services`   | `presence`            | Presence/availability (StatefulSet)             |
| `app-services`   | `directory`           | Address book / contacts                         |
| `edge`           | `sbc-edge`            | Session Border Controller (DaemonSet)           |
| `edge`           | `pstn-gateway`        | PSTN trunk gateway (StatefulSet)                |
| `provisioning`   | `account-provisioner` | Tenant provisioning                             |
| `admin-portal`   | `portal-ui`           | Admin web UI                                    |
| `call-routing`   | `route-engine`        | Call routing decisions                          |
| `cdr-storage`    | `cdr-writer`          | Call Detail Records (PVC)                       |
| `analytics`      | `metrics-aggregator`  | Telemetry aggregation                           |
| `number-porting` | `port-processor`      | LNP workflows (ResourceQuota)                   |

The full fleet boots in every lesson's `baseline/` scenario. Each module's break/fix scenarios mutate one or two of these workloads to create a learnable failure.

**Module-layered workloads.** A module may layer extra workloads onto the standard fleet when its topic needs an archetype the base 17 don't cover — appended via a fenced enhancement in that module's `background.sh`, not added to `_baseline/`. M01b layers three batch workloads (run-to-completion / scheduled): `schema-migrate` (Job, `provisioning`), `usage-export` (parallel Job, `analytics`), `cdr-rollup` (CronJob, `cdr-storage`). They run `busybox` rather than the fleet's long-lived `nginx`, because batch pods must exit to complete. M02 layers `media-recorder` (`media`) plus an in-cluster private `registry` (registry:2 + htpasswd at `localhost:5000`) for its baseline tour and the registry-auth scenario, demonstrating an authenticated pull of a proprietary image.

## Module map

### Tier 1 — Foundations (linear)

| ID  | Title                                     | Core concepts                                                   |
|-----|-------------------------------------------|-----------------------------------------------------------------|
| M00 | Mental Model & kubectl Fluency            | Cluster anatomy, contexts, namespaces, the resource model       |
| M01 | Workloads I — Pods, Deployments, ReplicaSets | Lifecycle, probes, controllers, declarative reconciliation     |
| M01b | Workloads: Jobs & CronJobs               | Run-to-completion + scheduled batch, `restartPolicy` OnFailure/Never, completions/parallelism, `backoffLimit`. Split from M07 so the lifecycle-only batch controllers are taught right after M01 |
| M02 | Container Images & Registries             | Image anatomy, references vs digests, pull semantics, imagePullSecrets, registry auth, mirrors, promotion, scanning, signing |
| M03 | Configuration                             | ConfigMaps, Secrets (basic), env injection, projected volumes   |
| M04 | Networking I — Services & DNS             | Service types, Endpoints, kube-proxy, CoreDNS                   |
| M05 | Storage                                   | PV/PVC, StorageClass, CSI, RWO vs RWX, dynamic provisioning     |
| M06 | Scheduling                                | Requests/limits, QoS, affinity, taints, topology spread         |
| M07 | Workloads II — StatefulSets & DaemonSets | Stable identity, ordered rollout, per-Pod storage, node-local agents (batch moved to M01b)    |
| M08 | CRDs & Operators                          | The controller pattern, CRDs vs built-ins, owner references, reading operator-managed state, debugging stuck reconciliation |

### Tier 2 — Operational Depth (linear)

| ID  | Title                                     | Core concepts                                                   |
|-----|-------------------------------------------|-----------------------------------------------------------------|
| M09 | Resilience & Autoscaling                  | PDBs, HPA + Cluster Autoscaler + VPA + KEDA, rolling updates, rollbacks, graceful shutdown |
| M10 | Security I — RBAC & Pod Security          | RBAC, ServiceAccounts, SecurityContext, PodSecurity admission   |
| M11 | Security II — Secrets at Scale            | External Secrets Operator, Vault, sealed-secrets, sops; GitOps-safe secret handling |
| M12 | PKI & TLS                                 | cert-manager, internal CA, mTLS between workloads, ACME for public certs |
| M13 | Observability                             | Events, logs (sidecar + centralized stack), metrics (Prometheus operator), traces (OpenTelemetry) |
| M14 | Networking II — Policy & Ingress          | NetworkPolicies, Ingress controllers, multi-tenant patterns     |
| M15 | Service Mesh                              | Sidecar injection, traffic management (retries/timeouts/circuit breakers), debugging envoy config, mesh-managed mTLS |

### Tier 3 — Platform Engineering (branchable)

**Track A — GitOps**
| ID  | Title                  | Core concepts                                            |
|-----|------------------------|----------------------------------------------------------|
| M16 | Kustomize Bases & Overlays | Composition, patches, components, generators        |
| M17 | Helm Fundamentals      | Charts, values, templating, when to choose Helm vs Kustomize |
| M18 | Flux                   | GitRepository, Kustomization, HelmRelease, dependencies, drift |
| M19 | Multi-cluster Fleet    | Cluster vars, rendering trace, promotion (lab → stage → prod), per-region overlays |

**Track B — Policy & Compliance**
| ID  | Title                  | Core concepts                                            |
|-----|------------------------|----------------------------------------------------------|
| M20 | Kyverno / OPA Gatekeeper | Policy-as-code, validation, mutation, signed-image admission |
| M21 | Admission Control      | Validating vs mutating webhooks, admission ordering     |

**Track C — Real-Time / Latency-Sensitive Workloads**
| ID  | Title                  | Core concepts                                            |
|-----|------------------------|----------------------------------------------------------|
| M22 | Host Networking & Multi-NIC | hostNetwork, hostPort, Multus, CNI plumbing for RTP, UDP load balancing, ExternalTrafficPolicy |
| M23 | CPU & Memory Tuning    | CPU Manager, NUMA, topology manager, hugepages, RT kernel basics |
| M24 | Stateful Coordination  | Leader election, headless Services, StatefulSet identity, persistent caches |

### Tier 4 — Capstone

| ID  | Title                                     | Core concepts                                                   |
|-----|-------------------------------------------|-----------------------------------------------------------------|
| M25 | Failure & Recovery                        | Cluster upgrades + version skew, control plane, etcd, CSI failure, Velero/backup, GitOps rollback |
| M26 | Operate the Platform                      | Multi-broken-cluster triage; integrates Tier 1–3                |

## Lesson design philosophy

**Concept first, then practice, then self-grade.** The companion `LESSON.md` introduces the concept and mental model. The Killercoda `baseline/` scenario lets you see it working. The `breakfix-NN/` scenarios force you to debug it. The `ANSWER-KEY.md` shows the canonical diagnostic path so you can grade your own approach after — it's a learner-facing reference, not a hidden instructor key.

**One concept per break/fix scenario.** A scenario tests one diagnostic skill. Combining multiple bugs into one scenario teaches frustration, not Kubernetes.

**Depth scales with break/fix scenarios, not with LESSON.md length.** Each module identifies its load-bearing concepts — the ones an SRE needs cold at 3am — typically 2–3, occasionally 4 — and gives each of them full prose + an optional `<details>` deep dive + at least one break/fix scenario. Secondary concepts get covered in Vocabulary and the walkthrough but don't get dedicated depth treatment. The concept count is a default, not a cap: a module extends to a 4th scenario when it stays bite-sized and earns its place — most cleanly when the scenarios complete one coherent set (e.g. M02's four-branch pull-failure differential). Don't pad scenarios for symmetry; don't omit them to keep things short; prefer more small bites over one overstuffed scenario. Bite-sizedness is held by the per-scenario time budget and the LESSON length cap, not by a low scenario count.

**The platform is always the same.** Every lesson uses the same Polyphone fleet. Learners build familiarity with the same namespaces, the same workloads, the same vocabulary. By M10 they know the platform as well as they know their own production system.

**Earned vocabulary.** Each module assumes everything taught in earlier modules. `LESSON.md` cross-references back ("see M03 for Service basics"). The curriculum is cumulative, not encyclopedic.

**Production thinking.** Every `ANSWER-KEY.md` ends with a "what would you do in production" prompt. Diagnosis is necessary but not sufficient; reasoning about blast radius, runbooks, and post-incident action is what separates strong SREs.

**Authoritative references.** Every concept links out to k8s.io, kustomize.io, fluxcd.io, CNCF docs, or canonical IETF/3GPP terminology where appropriate. The curriculum is a curated path through the official docs, not a replacement for them.

## Voice and length

| Artifact          | Length target           | Voice                                            |
|-------------------|-------------------------|--------------------------------------------------|
| Sidebar `text.md` | ~300–600 words per step | Imperative, conversational, code-heavy           |
| `LESSON.md`       | ~1500–3000 words        | Explanatory, mental-model focused, well-linked   |
| `ANSWER-KEY.md`   | ~150–400 words per scenario | Terse, opinionated, what-to-watch-for          |

See `_internal/style-guide.md` for the full conventions.

## Status

| Module                 | LESSON | ANSWER-KEY | baseline/ | breakfix/ | Notes |
|------------------------|--------|------------|-----------|-----------|-------|
| M00 Foundations        | ✅     | ✅         | ✅        | 3 shipped (`context-blindness`, `event-only-failure`, `namespace-blindness`) | Canonical template — match its shape going forward |
| M01 Workloads I        | ✅     | ✅         | ✅        | 3 shipped (`liveness-restart-loop`, `readiness-traffic-blackhole`, `prestop-truncation`) | Lifecycle + 3 probes + graceful shutdown; `sip-app` upgraded to gold-standard in baseline |
| M01b Workloads: Batch  | ✅     | ✅         | ✅        | 3 shipped (`cronjob-never-fires`, `job-backofflimit`, `completions-shortfall`) | Jobs & CronJobs (lifecycle-only, split from M07). Layers 3 batch workloads onto the fleet: `schema-migrate` (Job), `usage-export` (parallel Job), `cdr-rollup` (CronJob) |
| M02 Images & Registries| ✅     | ✅         | ✅        | 4 shipped (`never-pull`, `registry-unreachable`, `imagepull-auth`, `digest-mismatch`) | Pull-failure differential (ErrImageNeverPull / no-such-host / 401 / manifest-unknown). Layers `media-recorder` + an in-cluster private `registry` (registry:2 + htpasswd) for baseline + the auth scenario; the other three mutate fleet workloads in place |
| M03 Configuration      | —      | —          | —         | —         | |
| M04 Networking I       | —      | —          | —         | —         | |
| M05 Storage            | —      | —          | —         | —         | |
| M06 Scheduling         | —      | —          | —         | —         | |
| M07 Workloads II       | —      | —          | —         | —         | StatefulSets & DaemonSets only (batch → M01b) |
| M08 CRDs & Operators   | —      | —          | —         | —         | |
| M09 Resilience & Autoscaling | —| —          | —         | —         | |
| M10 Security I (RBAC)  | —      | —          | —         | —         | |
| M11 Security II (Secrets at Scale) | — | — | —     | —         | |
| M12 PKI & TLS          | —      | —          | —         | —         | |
| M13 Observability      | —      | —          | —         | —         | |
| M14 Networking II      | —      | —          | —         | —         | |
| M15 Service Mesh       | —      | —          | —         | —         | |
| M16 Kustomize          | —      | —          | —         | —         | GitOps track |
| M17 Helm               | —      | —          | —         | —         | GitOps track |
| M18 Flux               | —      | —          | —         | —         | GitOps track |
| M19 Multi-cluster      | —      | —          | —         | —         | GitOps track |
| M20 Kyverno/OPA        | —      | —          | —         | —         | Policy track |
| M21 Admission control  | —      | —          | —         | —         | Policy track |
| M22 Host networking    | —      | —          | —         | —         | Real-time track |
| M23 CPU/NUMA           | —      | —          | —         | —         | Real-time track |
| M24 Stateful coord.    | —      | —          | —         | —         | Real-time track |
| M25 Failure & recovery | —      | —          | —         | —         | Capstone |
| M26 Operate platform   | —      | —          | —         | —         | Capstone |

Update the `breakfix/` column with `N shipped (slug1, slug2, ...)` each time a scenario lands. Each module ships ≥1 break/fix scenario; additional scenarios get added as authoring proceeds and as failure modes worth teaching emerge.
