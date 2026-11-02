# Step 2 — Fix it and verify

Mount the whole Secret volume as a directory. The file keeps the same path, `/etc/partner/API_TOKEN`, and the kubelet can now update it.

## Remove the subPath

```bash
kubectl patch deployment partner-connector -n media --type=json -p '[
  {"op":"replace","path":"/spec/template/spec/containers/0/volumeMounts/0/mountPath","value":"/etc/partner"},
  {"op":"remove","path":"/spec/template/spec/containers/0/volumeMounts/0/subPath"}]'
kubectl rollout status deployment/partner-connector -n media
kubectl exec deploy/partner-connector -n media -- cat /etc/partner/API_TOKEN; echo
```{{exec}}

The template change rolled the Pod, so the new container reads pt_live_rotated_51e0c7.

## Prove the next rotation lands without a restart

Rotate the token in the store again:

```bash
kubectl patch secret vault-backend -n secrets-source --type=merge -p '{"stringData":{"api-token":"pt_live_rotated_second"}}'
kubectl get pods -n media -l app=partner-connector
```{{exec}}

Note the Pod name and `RESTARTS` 0. The operator syncs within 10 seconds. The kubelet then updates the volume on a later sync, which takes about a minute or more. Read the file every 10 seconds for up to two minutes:

```bash
for i in $(seq 1 12); do kubectl exec deploy/partner-connector -n media -- cat /etc/partner/API_TOKEN; echo; sleep 10; done
kubectl get pods -n media -l app=partner-connector
```{{exec}}

The output changes to pt_live_rotated_second. The Pod name and `RESTARTS` are unchanged. The file updated in place. The application must still read the file again to use the new value.

Check your path against the [ANSWER-KEY](https://github.com/debozkurt/killercoda-k8s/blob/main/m11-secrets-at-scale/ANSWER-KEY.md).
