# Step 2 — Fix your context and verify

Set your context's default namespace to a Polyphone namespace. The fleet has 10 named namespaces (`app-services`, `media`, `signaling`, `admin-portal`, `analytics`, etc.) — pick whichever fits the task.

```bash
kubectl config set-context --current --namespace=app-services
```{{exec}}

Verify the new scope:

```bash
kubectl config view --minify | grep namespace:
```{{exec}}

Should show `namespace: app-services`.

```bash
kubectl get pods
```{{exec}}

You see the `app-services` workloads — visible proof the cluster was always healthy; your view was the problem. The same workloads also surface via the `plane` label (from baseline/step2):

```bash
kubectl get pods -l plane=app -A
```{{exec}}

For self-grading and the production practices that make this class of incident impossible, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m00-foundations/ANSWER-KEY.md). For the underlying concepts (contexts, kubeconfig, the resource model), see [`LESSON.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m00-foundations/LESSON.md).

You're done with breakfix-01. See `finish.md`.
