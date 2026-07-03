# Step 2 — Fix it and verify

The webhook configuration is correct; its backend is down. Bring `admission-guard` back up so its Service has an endpoint again, and the API server's admission calls succeed — Pods flow.

## Restore the backend

```bash
kubectl scale deployment/admission-guard -n admission --replicas=1
kubectl rollout status deployment/admission-guard -n admission --timeout=120s
```{{exec}}

The backend was scaled to zero (the image pulls now, so give it a moment). Once its Pod is `Ready`, the Service has an endpoint and the webhook is reachable:

```bash
kubectl get pods,endpoints -n admission
```{{exec}}

## Re-admit billing-api

The ReplicaSet keeps retrying with backoff; trigger a fresh attempt so it admits immediately now that the webhook answers:

```bash
kubectl rollout restart deployment/billing-api -n tenant-apps
kubectl rollout status  deployment/billing-api -n tenant-apps --timeout=90s
kubectl get pods -n tenant-apps -l app=billing-api -L env
```{{exec}}

`billing-api` goes to `1/1`, its Pod is `Running`, and it even carries the injected `env=tenant` — the mutating webhook fired the moment the call could complete. Nothing about the configuration changed; it was never wrong. You fixed the *backend*, not the gate. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
