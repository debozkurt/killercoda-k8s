# M13 — Observability — Answer Key

> Self-grading reference. Work each scenario first, then check your diagnostic path against the canonical one here. Instructors running the lab live can read the same sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline. Each break/fix layers a tiny addition on the fleet — a workload that emits (or fails to emit) one of the three signals. Nothing in the base fleet is broken; the mutation is one field or one command in one signal's path.

## Lesson summary

M13 is about the three signals a running cluster already gives you — **events** (what the control plane *did*), **logs** (what the process *said*), **metrics** (how much it's *using* / how it's *behaving*) — plus **traces** (concept-only here). The through-line: match the question to the signal, and remember all three are ephemeral (events expire, logs die with the Pod, `kubectl top` keeps no history), which is why a durable stack exists. The `baseline/` tour reads each healthy: surveying the event stream by `type`/`reason` with `--field-selector`, pulling logs with `--tail`/`--since`/`-c`/`--previous`, reading resource metrics with `kubectl top`, and inspecting a healthy `/metrics` exposition target with its scrape annotations. The three break/fix scenarios each break the reading of one signal:

- `breakfix-01-logs-to-stdout` — **an empty log on a healthy Pod**: the app writes logs to a file, not stdout, so the kubelet captures nothing.
- `breakfix-02-sidecar-crashloop` — **a `1/2` Pod**: a telemetry sidecar crashloops; the events name the container and `logs -c … --previous` says why.
- `breakfix-03-metrics-scrape-port` — **flat dashboards, healthy app**: the scrape port annotation points at a port nothing serves, so the target is DOWN — a pipeline-2 failure with pipeline-1 (`kubectl top`) still green.

The reflexes to carry: an empty log on a `Running` Pod means the app isn't logging to stdout; `N-1/N` means one container is down (name it, then `-c … --previous`); and a metrics gap with a healthy `kubectl top` is a scrape problem, not a sick app.

## Baseline tour reference

No broken state. Expected output per step:

- **Step 1 (Events):** `kubectl rollout restart deploy/session-broker -n media` then `kubectl get events -n media --sort-by=.lastTimestamp` shows the Normal lifecycle beats (`Scheduled`/`Pulled`/`Created`/`Started`). `--field-selector type=Warning -A` is short/empty on a healthy fleet — the point. `kubectl describe pod` aggregates events for one object (matched by `involvedObject`/UID). Teaching point: events are the control plane narrating itself, and they expire (~1h TTL).
- **Step 2 (Logs):** an ephemeral `curl` to `session-broker` produces an nginx access line; `kubectl logs deploy/session-broker --tail=3` shows it (nginx logs to stdout). `--since`/`--tail`/`-f`/`-c`/`--previous` are demonstrated; `--previous` returns "previous terminated container not found" because nothing has crashed. Teaching point: the kubelet captures stdout/stderr only, and logs die with the Pod.
- **Step 3 (Resource metrics):** `kubectl top nodes` and `kubectl top pods -A --sort-by=memory` return live CPU/memory. Read one workload's `top` against its `requests` — utilization is the ratio (the HPA's denominator, M09). Teaching point: this pipeline is CPU/memory only, point-in-time, and feeds the HPA.
- **Step 4 (Application metrics):** an ephemeral `curl` to `call-metrics.analytics/metrics` returns the exposition format (`# HELP`/`# TYPE`, a gauge/counter/histogram). The Pod's `prometheus.io/scrape|port|path` annotations show how a scraper discovers it, and `prometheus.io/port` (80) matches the container port (80) — a healthy target. Teaching point: application metrics are a separate, pull-based pipeline; the declared scrape port must match the serving port.

---

## Break/fix 01 — Logs: an app that writes to a file

**Symptom:** `session-logger` in `app-services` is `Running 1/1`, no restarts — healthy by every status check — but `kubectl logs deploy/session-logger` returns a single startup line and nothing else. The workload is obviously doing work (it was deployed to record per-session activity), yet its log is empty.

**Root cause:** The container writes its real output to a file *inside* the container, `/var/log/app/session.log`, instead of to stdout. The kubelet's logging pipeline captures **stdout/stderr only**, so `kubectl logs` sees only the one banner line the app prints to stdout at startup. The app is logging correctly *to the wrong place*; nothing is broken except the logging contract<sup><a href="https://kubernetes.io/docs/concepts/cluster-administration/logging/">[2]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
# 1. Healthy Pod — not a crash, not scheduling
kubectl get pods -n app-services -l app=session-logger            # Running 1/1, 0 restarts

# 2. The log is nearly empty — and the one line it prints is the clue
kubectl logs -n app-services deploy/session-logger
#    [session-logger] starting; writing session events to /var/log/app/session.log
#    ^ it told you where it logs: a FILE, not stdout

# 3. Confirm the output is on disk, not on stdout
kubectl exec -n app-services deploy/session-logger -- ls -l /var/log/app
kubectl exec -n app-services deploy/session-logger -- tail -5 /var/log/app/session.log
#    a growing session.log full of "session sess-N established ..." lines
```

A `Running` Pod with an empty log is not a dead end — it means the app isn't writing to stdout. Read the banner (it often names the file); confirm with `exec`.

**Fix:** Get that output onto stdout. Either reconfigure the app (preferred when you own it), or add a streaming sidecar (when you can't change it — the file already lives on a shared `emptyDir`):

```bash
# Option A — log to stdout (the twelve-factor default)
kubectl edit deployment session-logger -n app-services
#   in containers[0].args, drop the "  >> /var/log/app/session.log" redirect → echo to stdout

# Option B — streaming sidecar that tails the file to its stdout
kubectl patch deployment session-logger -n app-services --type=json -p='[
  {"op":"add","path":"/spec/template/spec/containers/-","value":{
    "name":"log-stream","image":"busybox:1.36",
    "command":["/bin/sh","-c","touch /var/log/app/session.log; exec tail -f /var/log/app/session.log"],
    "volumeMounts":[{"name":"logs","mountPath":"/var/log/app"}]}}]'
```

**Verify:**

```bash
kubectl rollout status deployment session-logger -n app-services --timeout=60s
kubectl logs -n app-services deploy/session-logger --all-containers=true --tail=6
#    the "session sess-N established ..." lines are now visible via kubectl logs
```

Use `--all-containers` — after the sidecar fix the lines come from `log-stream`, not `app`.

**What this scenario tests:** Recognizing that an empty log on a healthy Pod is a *logging-contract* problem, and bridging file output to stdout. Self-grading questions:

- Did you read the Pod as healthy (Running, 0 restarts) and treat the empty log as "not logging to stdout," rather than assuming a crash?
- Did the startup banner (or an `exec … ls /var/log`) lead you to the file, instead of concluding "this app has no logs"?
- Did you fix it by getting output to stdout (reconfigure or sidecar), rather than telling people to `exec` in and `tail` the file forever?

**Expected time:** 3–6 min once "empty log on a healthy Pod = not on stdout" is a reflex; 10–20 min the first time (lost time goes to restarting the Pod or hunting for a crash that isn't there).

**Production thinking:** The whole log stack keys on stdout/stderr — a node-level collector (Fluent Bit/Vector as a DaemonSet) tails every container's stdout and ships it centrally. An app that logs to a file is invisible to all of it, so its logs never leave the node and vanish when the Pod is replaced. Standardize on "log to stdout"; reserve the streaming sidecar for vendored binaries you genuinely can't change, and know it costs a container and some memory per Pod.

---

## Break/fix 02 — Logs & Events: a crashlooping sidecar

**Symptom:** `sip-monitor` in `signaling` sits at `1/2` with a climbing restart count and `STATUS CrashLoopBackOff`. The SIP monitoring app itself serves fine; one of its two containers keeps dying, and nothing paged because the app never went down.

**Root cause:** The Pod runs two containers — `app` (nginx, healthy) and `metrics-agent` (a telemetry sidecar). The sidecar's command execs `/usr/local/bin/metrics-agent`, a binary that isn't present in its `busybox` image, so it exits 127 immediately and the kubelet restarts it forever. The Pod can never be Ready (readiness requires *all* containers), so it stays `1/2` and that workload's telemetry export is dark<sup><a href="https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/">[3]</a></sup>.

**Diagnostic commands (the canonical path):**

```bash
# 1. 1/2 and CrashLoopBackOff — one of two containers is down
kubectl get pods -n signaling -l app=sip-monitor            # READY 1/2, RESTARTS climbing

# 2. WHICH container? Per-container status names it
kubectl get pod -n signaling -l app=sip-monitor -o \
  custom-columns='CONTAINER:.status.containerStatuses[*].name,READY:.status.containerStatuses[*].ready,RESTARTS:.status.containerStatuses[*].restartCount'
#    app=true, metrics-agent=false (restarts climbing)

# 3. The event stream names it too
kubectl describe pod -n signaling -l app=sip-monitor | sed -n '/Events:/,$p'
#    Warning  BackOff  ...  Back-off restarting failed container=metrics-agent

# 4. Read the DEAD instance's logs — the live one is mid-backoff
kubectl logs -n signaling deploy/sip-monitor -c metrics-agent --previous
#    [metrics-agent] starting; exporting sip-monitor telemetry
#    /bin/sh: exec: line 3: /usr/local/bin/metrics-agent: not found     (exit 127)
```

`get pods` aggregates; the per-container status and the `BackOff` event name the failing container; `-c … --previous` reads why the dead instance died.

**Fix:** Correct the sidecar's command so it runs something the image can execute (in production you'd fix the image or the binary path). `metrics-agent` is container index `1`:

```bash
kubectl patch deployment sip-monitor -n signaling --type=json -p='[
  {"op":"replace","path":"/spec/template/spec/containers/1/args/0",
   "value":"echo \"[metrics-agent] starting; exporting sip-monitor telemetry\"\nwhile true; do echo \"[metrics-agent] exported telemetry batch\"; sleep 30; done\n"}]'
```

**Verify:**

```bash
kubectl rollout status deployment sip-monitor -n signaling --timeout=90s
kubectl get pods -n signaling -l app=sip-monitor                 # READY 2/2, Running
kubectl logs -n signaling deploy/sip-monitor -c metrics-agent --tail=3   # exporting again
```

**What this scenario tests:** Isolating one failing container in a multi-container Pod, and the `-c` + `--previous` pair. Self-grading questions:

- Did the `1/2` push you to find *which* container (per-container status / the `BackOff` event) before touching anything?
- Did you reach for `--previous` — because the current instance is mid-restart and only the dead one carries the error — rather than reading empty live logs?
- Did you read `-c metrics-agent` specifically, not the default (`app`) container that was fine all along?

**Expected time:** 3–6 min once `N-1/N → name the container → -c --previous` is a reflex; 10–20 min the first time (lost time goes to reading the healthy `app` container's logs, or missing that `--previous` holds the exit error).

**Production thinking:** Sidecars *are* the observability topology — log shippers, metrics agents, mesh proxies all ride alongside the app. When one dies quietly, the app keeps serving and no alert fires, but you go blind on that workload. Alert on Pods that are `Ready < desired` for more than a few minutes (not just on Pods that are fully down), and treat a crashlooping telemetry sidecar as an incident, because the thing that would normally tell you something is wrong is itself the thing that's broken.

---

## Break/fix 03 — Metrics: a scrape target that's DOWN

**Symptom:** `call-metrics` in `analytics` is `Running 1/1`, `kubectl top` shows it consuming CPU/memory normally, and its `/metrics` endpoint serves fine — but every dashboard and alert built on its metrics has gone flat. No new data is arriving.

**Root cause:** Two separate metrics pipelines. The **resource metrics** pipeline (metrics-server → `kubectl top`) is healthy, which is why `top` still works. The **application metrics** pipeline is broken: the Pod's `prometheus.io/port` annotation advertises `9090`, but the container serves `/metrics` on `80`. A Prometheus discovers the Pod by its annotations and scrapes `podIP:9090`, gets connection-refused, and marks the target **DOWN** — so the metric never arrives and the graph flatlines<sup><a href="https://prometheus.io/docs/concepts/data_model/">[6]</a></sup>. The app is healthy; the scrape target is misconfigured.

**Diagnostic commands (the canonical path):**

```bash
# 1. App healthy, and the OTHER pipeline (kubectl top) works
kubectl get pods -n analytics -l app=call-metrics          # Running 1/1
kubectl top  pod  -n analytics -l app=call-metrics          # CPU/mem returned → pipeline 1 fine

# 2. The app really exposes /metrics — on its real port (80)
POD_IP=$(kubectl get pod -n analytics -l app=call-metrics -o jsonpath='{.items[0].status.podIP}')
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s http://$POD_IP:80/metrics                      # exposition output returns

# 3. But the scrape annotation points elsewhere
kubectl get pod -n analytics -l app=call-metrics \
  -o jsonpath='{.items[0].metadata.annotations.prometheus\.io/port}{"\n"}'   # 9090

# 4. Reproduce the scrape at the advertised port → refused
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s -m 5 -o /dev/null -w "HTTP %{http_code}\n" http://$POD_IP:9090/metrics   # HTTP 000
```

A healthy `kubectl top` with flat app dashboards is the tell: pipeline 1 is fine, so the fault is in pipeline 2 — the scrape.

**Fix:** Point the scrape port at the port `/metrics` is actually served on (80). With annotations:

```bash
kubectl patch deployment call-metrics -n analytics -p \
  '{"spec":{"template":{"metadata":{"annotations":{"prometheus.io/port":"80"}}}}}'
# With the Prometheus Operator, you'd fix the ServiceMonitor's `port` instead — same mismatch.
```

**Verify:**

```bash
kubectl rollout status deployment call-metrics -n analytics --timeout=60s
kubectl get deploy call-metrics -n analytics \
  -o jsonpath='{.spec.template.metadata.annotations.prometheus\.io/port}{"\n"}'   # 80
POD_IP=$(kubectl get pod -n analytics -l app=call-metrics -o jsonpath='{.items[0].status.podIP}')
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s -o /dev/null -w "HTTP %{http_code}\n" http://$POD_IP:80/metrics        # HTTP 200
```

**What this scenario tests:** The two-pipelines distinction, and fixing a scrape target rather than the app. Self-grading questions:

- Did a healthy `kubectl top` tell you the app and metrics-server were fine, steering you to the scrape rather than the workload?
- Did you prove the app exposes `/metrics` on its real port *before* concluding the app was fine — so the fault had to be in discovery/scraping?
- Did you compare the advertised scrape port to the serving port, and fix the annotation (or ServiceMonitor), not the app?

**Expected time:** 3–6 min once "flat graphs + healthy `top` = scrape problem" is a reflex; 10–20 min the first time (lost time goes to restarting or "fixing" a perfectly healthy app).

**Production thinking:** A one-digit port typo silently drops an entire workload from monitoring — no error on the app, no failed deploy, just a target that reads DOWN in Prometheus and graphs that go flat. This is why teams alert on `up == 0` (the scrape-health metric Prometheus records for every target) in addition to app-level metrics: it catches the workload that fell out of monitoring before someone notices the dashboard is blank during an incident. Bake the scrape port into the same manifest as the container port so the two can't drift, and prefer a ServiceMonitor that references the port *by name* over a hard-coded number.

## References

1. Kubernetes — Event API reference: https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/event-v1/
2. Kubernetes — Logging Architecture: https://kubernetes.io/docs/concepts/cluster-administration/logging/
3. Kubernetes — Debug Running Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
4. Kubernetes — `kubectl logs` reference: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_logs/
5. Kubernetes — Resource Metrics Pipeline: https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/
6. Prometheus — Data model and metric types: https://prometheus.io/docs/concepts/data_model/
