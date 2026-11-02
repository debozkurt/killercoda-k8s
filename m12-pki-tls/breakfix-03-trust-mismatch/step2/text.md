# Step 2 — Fix it and verify

Point the client's `trust` volume at `internal-ca-bundle`, the public cert of the CA that signed the server.

## Repoint the trust volume

A strategic-merge patch updates the `trust` volume by name and leaves the identity volume alone:

```bash
kubectl patch deployment config-client -n app-services -p \
  '{"spec":{"template":{"spec":{"volumes":[{"name":"trust","secret":{"secretName":"internal-ca-bundle"}}]}}}}'
kubectl rollout status deployment/config-client -n app-services --timeout=90s
```{{exec}}

The Deployment rolls a new Pod that mounts the correct bundle.

## Verify the handshake

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

The call returns `config-api: mTLS OK`. The server cert never changed. The client now holds the CA that signed it. Distribute the right CA to fix a trust error, and never disable verification.

Check your path against the [ANSWER-KEY](https://github.com/debozkurt/killercoda-k8s/blob/main/m12-pki-tls/ANSWER-KEY.md).
