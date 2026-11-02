# Step 4 — Expiry and automatic renewal

Certificates expire. cert-manager renews them with a control loop, so no calendar reminder carries the job.

## Read the validity window

```bash
kubectl describe certificate config-api-tls -n media
```{{exec}}

In the `Status:` block, read `Not Before`, `Not After` and `Renewal Time`. Not After is when the cert dies. Renewal Time is when cert-manager reissues it. The default is two thirds of the way through the lifetime. This cert lives 90 days, so renewal starts about 30 days before expiry.

## Confirm the same window inside the cert

```bash
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -dates
```{{exec}}

The signed cert carries the same dates. The `Certificate` status only mirrors them.

## Renewal is a controller, so it can stall

```bash
kubectl get certificate -A
```{{exec}}

Every leaf renews as long as cert-manager runs and its issuer works. A stalled loop fails silently until Not After. Production alerts on the cert's expiry, not on the loop. A renewed cert also needs a reader: cert-manager writes the new cert into the same Secret, the kubelet refreshes the mounted files, and nginx keeps serving the cert it loaded at startup until it reloads.
