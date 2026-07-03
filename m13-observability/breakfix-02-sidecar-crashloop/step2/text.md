# Step 2 — Fix it and verify

The sidecar's command execs a binary the image doesn't contain. In production you'd point it at the right image or the right path; here, correct the command to one the image can actually run, so `metrics-agent` stays up.

## Correct the sidecar's command

`metrics-agent` is container index `1` in the Pod (`app` is `0`). Replace its command with a working one:

```bash
kubectl patch deployment sip-monitor -n signaling --type=json -p='[
  {"op":"replace","path":"/spec/template/spec/containers/1/args/0",
   "value":"echo \"[metrics-agent] starting; exporting sip-monitor telemetry\"\nwhile true; do echo \"[metrics-agent] exported telemetry batch\"; sleep 30; done\n"}]'
```{{exec}}

This changes the template, so the Deployment rolls a new Pod whose `metrics-agent` runs a command that exists — it starts, exports, and stays up instead of exiting 127.

## Roll and verify

```bash
kubectl rollout status deployment sip-monitor -n signaling --timeout=90s
```{{exec}}

The Deployment only becomes **Available** once its Pod is fully Ready — which needs *both* containers up:

```bash
kubectl get pods -n signaling -l app=sip-monitor
```{{exec}}

`READY 2/2`, `Running`, restarts no longer climbing. Confirm the sidecar is now logging its own activity:

```bash
kubectl logs -n signaling deploy/sip-monitor -c metrics-agent --tail=3
```{{exec}}

`[metrics-agent] exported telemetry batch` — the telemetry export is alive again, so this workload is no longer dark. The app never changed; the broken container did. See `finish.md`, and check `ANSWER-KEY.md`.
