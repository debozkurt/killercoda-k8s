# Step 3 — Values and an upgrade

A release runs the chart defaults merged with your overrides. Later sources win: `values.yaml`, then each `-f` file (the rightmost wins), then each `--set`.

## Read the values

```bash
helm get values voicemail -n app-services
```{{exec}}

`USER-SUPPLIED VALUES` lists only the overrides from the install: `replicaCount: 2` and `config.sipRealm`.

```bash
helm get values voicemail -n app-services -a
```{{exec}}

`COMPUTED VALUES` (`-a` is `--all`) adds the chart defaults: `image`, `resources`, `service`, `config.greeting`. This is the full input to the render.

## Change a value

`--reuse-values` keeps the overrides from the current revision, so you state only the change. Without it, the upgrade drops `config.sipRealm` and the render fails.

```bash
helm upgrade voicemail /root/voicemail \
  --namespace app-services \
  --reuse-values \
  --set replicaCount=3
```{{exec}}

Helm renders again, records revision 2 and applies it. The output reads `STATUS: deployed` and `REVISION: 2`.

```bash
kubectl get deployment voicemail -n app-services
```{{exec}}

`READY` reads 3/3 after a few seconds.
