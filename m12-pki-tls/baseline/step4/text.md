# Step 4 — Expiry and automatic renewal

Certificates expire. A cert nobody renews is an outage with a timer on it. cert-manager makes renewal a control loop, not a calendar reminder.

## Read the validity window

```bash
kubectl get certificate config-api-tls -n media \
  -o jsonpath='{"notBefore: "}{.status.notBefore}{"\nnotAfter:  "}{.status.notAfter}{"\nrenewal:   "}{.status.renewalTime}{"\n"}'
```{{exec}}

`notAfter` is when the cert dies; `renewalTime` is when cert-manager will reissue it — by default at ⅔ of the cert's lifetime, well before expiry. This cert has a 90-day life (`duration: 2160h`), so `renewalTime` is ~30 days before `notAfter`.

## Confirm the same window in the cert itself

The Secret's cert carries the same dates — the object status just mirrors what's cryptographically signed:

```bash
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -dates
```{{exec}}

`notBefore` / `notAfter` match the `Certificate` status. When renewal fires, cert-manager writes a fresh cert into this same Secret — the workload picks it up on its next restart (or immediately, with a reloader watching the Secret).

## Renewal is a controller, so it can stall

```bash
kubectl get certificate -A
```{{exec}}

Every leaf here renews automatically **as long as cert-manager is healthy and the issuer still works**. If the controller is down or the CA is unreachable, renewal silently doesn't happen and you find out at `notAfter` — which is why production alerts on the cert's *expiry*, not on trusting the loop to fire. That's the healthy PKI end to end; now go break it three ways. See `finish.md`.
