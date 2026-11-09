# Step 2 — Fix the file and verify

The values file is the source of truth: the next install reads it again. Fix the key in the file, not only in the live release.

## Correct the key

```bash
sed -i 's/^replicas:/replicaCount:/' /root/voicemail-values.yaml
cat /root/voicemail-values.yaml
```{{exec}}

The file now sets `replicaCount: 3`. In production this change is a reviewed commit to the values file in git.

## Upgrade from the file

Without `--reuse-values`, the upgrade uses only this file plus the chart defaults. The stray key leaves the release values.

```bash
helm upgrade voicemail /root/voicemail \
  --namespace app-services \
  -f /root/voicemail-values.yaml
```{{exec}}

## Verify

```bash
helm get values voicemail -n app-services
helm get manifest voicemail -n app-services | grep 'replicas:'
kubectl get deployment voicemail -n app-services
```{{exec}}

The user-supplied values show `replicaCount: 3` and no `replicas` key. The manifest reads `replicas: 3`, and `READY` reaches 3/3 after a few seconds.

`helm upgrade --reuse-values --set replicaCount=3` also gives 3 Pods. It keeps the unused key in the release and leaves the file wrong, so the next install from the file runs 1 Pod again. [ANSWER-KEY.md](https://github.com/debozkurt/killercoda-k8s/blob/main/m17-helm/ANSWER-KEY.md) compares the two fixes.
