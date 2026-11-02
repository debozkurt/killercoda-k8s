# Step 2 — Fix it and verify

Fix the issuer once. cert-manager retries the pending requests when the issuer changes state.

## Name the real signing Secret

```bash
kubectl patch clusterissuer polyphone-ca --type=merge \
  -p '{"spec":{"ca":{"secretName":"polyphone-internal-ca"}}}'
sleep 5
kubectl get clusterissuers
kubectl get certificate -A
```{{exec}}

`polyphone-ca` reads Ready True, and both leaf `Certificate` objects follow. If one still reads False, run the last command again after 10 seconds.

## Start both Pods

The kubelet retries a failed mount on its own, after a delay. Roll both Deployments to skip the delay:

```bash
kubectl rollout restart deployment/config-api -n media
kubectl rollout restart deployment/config-client -n app-services
kubectl rollout status deployment/config-api -n media --timeout=90s
kubectl rollout status deployment/config-client -n app-services --timeout=90s
```{{exec}}

## Verify end to end

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

The call returns `config-api: mTLS OK`. You fixed one issuer, and two workloads recovered.

Check your path against the [ANSWER-KEY](https://github.com/debozkurt/killercoda-k8s/blob/main/m12-pki-tls/ANSWER-KEY.md).
