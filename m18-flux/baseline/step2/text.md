# Step 2 — The Kustomization

A Flux `Kustomization` is a **consumer**: it takes a source, builds a path inside it (the same Kustomize engine as `kubectl apply -k` from M16), and applies the result. Note the name collision — the Flux CRD `Kustomization` is not the `kustomization.yaml` file it builds.

## Read the Kustomization

```bash
flux get kustomizations
```{{exec}}

One Kustomization: `apps`, `READY True`, message `Applied revision: main@sha1:...`. When that SHA matches the source's revision from step 1, the cluster is in sync with git.

```bash
kubectl get kustomization apps -n flux-system -o yaml | grep -A12 '^spec:'
```{{exec}}

`path: ./apps`, `prune: true` (removals from git get garbage-collected), `targetNamespace: app-services` (where the manifests land), `wait: true` (report `Ready` only when the applied workloads are healthy).

## See what it applied

```bash
kubectl get deploy -n app-services -l app=dialplan
```{{exec}}

`dialplan`, `READY 2/2`. Flux built `./apps` and applied it — the Deployment is an ordinary object; nothing in it records that Flux is involved.

```bash
flux tree kustomization apps
```{{exec}}

The inventory of what this Kustomization manages — the `dialplan` Deployment (and its Namespace). This is the list Flux prunes against.

## Read the desired state

```bash
cat /root/polyphone-config/apps/dialplan.yaml
```{{exec}}

`replicas: 2`. That number in git is the desired state Flux enforces — which is what step 3 tests.

## Verify

```bash
kubectl get kustomization apps -n flux-system \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}{"\n"}'
kubectl get deploy dialplan -n app-services -o jsonpath='{.spec.replicas}{"\n"}'
```{{exec}}

`True` and `2` — the Kustomization reconciled and dialplan is at its declared replica count. Move on to step 3.
