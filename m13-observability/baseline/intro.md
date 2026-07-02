# M13 — Baseline Tour

A running cluster gives you three signals for free, and each answers a different question: **events** tell you what the *control plane* did, **logs** tell you what the *process* said, **metrics** tell you how much it's *using*. (A fourth — traces — you add yourself; you'll meet it in the lesson.) The skill is reaching for the right one first.

This tour runs on the full Polyphone fleet on a **2-node cluster**, plus one added workload — `call-metrics` in `analytics`, a healthy application-metrics target. Nothing to fix — you're learning to *read* each signal while it's healthy, so a dark one stands out later.

Four short steps:

1. **Events** — the event stream as structured objects (`type`/`reason`/`count`), surveyed with `--field-selector` and `--sort-by`
2. **Logs** — `kubectl logs` and its load-bearing flags (`--tail`/`--since`/`-c`/`--previous`), and the stdout/stderr contract
3. **Resource metrics** — `kubectl top` for live CPU/memory, and the pipeline behind it
4. **Application metrics** — a `/metrics` exposition endpoint and the `prometheus.io/*` scrape annotations a Prometheus discovers it by

The cluster takes 90–150 seconds to come up. Click **Start** when ready.
