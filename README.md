# Kubernetes Scenarios for SREs

Hands-on, scenario-based Kubernetes training that runs in the browser via [Killercoda](https://killercoda.com). Three flavors of content live here:

- **Curriculum modules** ([`m00-foundations/`](m00-foundations/) through [`m26-operate-platform/`](m26-operate-platform/)) — a structured, multi-module path from K8s foundations through GitOps, policy, real-time workloads, and a capstone. Each module pairs a known-good cluster with broken-cluster siblings, a companion lesson doc, and a self-grading answer key. Built around a fictional real-time communications platform called **Polyphone** so every lesson reinforces the same vocabulary. See [`CURRICULUM.md`](CURRICULUM.md) for the master plan.
- **Standalone scenarios** ([`operational-cluster/`](operational-cluster/), [`sre-lab/`](sre-lab/)) — independent labs. `operational-cluster` is a healthy reference cluster for `kubectl` practice; `sre-lab` is a timed, interview-style practice lab with 8 break/fix scenarios ([run it on Killercoda](https://killercoda.com/debozkurt/scenario/sre-lab)); solutions are in [`sre-lab/answer-key.md`](sre-lab/answer-key.md).

## Quick start

Each scenario directory is a standalone Killercoda scenario. To run one in the browser:

1. Fork this repo (or push it to your own public Git host).
2. Visit `https://killercoda.com/<your-user>/scenario/<scenario-path>` — for example: `https://killercoda.com/<your-user>/scenario/m00-foundations/baseline`
3. Wait for the background script to provision the cluster (60–120 seconds for the full Polyphone fleet).
4. Follow the sidebar instructions.

The practice lab is hosted, so you can skip the fork: [run sre-lab on Killercoda](https://killercoda.com/debozkurt/scenario/sre-lab).

To run a lab with a group, use the module's `ANSWER-KEY.md` as the facilitator script.

## Learning path

26 modules, 108 Killercoda scenarios: 25 baselines, 81 break/fix labs, and 2 standalone labs. Every break/fix lab ends with a verify step that checks cluster state.

| Tier | Modules | Focus |
|---|---|---|
| 1. Foundations | M00–M08, M01b | kubectl, workloads, jobs, images, configuration, Services and DNS, storage, scheduling, CRDs and operators |
| 2. Operational depth | M09–M15 | resilience and autoscaling, RBAC, secrets, PKI and TLS, observability, NetworkPolicy and Ingress, service mesh |
| 3. Platform engineering | M16–M22, M24 | Kustomize, Helm, Flux, multi-cluster, Kyverno and OPA, admission control, host networking, stateful coordination |
| 4. Capstone | M26 | operating the platform: multi-fault triage |

Each lab module (M00–M24) has a `LESSON.md`, an `ANSWER-KEY.md`, a slide deck, a `baseline/` scenario, and `breakfix-NN-*/` scenarios. M26 is a lesson. The full plan is in [`CURRICULUM.md`](CURRICULUM.md).

## Repository layout

```
.
├── README.md
├── CURRICULUM.md                    master plan: persona, fleet, module map
├── _baseline/                       canonical 17-workload Polyphone fleet (shared reference)
├── operational-cluster/             standalone: healthy reference cluster
├── sre-lab/                         standalone: timed 8-scenario practice lab
│   └── answer-key.md                solutions and facilitator notes
└── mNN-<topic>/                     one directory per curriculum module
    ├── LESSON.md                    companion doc
    ├── ANSWER-KEY.md                self-grading reference
    ├── baseline/                    killercoda scenario: known-good tour
    └── breakfix-NN-<name>/          killercoda scenario: one broken thing
```

## Where to start

- **New to Kubernetes?** Begin with [`m00-foundations/`](m00-foundations/). Read `LESSON.md`, then run `baseline/` on Killercoda, then attempt `breakfix-01-context-blindness/` before checking yourself against `ANSWER-KEY.md`.
- **Comfortable with Kubernetes, want practice?** [`operational-cluster/`](operational-cluster/) gives you a fully populated healthy cluster to explore at your own pace.
- **Preparing for an SRE interview?** [`sre-lab/`](sre-lab/) is a timed 8-scenario practice lab ([run it on Killercoda](https://killercoda.com/debozkurt/scenario/sre-lab)). [`sre-lab/answer-key.md`](sre-lab/answer-key.md) documents the expected diagnostic paths.

## Disclaimer

Polyphone is a fictional company invented for this curriculum. The platform shape — workload archetypes, namespace organization, GitOps patterns — is inspired by industry-standard practice across the real-time communications and platform-engineering space. Nothing here describes any specific real company's internal systems.

## Contributing

Each module follows a canonical lesson trio: Killercoda scenario(s), `LESSON.md`, `ANSWER-KEY.md`. The format is intentionally consistent so learners always know where to find what. New modules should match the existing M00 layout. Issues and PRs welcome.

## License

Code, scripts, and manifests are under the [MIT License](LICENSE). Lessons, answer keys, scenario text, and slide decks are under [CC BY 4.0](LICENSE-docs).
