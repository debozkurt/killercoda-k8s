# Step 2 — Fix it and verify

Give the client the right trust anchor: point its `trust` volume at `internal-ca-bundle` (the internal CA's public cert), the CA that actually signed the server.

## Repoint the trust volume

A strategic-merge patch updates the `trust` volume by name and leaves the client's identity volume alone:

```bash
kubectl patch deployment config-client -n app-services -p \
  '{"spec":{"template":{"spec":{"volumes":[{"name":"trust","secret":{"secretName":"internal-ca-bundle"}}]}}}}'
```{{exec}}

The Deployment rolls a new Pod mounting the correct bundle. Wait for it:

```bash
kubectl rollout status deployment/config-client -n app-services --timeout=90s
```{{exec}}

## Confirm the client now trusts the right CA

```bash
kubectl exec -n app-services deploy/config-client -- \
  openssl x509 -in /etc/tls/trust/ca.crt -noout -subject
```{{exec}}

`subject=CN=polyphone-internal-ca` — the client now holds the CA that signed the server.

## Verify the handshake

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

`config-api: mTLS OK`. The server's cert never changed — it was valid the whole time. What changed is that the client now trusts the CA that signed it. That's the fix for a trust error: distribute the *right* CA, never disable verification. See `finish.md`, and check `ANSWER-KEY.md`.
