# Step 2 — Fix it and verify

Point the `Certificate` at the real issuer. cert-manager compares the open CertificateRequest with the spec, sees the new `issuerRef`, and creates a fresh request.

## Correct the issuerRef

```bash
kubectl patch certificate config-api-tls -n media --type=merge \
  -p '{"spec":{"issuerRef":{"name":"polyphone-ca"}}}'
kubectl wait --for=condition=Ready certificate/config-api-tls -n media --timeout=90s
kubectl get secret config-api-tls -n media
```{{exec}}

Ready is True, and the `kubernetes.io/tls` Secret exists.

## Start the Pod

The kubelet retries a failed mount on its own, after a delay. Roll the Deployment to skip the delay:

```bash
kubectl rollout restart deployment/config-api -n media
kubectl rollout status deployment/config-api -n media --timeout=90s
```{{exec}}

## Verify end to end

```bash
kubectl get pods -n media -l app=config-api
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

The Pod reads Running, 1/1, and the call returns `config-api: mTLS OK`. The Pod was never broken. It waited for a Secret that no issuer could sign.

Check your path against the [ANSWER-KEY](https://github.com/debozkurt/killercoda-k8s/blob/main/m12-pki-tls/ANSWER-KEY.md).
