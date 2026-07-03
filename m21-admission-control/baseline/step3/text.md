# Step 3 — failurePolicy and scope: the blast radius

A webhook is code in the synchronous path of every write it matches, so two fields decide how much damage it can do: `failurePolicy` (what happens when the backend is unreachable) and its scope (`rules` + `namespaceSelector` — what it matches at all). Read both, then see the scope hold.

## What happens when the backend is down

```bash
kubectl get validatingwebhookconfiguration admission-guard \
  -o jsonpath='{.webhooks[0].failurePolicy}{"\n"}'
```{{exec}}

`Fail` — fail *closed*. If `admission-guard` goes unready, the API server treats every call it can't complete as a denial, so Pod creates in scope are **blocked** until the backend returns. That is the safe choice for a control you must not bypass, and the reason a down webhook can wedge deploys (break/fix 01).

## What it is allowed to touch

```bash
kubectl get validatingwebhookconfiguration admission-guard \
  -o jsonpath='{.webhooks[0].namespaceSelector}{"\n"}'
```{{exec}}

`matchLabels: {admission-guard: enabled}` — only namespaces carrying that label, which is `tenant-apps` alone. A *positive* selector fails safe: a namespace without the label is never intercepted, so a backend outage can never block the fleet or the control plane. Watch the scope hold — the same bare Pod, dry-run in two namespaces:

```bash
echo "tenant-apps (governed):"
kubectl run probe --image=nginx:1.25 -n tenant-apps --dry-run=server -o jsonpath='{.metadata.labels.env}{"\n"}'
echo "default (not governed):"
kubectl run probe --image=nginx:1.25 -n default --dry-run=server -o jsonpath='{.metadata.labels.env}{"\n"}'
```{{exec}}

In `tenant-apps` the Pod comes back with `env=tenant` — the webhook fired and mutated it. In `default` the field is empty — the webhook never saw the request, because `default` doesn't carry the label. Same object, two namespaces, one intercepted. That scoping is the whole difference between a webhook that governs a blast radius you chose and one that reaches into namespaces you didn't (break/fix 03).
