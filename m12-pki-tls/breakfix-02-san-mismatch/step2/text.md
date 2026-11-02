# Step 2 — Fix it and verify

The cert must list every name a client uses: the short name, `<service>.<namespace>.svc`, and the full cluster name. Restore them, let cert-manager reissue, then make nginx reload.

## Restore the dnsNames

```bash
kubectl patch certificate config-api-tls -n media --type=merge -p \
  '{"spec":{"dnsNames":["config-api.media.svc.cluster.local","config-api.media.svc","config-api"]}}'
sleep 5
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -ext subjectAltName
```{{exec}}

The `Certificate` can read Ready True for a moment before cert-manager notices the edit. Trust the SAN list instead. If it still shows the legacy name, wait 10 seconds and run the last command again. It must list three names.

## Make nginx load the new cert

nginx loads its cert at startup and does not notice a Secret change. Roll the Deployment so a new Pod loads the reissued cert:

```bash
kubectl rollout restart deployment/config-api -n media
kubectl rollout status deployment/config-api -n media --timeout=90s
```{{exec}}

## Verify the handshake

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

The call returns `config-api: mTLS OK`. The cert was issued and trusted all along. It claimed the wrong identity.

Check your path against the [ANSWER-KEY](https://github.com/debozkurt/killercoda-k8s/blob/main/m12-pki-tls/ANSWER-KEY.md).
