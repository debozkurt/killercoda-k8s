# Done

You read all three built-in signals on a healthy fleet: the **event** stream as structured objects (`type`/`reason`/`count`, surveyed with `--field-selector` and `--sort-by`, aggregated by `describe`), container **logs** and their load-bearing flags (`--tail`/`--since`/`-c`/`--previous`) plus the stdout-only contract, live **resource metrics** through `kubectl top`, and a healthy **application-metrics** target — its `/metrics` exposition output and the `prometheus.io/*` annotations a scraper discovers it by. That's the shape of "observable" — internalize it so a dark signal stands out.

**Next:**

- For the *why* behind all of it — the three questions, the ephemerality, the two metrics pipelines, and where traces fit — read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order — each breaks the reading of exactly one signal:
  - **`breakfix-01-logs-to-stdout`** — a `Running 1/1` workload whose `kubectl logs` shows only a startup banner: it writes its real logs to a file, breaking the stdout contract.
  - **`breakfix-02-sidecar-crashloop`** — a Pod stuck at `1/2`: the app is fine but its telemetry sidecar crashloops; read *which* container the events name, then `logs -c … --previous`.
  - **`breakfix-03-metrics-scrape-port`** — a healthy app with flat dashboards: the scrape port annotation points at a port nothing serves, so the target is DOWN.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
