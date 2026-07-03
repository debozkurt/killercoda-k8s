# Step 2 — Fix it and verify

The `Certificate` points at `polyphone-ca-typo`; the real internal-CA issuer is `polyphone-ca`. Repoint it and cert-manager will sign it.

## Correct the issuerRef

```bash
kubectl patch certificate config-api-tls -n media --type=merge \
  -p '{"spec":{"issuerRef":{"name":"polyphone-ca"}}}'
```{{exec}}

cert-manager sees the change, creates a fresh `CertificateRequest`, the CA issuer signs it, and the Secret gets written. Watch it go Ready:

```bash
kubectl wait --for=condition=Ready certificate/config-api-tls -n media --timeout=90s
kubectl get secret config-api-tls -n media
```{{exec}}

`READY=True`, and the `kubernetes.io/tls` Secret now exists.

## The Pod recovers

Once the Secret exists, the kubelet's next mount retry lets the stuck Pod start — give it a nudge so you don't wait for the backoff:

```bash
kubectl rollout restart deployment/config-api -n media
kubectl rollout status deployment/config-api -n media --timeout=90s
```{{exec}}

## Verify end to end

```bash
kubectl get certificate config-api-tls -n media
kubectl get pods -n media -l app=config-api
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

`Certificate` Ready, Pod `Running 1/1`, and the mTLS call returns `config-api: mTLS OK`. The Pod was never broken — it was waiting on a Secret that couldn't exist until the `Certificate` had a real issuer. See `finish.md`, and check `ANSWER-KEY.md`.
