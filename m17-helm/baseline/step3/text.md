# Step 3 — Values and overrides

A release's behavior is the chart defaults **merged with** the overrides you supplied. This step reads that merge, then changes it with an upgrade.

## See the values a release was installed with

```bash
helm get values voicemail -n app-services
```{{exec}}

This shows only the **user-supplied** overrides — `replicaCount: 2` and `config.sipRealm: polyphone.example`, the two values passed at install. It does *not* show chart defaults you didn't override.

To see the fully-merged, effective values (defaults + overrides):

```bash
helm get values voicemail -n app-services -a
```{{exec}}

Now `image`, `service`, `resources`, and `config.greeting` appear too — pulled from the chart's `values.yaml`. When a release behaves unexpectedly, `-a` (`--all`) is how you see what value *actually* took effect.

## Precedence — who wins

Values merge in a fixed order, lowest to highest:

```text
chart values.yaml   <   -f myvalues.yaml   <   --set key=value
                        (rightmost -f wins        (highest precedence)
                         if repeated)
```

`--set` beats a `-f` file beats the chart default. Repeated `-f` files: the rightmost wins. Getting a value to take is almost always a question of *precedence* and *exact key path*, not of Helm "not working."

## Change a value with `helm upgrade`

Scale the release to 3 replicas. `--reuse-values` keeps the other overrides (the required `sipRealm`) so you only state what changes:

```bash
helm upgrade voicemail /root/voicemail \
  --namespace app-services \
  --reuse-values \
  --set replicaCount=3
```{{exec}}

`helm upgrade` re-merges, re-renders, applies the diff, and records a new revision. Watch the third pod appear:

```bash
kubectl get pods -n app-services -l app=voicemail
```{{exec}}

## Verify

```bash
helm get values voicemail -n app-services | grep -E "replicaCount|sipRealm"
kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.replicas}{"\n"}'
```{{exec}}

`replicaCount: 3` in the values, `3` on the Deployment. The upgrade created revision 2 — you'll walk that history in step 4. Move on.
