# M03 — Break/fix 03: config edited, nothing changed

> Pre-req: the M03 baseline tour, or comfort with how env vars vs mounted files behave on a config change.

An engineer is chasing an intermittent issue in `session-broker` (`media`) and raised its log level to `debug` by editing the `app-config` ConfigMap. The change applied cleanly — `kubectl get configmap` shows `debug` — but the logs never got more verbose. As far as the running workload is concerned, nothing happened.

This is the third config-failure shape, and it's the one that wastes the most time because *nothing looks broken*. The Pod is `Running` and `Ready`. The ConfigMap holds the new value. And yet the workload is still on the old one. No status, no event, no error will point at this — you have to know how config propagation works to even see it.

Your job: confirm the disagreement between the ConfigMap and the running container, explain why the edit didn't reach it, and make it take effect. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
