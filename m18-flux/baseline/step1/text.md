# Step 1 — Flux and its source

Flux runs as controllers in the `flux-system` namespace. The **source-controller** fetches content from git. The **kustomize-controller** and the **helm-controller** apply it.

## Check the installation

```bash
flux check
```{{exec}}

The controller and CRD lines are green, and the command still ends with `check failed`. Two prerequisite lines fail:

- `Kubernetes version v1.30... does not match >=1.33.0-0`. This Flux release supports only newer Kubernetes minor versions than the lab cluster runs. The controllers still run here. In production, this line is a cluster upgrade to plan.
- `new CLI version is available`. The lab pins its Flux version, so this line is expected.

```bash
kubectl get deploy -n flux-system
```{{exec}}

The controllers are ordinary Deployments, next to the `gitea` git server.

## Read the source

A `GitRepository` is a **source**: it clones a git ref on an interval and stores the tree as an **artifact**.

```bash
flux get sources git
```{{exec}}

`polyphone-config` is `READY True`. The `REVISION` column reads `main@sha1:` and the first 8 characters of a commit hash. That revision is the exact commit Flux fetched.

```bash
kubectl describe gitrepository polyphone-config -n flux-system
```{{exec}}

Under `Spec`, read `Interval`, `Ref` and `URL`. Under `Status`, the `Artifact` block holds the same revision.

## Compare with git

```bash
cd /root/polyphone-config
git log --oneline
ls apps charts
```{{exec}}

One commit. Its short hash matches the start of the revision. The repo has an `apps/` directory of plain manifests and two charts.

## See the whole pipeline

```bash
flux get all
```{{exec}}

The source, the `apps` Kustomization, two HelmReleases and two HelmCharts, each with `READY` and a revision. This is the first command during an incident.
