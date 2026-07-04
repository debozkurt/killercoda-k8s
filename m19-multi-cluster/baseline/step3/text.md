# Step 3 — Promotion across tiers

A new image is rolled out by **promoting** it through tiers in order — lab, then stage, then prod — so each tier is a gate. In a layered fleet, promotion isn't a copy into every cluster; it's advancing a pin from one tier's overlay to the next. Render the image each us-east-1 tier currently gets:

```bash
cd /root/fleet
for t in lab stage prod; do
  echo -n "$t: "
  kubectl kustomize clusters/$t-us-east-1 | grep -m1 'image: nginx'
done
```{{exec}}

`1.27` has cleared lab and stage; prod still renders the base default `1.25`. The tiers legitimately differ — that's the gate working, not drift. `1.27` reaches prod only when `clusters/prod-us-east-1` gets the pin.

## Where a pin lives sets its blast radius

Look at where lab and stage carry that pin, and where prod doesn't:

```bash
grep -rn 'newTag' clusters/lab-us-east-1 clusters/stage-us-east-1 clusters/prod-us-east-1
```{{exec}}

Lab and stage each carry their own `images:` pin; prod has none, so it inherits `1.25` from the base. **The layer you edit is the blast radius.** A pin in a leaf touches one cluster. The same tag put in the **base** would hand `1.27` to lab, stage, *and* prod in a single commit — the gate bypassed. Confirm the base carries no image pin:

```bash
grep -n 'image:' base/deployment.yaml
grep -rn 'images:' base/ || echo "base has no images: transformer — good, per-tier rollout stays in the leaves"
```{{exec}}

The base pins `nginx:1.25` in the Deployment (the fleet default) and has no `images:` transformer, so the promoted tag stays a per-tier decision. Reserve the base for changes every cluster must take at once — a security floor, a corrected default. Step 4 applies one cluster and confirms the API server holds only rendered objects.
