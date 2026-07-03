# Step 2 — Fix it and verify

The server requires mTLS and that's the intent — STRICT is the security posture you want to keep. So fix the *client* side: tell callers to send mTLS. Don't downgrade the server to PERMISSIVE to make plaintext work; that throws away the encryption everyone else relies on.

## Align the client to mTLS

Set the DestinationRule's `tls.mode` to `ISTIO_MUTUAL`:

```bash
kubectl patch destinationrule session-broker -n media --type=json \
  -p '[{"op":"replace","path":"/spec/trafficPolicy/tls/mode","value":"ISTIO_MUTUAL"}]'
```{{exec}}

(Or `kubectl edit destinationrule session-broker -n media` and change `mode: DISABLE` to `mode: ISTIO_MUTUAL`. Removing the `tls` block entirely also works — automatic mTLS then negotiates it.) Now both halves agree: server requires mTLS, client sends mTLS.

## Verify the calls succeed — and STRICT is intact

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
kubectl get peerauthentication default -n media -o jsonpath='{.spec.mtls.mode}{"\n"}'
```{{exec}}

`HTTP 200`, and the PeerAuthentication is still `STRICT`. You fixed the mismatch by bringing the client up to mTLS, not by weakening the server — the traffic is encrypted and authenticated end to end. For self-grading and the full path, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
