# Step 2 — Supply the value and verify

## Render clean first

```bash
helm template voicemail /root/voicemail \
  --set replicaCount=2 \
  --set config.sipRealm=polyphone.example | grep -A1 'SIP_REALM'
```{{exec}}

No error, and the `SIP_REALM` variable now has a value.

## Install

```bash
helm install voicemail /root/voicemail \
  --namespace app-services \
  --set replicaCount=2 \
  --set config.sipRealm=polyphone.example
```{{exec}}

`STATUS: deployed`, `REVISION: 1`. The render succeeded, so Helm recorded the release and applied it.

## Verify

```bash
helm list -n app-services
kubectl describe deployment voicemail -n app-services | grep -A2 'Environment:'
kubectl get deployment voicemail -n app-services
```{{exec}}

The `Environment:` block reads `SIP_REALM: polyphone.example`, and `READY` reaches 2/2.

A `--set` on one command line depends on every caller remembering it. The durable fix puts the value in the values file that the deploy job applies. [ANSWER-KEY.md](https://github.com/debozkurt/killercoda-k8s/blob/main/m17-helm/ANSWER-KEY.md) compares `required` with a default.
