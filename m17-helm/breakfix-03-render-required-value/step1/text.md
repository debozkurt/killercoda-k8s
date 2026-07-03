# Step 1 — An install that rendered nothing

Nothing deployed. Confirm the release is genuinely absent, then make the failure show itself.

## Confirm there's no release

```bash
helm list -n app-services
```{{exec}}

No `voicemail` row. A render-stage failure aborts *before* Helm records a release, so there's nothing half-installed to clean up:

```bash
helm list -A --all --pending --failed | grep voicemail || echo "no voicemail release in any state"
```{{exec}}

```bash
kubectl get all -n app-services -l app=voicemail
```{{exec}}

No Deployment, no pods. The install never reached the cluster.

## Make the error show itself

Re-run the install the pipeline ran — the error is the diagnosis:

```bash
helm install voicemail /root/voicemail --namespace app-services --set replicaCount=2
```{{exec}}

```text
Error: execution error at (voicemail/templates/deployment.yaml:NN:MM):
       voicemail: .Values.config.sipRealm is required (the SIP realm to register under)
```

Helm renders templates before it applies anything. The `deployment.yaml` template wraps `sipRealm` in the `required` function, which aborts the render when the value is empty or missing. The message names the template and tells you exactly which value is missing — this is the chart author signalling "you must set this."

## Reproduce it offline with `helm template`

You don't need the cluster to debug a render error. `helm template` runs the same merge + render locally:

```bash
helm template voicemail /root/voicemail --set replicaCount=2
```{{exec}}

Same error, no cluster round-trip. This is how you iterate on values without touching anything — flip inputs until the render is clean.

## Confirm the chart's expectation

```bash
helm show values /root/voicemail | grep -A2 "config:"
```{{exec}}

`sipRealm: ""` — the chart ships an empty default on purpose, forcing each install to supply it. Move to step 2 to provide the value.
