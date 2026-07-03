# Step 2 — Fix it and verify

The cert must list every name clients use to reach the Service — all three DNS forms. Put them back, let cert-manager reissue, then make nginx reload the new cert.

## Restore the dnsNames

```bash
kubectl patch certificate config-api-tls -n media --type=merge -p \
  '{"spec":{"dnsNames":["config-api.media.svc.cluster.local","config-api.media.svc","config-api"]}}'
```{{exec}}

cert-manager reissues into the same Secret with the corrected SANs. Wait for it, then confirm the cert now carries the right names:

```bash
kubectl wait --for=condition=Ready certificate/config-api-tls -n media --timeout=90s
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -ext subjectAltName
```{{exec}}

The SAN list now includes `config-api.media.svc.cluster.local`.

## Reload nginx so it serves the new cert

nginx loaded the *old* cert at startup and won't notice the Secret changed. Roll the Deployment so a fresh Pod loads the reissued cert:

```bash
kubectl rollout restart deployment/config-api -n media
kubectl rollout status deployment/config-api -n media --timeout=90s
```{{exec}}

(In production a sidecar "reloader" that watches the Secret and signals nginx avoids the restart — but the reissue-then-reload sequence is the same.)

## Verify the handshake

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

`config-api: mTLS OK`. The name the client dialed now appears in the cert's SANs, so hostname verification passes. The cert was always issued and trusted; it just claimed the wrong identity. See `finish.md`, and check `ANSWER-KEY.md`.
