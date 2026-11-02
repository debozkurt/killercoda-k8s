# Step 5 — Delete the Secret

The `Certificate` holds the intent. The Secret holds derived state. Prove the split.

## Record the current cert

```bash
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -serial
kubectl describe certificate config-api-tls -n media | grep Revision
```{{exec}}

Note the serial number. Revision is 1: cert-manager has issued this `Certificate` once.

## Delete the Secret

```bash
kubectl delete secret config-api-tls -n media
sleep 5
kubectl get secret config-api-tls -n media
```{{exec}}

The Secret is back. If it reads NotFound, run the last command again. The controller noticed the missing Secret, created a new CertificateRequest, and wrote a new key pair.

## Compare

```bash
kubectl get secret config-api-tls -n media -o jsonpath='{.data.tls\.crt}' | base64 -d \
  | openssl x509 -noout -serial
kubectl describe certificate config-api-tls -n media | grep Revision
```{{exec}}

The serial differs and Revision is 2. A new key pair replaced the old one. Check that the running server still answers:

```bash
kubectl exec -n app-services deploy/config-client -- \
  curl -sS --cert /etc/tls/id/tls.crt --key /etc/tls/id/tls.key \
       --cacert /etc/tls/trust/ca.crt \
       https://config-api.media.svc.cluster.local/
```{{exec}}

The call still succeeds. nginx holds the cert it loaded at startup, and the old cert is still valid. The new cert waits in the Secret until nginx reloads.
