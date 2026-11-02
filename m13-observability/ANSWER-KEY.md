# M13 — Observability — Answer Key

> Self-grading reference. Work each scenario first, then compare your diagnostic path with the canonical one here. An instructor who runs the lab live can read the same sections as a teaching script.
> Environment: Killercoda `kubernetes-kubeadm-2nodes` with the Polyphone baseline. Each break/fix layers a small workload on the fleet. Nothing in the base fleet is broken. The fault is one field or one command in the path of one signal.

## Lesson summary

M13 teaches the three signals a running cluster gives you, and the fourth you add. **Events** show what the control plane did. **Logs** show what the process said. **Metrics** show how much the workload uses, and how it behaves. **Traces** are a concept here. All three built-in signals are ephemeral: events expire after the TTL, logs leave with the Pod, and `kubectl top` keeps no history. A durable stack exists to replace all three.

The baseline reads each signal on a healthy fleet. The five break/fix scenarios each break the reading of one signal:

- `breakfix-01-logs-to-stdout`: **an empty log on a healthy Pod.** The app writes to a file.
- `breakfix-02-sidecar-crashloop`: **a 1/2 Pod.** A sidecar exits 1 after it starts. `--previous` pins the instance that died.
- `breakfix-03-metrics-scrape-port`: **a target that is DOWN.** The scrape port is wrong.
- `breakfix-04-event-only-failure`: **a workload with no logs.** Only a Warning event names the cause.
- `breakfix-05-scrape-target-absent`: **a target that is absent.** The Service has no endpoints.

The reflexes: an empty log on a Running Pod means the app does not log to stdout. N-1/N means one container is down: name it, then read it with `-c … --previous`. A Pod that never started has no logs, only events. Flat dashboards with a healthy `kubectl top` mean the scrape: check the endpoints, then the port.

## Baseline tour reference

No broken state. Expected output per step:

- **Step 1 (Events):** After `kubectl rollout restart`, `kubectl events -n media` lists `ScalingReplicaSet`, `Scheduled`, `Pulled`, `Created` and `Started`, oldest first.<sup><a href="https://kubernetes.io/docs/reference/kubectl/generated/kubectl_events/">[1]</a></sup> `-A --types=Warning` is short or empty on a healthy fleet. `describe` shows the same events with `x3 over 5m` counts. `get events` does not sort and hides the count column. Events expire after one hour by default.<sup><a href="https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/">[3]</a></sup>
- **Step 2 (Logs):** A throwaway `curl` Pod sends one request. `kubectl logs deploy/session-broker --tail=3` shows the access line. The kubelet captures stdout and stderr only.<sup><a href="https://kubernetes.io/docs/concepts/cluster-administration/logging/">[2]</a></sup>
- **Step 3 (Resource metrics):** `kubectl top nodes` and `kubectl top pods -A --sort-by=memory` return live CPU and memory. Usage next to the request gives the ratio the HPA scales on.<sup><a href="https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/">[5]</a></sup>
- **Step 4 (Application metrics):** `curl call-metrics/metrics` returns the exposition format. `describe pod` shows the three `prometheus.io/*` annotations and the container port 80. `describe service` shows the selector and one endpoint.
- **Step 5 (Restarts):** `restart-demo` reads RESTARTS 1. `describe` shows Last State Terminated with Exit Code 1. `kubectl logs` prints `start 2: healthy`. `--previous` prints `start 1: cannot reach upstream, exiting`. After `kubectl delete pod`, `kubectl logs` fails with NotFound, and `kubectl events --for pod/restart-demo` still lists events until the TTL ends.

---

## Break/fix 01 — an app that writes to a file

**Symptom:** `session-logger` in `app-services` is Running 1/1 with no restarts. `kubectl logs deploy/session-logger` returns one startup line and nothing else. The workload obviously works, yet its log is empty.

**Root cause:** The container writes its output to `/var/log/app/session.log`, a file inside the container, and not to stdout. The kubelet captures only stdout and stderr, so `kubectl logs` sees only the banner that the app prints to stdout at startup.<sup><a href="https://kubernetes.io/docs/concepts/cluster-administration/logging/">[2]</a></sup> Nothing is broken except the logging contract.

**Diagnostic commands:**

```bash
kubectl get pods -n app-services -l app=session-logger          # Running 1/1, 0 restarts
kubectl logs -n app-services deploy/session-logger
#   [session-logger] starting; writing session events to /var/log/app/session.log
kubectl exec -n app-services deploy/session-logger -- ls -l /var/log/app
kubectl exec -n app-services deploy/session-logger -- tail -5 /var/log/app/session.log
#   a growing file of "session sess-N established ..." lines
```

A Running Pod with an empty log means the app does not write to stdout. The banner names the file. `exec` confirms it.

**Fix:** Move the output onto stdout. Option A changes the app. Option B adds a streaming sidecar that shares the log volume:

```bash
# Option A: drop the ">> /var/log/app/session.log" redirect from containers[0].args
kubectl edit deployment session-logger -n app-services

# Option B: a streaming sidecar
kubectl patch deployment session-logger -n app-services --type=json -p='[
  {"op":"add","path":"/spec/template/spec/containers/-","value":{
    "name":"log-stream","image":"busybox:1.36",
    "command":["/bin/sh","-c","touch /var/log/app/session.log; exec tail -F /var/log/app/session.log"],
    "volumeMounts":[{"name":"logs","mountPath":"/var/log/app"}]}}]'
```

**Verify:**

```bash
kubectl rollout status deployment session-logger -n app-services --timeout=60s
kubectl logs -n app-services deploy/session-logger --all-containers=true --tail=6
#   "session sess-N established ..." lines now appear
```

Use `--all-containers`. After Option B the lines come from `log-stream`, not from `app`.

**What this scenario tests:** recognizing an empty log on a healthy Pod as a logging-contract fault. Self-grading questions:

- Did you read the Pod as healthy and treat the empty log as "not on stdout", instead of hunting for a crash?
- Did the banner or `exec … ls /var/log` lead you to the file?
- Did you fix the destination, rather than telling people to `exec` in and tail the file?

**Expected time:** 3–6 minutes once the reflex exists. 10–20 minutes the first time, mostly spent restarting the Pod or hunting a crash that does not exist.

**Production thinking:** The log stack keys on stdout and stderr. A node-level collector, a DaemonSet such as Fluent Bit or Vector, ships every container's stdout to a central store. An app that logs to a file is invisible to it, and its lines vanish when the Pod is replaced. Standardize on "log to stdout". Keep the sidecar for a vendored binary you cannot change. It costs one container per Pod, and if a node agent also runs, the streamed file can double the log storage on the node.<sup><a href="https://kubernetes.io/docs/concepts/cluster-administration/logging/">[2]</a></sup> On Kubernetes v1.29 and later you can declare the sidecar as an init container with `restartPolicy: Always`, so it starts before the app and stops after it.<sup><a href="https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/">[6]</a></sup>

---

## Break/fix 02 — a sidecar that dies after it starts

**Symptom:** `sip-monitor` in `signaling` reads 1/2 with a climbing restart count. The nginx app serves traffic. One of the two containers keeps dying, and nothing paged because the app never went down.

**Root cause:** The Pod runs `app` (nginx, healthy) and `metrics-agent` (a telemetry sidecar). The sidecar prints a banner, waits 15 seconds, then finds that `COLLECTOR_ENDPOINT` is empty, prints a fatal line and exits 1. Its readiness probe passes only after that check, so it is never Ready. The kubelet restarts it with growing back-off. A Pod is Ready only when all of its containers are Ready, so the Pod stays 1/2 and the telemetry is dark.

**Diagnostic commands:**

```bash
kubectl get pods -n signaling -l app=sip-monitor                 # READY 1/2, RESTARTS climbing
kubectl describe pod -n signaling -l app=sip-monitor | grep -E "^  [a-z-]+:$|Ready:|Restart Count|Reason:|Exit Code"
#   app: Ready True.  metrics-agent: Ready False, Last State Terminated, Exit Code 1
kubectl events -n signaling --types=Warning
#   BackOff  Back-off restarting failed container metrics-agent in pod sip-monitor-…
kubectl logs -n signaling deploy/sip-monitor -c metrics-agent             # banner, maybe the error
kubectl logs -n signaling deploy/sip-monitor -c metrics-agent --previous  # banner + fatal line
```

`get pods` aggregates. `describe` and the BackOff event name the failing container. Plain `kubectl logs` returns the current instance when one runs, and the last terminated instance while the container waits in back-off. You cannot tell which you hold. `--previous` selects the last terminated instance in both cases.<sup><a href="https://kubernetes.io/docs/reference/kubectl/generated/kubectl_logs/">[4]</a></sup>

**Fix:** Give the sidecar, and only the sidecar, the variable:

```bash
kubectl set env deployment/sip-monitor -n signaling -c metrics-agent COLLECTOR_ENDPOINT=collector.platform.svc:4317
```

**Verify:**

```bash
kubectl rollout status deployment sip-monitor -n signaling --timeout=90s
kubectl get pods -n signaling -l app=sip-monitor                          # READY 2/2, 0 restarts
kubectl logs -n signaling deploy/sip-monitor -c metrics-agent --tail=3    # after 20 s: exported telemetry batch
```

The sidecar reports ready only after its variable check passes, so a broken instance never reaches 2/2. The verify script waits for the export line and a 2/2 Pod.

**What this scenario tests:** isolating one failing container and reading the instance that died. Self-grading questions:

- Did 1/2 push you to name the container, from `describe` or the BackOff event, before you changed anything?
- Did you use `--previous`, knowing that plain `kubectl logs` may return a new instance that has not failed yet?
- Did you read `-c metrics-agent`, not the default container that was fine all along?

**Expected time:** 3–6 minutes with the reflex. 10–20 minutes the first time, spent on the healthy container's log or on a banner-only read.

**Production thinking:** Sidecars carry the observability topology: log shippers, metrics agents and mesh proxies. When one dies, the app keeps serving and nothing alerts, and you lose sight of that workload. Alert on Pods that are not fully Ready for more than a few minutes, not only on Pods that are down. Treat a crashlooping telemetry sidecar as an incident, because the component that would report trouble is the broken one. Required settings should fail the deploy, not the runtime. A check at start, not 15 seconds later, surfaces the fault sooner.

---

## Break/fix 03 — a scrape target that is DOWN

**Symptom:** `call-metrics` in `analytics` is Running 1/1. `kubectl top` shows normal CPU and memory, and `/metrics` answers on port 80. Every dashboard and alert built on its metrics is flat.

**Root cause:** Two pipelines. The resource metrics pipeline (metrics-server, `kubectl top`) is healthy. The application metrics pipeline is broken: the Pod's `prometheus.io/port` annotation names 9090, but the container serves `/metrics` on 80. A scraper whose configuration follows the annotation calls the Pod on 9090, receives a refused connection, and marks the target DOWN.<sup><a href="https://prometheus.io/docs/concepts/jobs_instances/">[9]</a></sup> The `prometheus.io/*` annotations are a community convention. They work only when the scrape configuration reads them.<sup><a href="https://prometheus.io/docs/prometheus/latest/configuration/configuration/">[7]</a></sup>

**Diagnostic commands:**

```bash
kubectl get pods -n analytics -l app=call-metrics             # Running 1/1
kubectl top pod -n analytics -l app=call-metrics              # CPU and memory: pipeline 1 is fine
POD_IP=$(kubectl get pod -n analytics -l app=call-metrics -o jsonpath='{.items[0].status.podIP}')
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s http://$POD_IP:80/metrics                        # exposition text returns
kubectl describe pod -n analytics -l app=call-metrics | grep -E "prometheus.io|Port:"   # port 9090 vs Port 80
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n analytics \
  -- curl -s -m 5 -o /dev/null -w "HTTP %{http_code}\n" http://$POD_IP:9090/metrics     # HTTP 000
```

A healthy `kubectl top` with flat dashboards means pipeline 1 is fine, so the fault is in the scrape.

**Fix:** Point the annotation at the serving port.

```bash
kubectl patch deployment call-metrics -n analytics -p \
  '{"spec":{"template":{"metadata":{"annotations":{"prometheus.io/port":"80"}}}}}'
```

**Verify:**

```bash
kubectl rollout status deployment call-metrics -n analytics --timeout=60s
kubectl describe pod -n analytics -l app=call-metrics | grep prometheus.io/port     # 80
# a curl to http://$POD_IP:80/metrics returns HTTP 200
```

**What this scenario tests:** the two-pipelines distinction, and fixing the scrape target instead of the app. Self-grading questions:

- Did a healthy `kubectl top` steer you to the scrape, not the workload?
- Did you prove the app serves `/metrics` on its real port before you blamed discovery?
- Did you compare the advertised port with the serving port, and fix the annotation, not the app?

**Expected time:** 3–6 minutes with the reflex. 10–20 minutes the first time, spent restarting a healthy app.

**Production thinking:** One wrong digit removes a workload from monitoring with no error on the app and no failed deploy. Alert on `up == 0`, the series Prometheus records for every target it scrapes.<sup><a href="https://prometheus.io/docs/concepts/jobs_instances/">[9]</a></sup> Keep the scrape port in the same manifest as the container port so they cannot drift. Prefer a ServiceMonitor that names the Service port by name over a hard-coded number.<sup><a href="https://prometheus-operator.dev/docs/api-reference/api/">[8]</a></sup>

---

## Break/fix 04 — a workload with no logs

**Symptom:** A workload that loads call rates never starts. `kubectl events` in the default namespace finds nothing. `kubectl logs` on the Pod fails with `waiting to start: ContainerCreating`. The namespace is not given.

**Root cause:** The Deployment `rate-loader` in `call-routing` mounts a ConfigMap volume that names `rate-table-v2`. The namespace holds `rate-table`. The kubelet cannot set up the volume, so it never starts the container and the Pod waits in ContainerCreating. No container exists to log. The cause appears only as a Warning `FailedMount` event.

**Diagnostic commands:**

```bash
kubectl events                                  # no events: events are namespaced
kubectl events -A --types=Warning
#   call-routing  FailedMount  pod/rate-loader-…  MountVolume.SetUp failed for volume "rates" : configmap "rate-table-v2" not found
kubectl get pods -n call-routing -l app=rate-loader                # ContainerCreating
kubectl logs -n call-routing deploy/rate-loader                    # waiting to start: ContainerCreating
kubectl describe pod -n call-routing -l app=rate-loader | tail -8  # the same event
kubectl get configmap -n call-routing                              # rate-table exists
```

The event names the failing step and the missing object. The log read proves that no logs exist yet.

**Fix:** Point the volume at the ConfigMap that exists. Creating `rate-table-v2` also works, because the kubelet retries the mount on its own.

```bash
kubectl patch deployment rate-loader -n call-routing --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/volumes/0/configMap/name","value":"rate-table"}]'
```

**Verify:**

```bash
kubectl rollout status deployment rate-loader -n call-routing --timeout=90s
kubectl get pods -n call-routing -l app=rate-loader                # Running 1/1
```

The old Warning stays in `kubectl events` until the TTL ends. The event lists the past, and the Pod shows the present.

**What this scenario tests:** reading events when no logs exist, and searching across namespaces. Self-grading questions:

- Did you survey with `-A --types=Warning` when the default namespace was empty, instead of concluding "no events"?
- Did you read the `reason` and the message, and then check which ConfigMaps exist?
- Did you recognize that a Pod in ContainerCreating has no log to read?

**Expected time:** 3–6 minutes with the reflex. 10–20 minutes the first time, spent in the default namespace or on the application.

**Production thinking:** Events expire after the TTL, one hour by default, and nothing stores them.<sup><a href="https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/">[3]</a></sup> An alert that fires at 02:00 and is read at 09:00 finds the evidence gone. Run an event exporter that writes Warning events to a durable store. Alert on Pods stuck in ContainerCreating or Pending past a threshold, because those Pods produce no application signal.

---

## Break/fix 05 — a scrape target that is absent

**Symptom:** `call-metrics` in `analytics` is Running 1/1 and `kubectl top` works. The scrape annotations name port 80, which is correct. Every dashboard is flat. Prometheus lists no DOWN target for it, and an alert on `up == 0` is silent.

**Root cause:** The Service `call-metrics` selects `app=call-metric`, one letter short of the Pod's label `app=call-metrics`. The selector matches no Pod, so the Service has no endpoints. A ServiceMonitor discovers targets through a Service's endpoints,<sup><a href="https://prometheus-operator.dev/docs/api-reference/api/">[8]</a></sup> so the scraper finds no target. An absent target produces no `up` series, so an alert on `up == 0` has nothing to evaluate.

**Diagnostic commands:**

```bash
kubectl get pods -n analytics -l app=call-metrics                 # Running 1/1
kubectl top pod -n analytics -l app=call-metrics                  # works
kubectl describe service call-metrics -n analytics | grep -E "Selector|Endpoints"
#   Selector: app=call-metric   Endpoints: <none>
kubectl get pods -n analytics -l app=call-metrics --show-labels   # app=call-metrics
kubectl describe pod -n analytics -l app=call-metrics | grep -E "prometheus.io|Port:"   # port 80 matches: rule out the port
```

DOWN has an address that refuses a connection. Absent has no address. Check the endpoints before the port.

**Fix:** Correct the selector. A Service is not a Pod template, so nothing rolls.

```bash
kubectl patch service call-metrics -n analytics -p '{"spec":{"selector":{"app":"call-metrics"}}}'
```

**Verify:**

```bash
kubectl describe service call-metrics -n analytics | grep -E "Selector|Endpoints"   # one address
# a curl to http://call-metrics/metrics from a Pod in analytics returns HTTP 200
```

**What this scenario tests:** telling an absent target from a DOWN target. Self-grading questions:

- Did you check the Service endpoints before the port, and then confirm the port was fine?
- Did you read the Service's Endpoints line, and compare its selector with the Pod's labels?
- Can you say why `up == 0` stays silent here?

**Expected time:** 3–6 minutes with the reflex. 10–20 minutes the first time, spent re-checking a port that was right.

**Production thinking:** A single typo in a selector hides a workload from monitoring and from traffic. Alert on absence, for example `absent(up{job="call-metrics"})`, as well as on `up == 0`. Add a CI check that every Service selector matches at least one Pod label set in the same manifest set. Alert on Services that have zero ready endpoints.

## References

1. Kubernetes — `kubectl events` reference: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_events/
2. Kubernetes — Logging Architecture: https://kubernetes.io/docs/concepts/cluster-administration/logging/
3. Kubernetes — `kube-apiserver` reference (`--event-ttl`): https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/
4. Kubernetes — `kubectl logs` reference: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_logs/
5. Kubernetes — Resource Metrics Pipeline: https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/
6. Kubernetes — Sidecar Containers: https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/
7. Prometheus — Configuration (`kubernetes_sd_config`): https://prometheus.io/docs/prometheus/latest/configuration/configuration/
8. Prometheus Operator — API reference (ServiceMonitor): https://prometheus-operator.dev/docs/api-reference/api/
9. Prometheus — Jobs and instances (`up`): https://prometheus.io/docs/concepts/jobs_instances/
