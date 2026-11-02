# Step 2 — Fix it and verify

Restore `client auth` in the `Certificate` usages. cert-manager compares the spec with the current request and reissues.

## Restore the usages

```bash
kubectl patch certificate config-client-tls -n app-services --type=merge \
  -p '{"spec":{"usages":["client auth","digital signature","key encipherment"]}}'
sleep 5
kubectl get secret config-client-tls -n app-services -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -ext extendedKeyUsage
```{{exec}}

The `Certificate` can read Ready True for a moment before cert-manager notices the edit. Trust the extension instead. If it still reads Server Authentication, wait 10 seconds and run the last command again.

## Refresh the client's mounted cert

The kubelet refreshes a mounted Secret within about a minute. Roll the client to skip the wait:

```bash
kubectl rollout restart deployment/config-client -n app-services
kubectl rollout status deployment/config-client -n app-services --timeout=90s
```{{exec}}

## Verify the handshake

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

The call returns `config-api: mTLS OK, client=CN=config-client`. The server never changed. The client cert now carries the purpose the server requires.

Check your path against the [ANSWER-KEY](https://github.com/debozkurt/killercoda-k8s/blob/main/m12-pki-tls/ANSWER-KEY.md).
