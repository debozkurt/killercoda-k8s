# Step 2 — Supply the value and verify

The chart requires `config.sipRealm`. Supply it and the render — and the install — succeed.

## Render clean first (optional but wise)

Confirm your values produce a valid manifest before you touch the cluster:

```bash
helm template voicemail /root/voicemail \
  --set replicaCount=2 \
  --set config.sipRealm=polyphone.example | grep -E "SIP_REALM|value:|replicas:"
```{{exec}}

No error, and `SIP_REALM` renders with your value. Good to install.

## Install for real

```bash
helm install voicemail /root/voicemail \
  --namespace app-services \
  --set replicaCount=2 \
  --set config.sipRealm=polyphone.example
```{{exec}}

`STATUS: deployed`. This time render succeeded, so Helm recorded a release (revision 1) and applied the manifests.

## Verify

```bash
helm list -n app-services
```{{exec}}

```bash
kubectl get deployment voicemail -n app-services
```{{exec}}

`voicemail` is `deployed`, the Deployment reports `2/2` ready. Confirm the value actually reached the container:

```bash
kubectl get deployment voicemail -n app-services \
  -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="SIP_REALM")].value}{"\n"}'
```{{exec}}

`polyphone.example`. The required value rendered into the pod's environment.

## The durable fix

`--set` on the command line works, but a value the chart *always* needs shouldn't depend on every caller remembering it. The durable fix is a committed values file (or a sensible chart default) so the install can't be run without it. See [ANSWER-KEY.md](../ANSWER-KEY.md) for `required` vs a default, and where this value belongs in a GitOps repo.

You're done with breakfix-03, and with M17. See `finish.md`.
