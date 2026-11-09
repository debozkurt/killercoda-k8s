# Step 1 — Find the stalled stage

The workload is healthy, so it is not the place to start. Follow the commit through the pipeline and find where it stops.

## Confirm the symptom

```bash
kubectl get deploy dialplan -n app-services
cd /root/polyphone-config
git log --oneline
```{{exec}}

2 replicas, all ready. The newest commit asked for 3.

## Fetch: did the source get the commit?

```bash
flux get sources git
```{{exec}}

`READY True`, and the `REVISION` hash matches the restructure commit. The fetch stage works.

## Build: did the consumer apply it?

```bash
flux get kustomizations
```{{exec}}

`apps` is `READY False`, and its `REVISION` is the **seed** commit, not the restructure. The applied revision trails the source. The message names the stage:

`kustomization path not found: stat /tmp/kustomization-.../apps: no such file or directory`

kustomize-controller unpacked the new artifact into a temporary directory and looked for `./apps` inside it. The build failed, so the pass stopped before apply and before prune. The `dialplan` objects from the seed commit keep running untouched.

## Compare the path with the repo

```bash
kubectl describe kustomization apps -n flux-system
ls deploy
```{{exec}}

Under `Spec`, `Path: ./apps`. The repo now keeps the manifests in `deploy/apps`. The restructure moved the directory, and nobody updated the `Kustomization` that builds it.
