# Step 2 — The Polyphone fleet

Polyphone is a real-time communications platform. Its workloads are organized by **architectural plane**:

| Plane         | What lives there                                       | Namespaces                                  |
|---------------|--------------------------------------------------------|---------------------------------------------|
| **media**     | RTP media servers, transcoding, session brokering      | `media`                                     |
| **signaling** | SIP routing, proxying, endpoint registration           | `signaling`                                 |
| **app**       | Telephony application logic, presence, directory       | `app-services`                              |
| **edge**      | North-south session border controllers, PSTN gateways  | `edge`                                      |
| **control**   | Provisioning, routing, CDR, analytics, number porting  | `provisioning`, `call-routing`, `cdr-storage`, `analytics`, `number-porting` |
| **admin**     | Operator-facing portal                                 | `admin-portal`                              |

Every workload carries a `plane=...` **label** — a `key=value` tag attached to an object. **Selectors** (e.g., `-l plane=media`) filter on labels; this is how Services find their backing Pods, how Deployments pick which Pods they own, and how you grep the cluster. You'll use the `plane` label a lot in later modules (notably M14 — NetworkPolicies).

## See the whole fleet at once

```bash
kubectl get pods -A
```{{exec}}

This is the canonical "what's running anywhere on this cluster" command. Memorize it. It is the first thing you should type whenever you're triaging an unfamiliar situation.

Quick vocabulary before reading the output: a **Pod** is the smallest deployable unit — one or more containers that share a network IP and lifecycle. A **namespace** is a logical grouping inside the cluster used for organization, RBAC scoping, quotas, and DNS. Almost everything you'll touch in this curriculum is a Pod, living in a namespace.

You should see ~25 pods spread across the Polyphone namespaces, plus the standard `kube-system` and `local-path-storage` infrastructure namespaces.

## Filter by plane

```bash
kubectl get pods -A -l plane=media
```{{exec}}

```bash
kubectl get pods -A -l plane=signaling
```{{exec}}

The `plane` label cuts the fleet by architectural responsibility. In later modules you'll use this to apply policy, scale together, or scope debugging.

## Look at the different workload types

The choice of workload controller encodes an assumption about the workload. Here's the cheat sheet:

| Controller | Use when | Pod identity | Polyphone example |
|---|---|---|---|
| **Deployment** | Pods are stateless and interchangeable; any replica can serve any request. | Random suffix, anonymous, fungible. | `sip-router`, `portal-ui` |
| **StatefulSet** | Pods need a stable name + their own **PVC** (a Pod's request for persistent storage), and must start/stop in order. | `name-0`, `name-1`, … — sticky. | `media-engine`, `reg-proxy`, `presence`, `pstn-gateway` |
| **DaemonSet** | You need exactly one Pod per (matching) node — typically a host-level agent. | One per node. | `sbc-edge` (per-node edge proxy) |
| **Job** | Run-to-completion batch work; success means the Pod exited 0. | Throwaway. | (covered in M01b) |
| **CronJob** | A Job, on a schedule. | Throwaway. | (covered in M01b) |

> `ReplicaSet` is what a Deployment creates and manages internally to track desired replica count. You almost never write one yourself — you write a Deployment, and the Deployment controller manages its ReplicaSets across rolling updates.

See them in the cluster:

```bash
kubectl get deployments -A
```{{exec}}

```bash
kubectl get statefulsets -A
```{{exec}}

```bash
kubectl get daemonsets -A
```{{exec}}

Each command shows the workloads managed by that controller. The controller type tells you how the workload behaves (identity, lifecycle, storage) — useful when you land on an unfamiliar service in production.

## Verify

```bash
kubectl get ns -l '!kubernetes.io/metadata.name' 2>/dev/null
kubectl get pods -A --no-headers | wc -l
```{{exec}}

You should see 10 Polyphone namespaces and ~25 total pods.

Move on to step 3.
