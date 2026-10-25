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

## Repository layout

```
.
├── README.md
├── CURRICULUM.md                    master plan: persona, fleet, module map
├── _baseline/                       canonical 17-workload Polyphone fleet (shared reference)
├── operational-cluster/             standalone: healthy reference cluster
├── sre-lab/                         standalone: timed interview break/fix assessment
│   └── answer-key.md                interviewer/self-grading reference
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
