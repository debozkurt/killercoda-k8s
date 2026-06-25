# Done

You diagnosed a Pod stuck before it ever ran. `ContainerCreating` that never resolves — with no logs and no config error — points at a volume the kubelet can't set up; the `FailedMount` event named the missing piece (`secret "portal-secrets" not found`). Creating the Secret let the kubelet's retry loop finish the mount and start the container, no restart required.

Compare it with break/fix 01: same family of root cause (a referenced object that isn't there), but consumed as a *volume* instead of *env*, so it failed at mount time instead of container-creation time — a different status, a different event, a different place to look. That contrast is the spine of the module: **how a Pod consumes config decides how a missing reference fails.**

The next two scenarios are subtler — the Pod runs fine, but the config is wrong.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § "Two ways in" and § "When config breaks the Pod".
- Next scenario: **`breakfix-03-stale-env-config`** — a ConfigMap was edited, but the workload still serves the old value.
