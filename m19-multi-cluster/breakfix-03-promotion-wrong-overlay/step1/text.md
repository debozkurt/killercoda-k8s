# Step 1 — Diagnose the two-sided symptom

Render the image every us-east-1 tier currently gets — the promotion ladder at a glance:

```bash
cd /root/fleet
for t in lab stage prod; do
  echo -n "$t: "
  kubectl kustomize clusters/$t-us-east-1 | grep -m1 'image: nginx'
done
```{{exec}}

Read the ladder: lab `1.27`, stage `1.25`, prod `1.27`. That's backwards. Promotion goes lab → stage → prod, so a healthy ladder is monotonic — a tier is never behind the one after it. Here stage is *behind* prod. Two symptoms in one: stage didn't advance, and prod overshot to a tag it was never approved for.

The applied stage cluster confirms the stall:

```bash
kubectl get deploy edge-relay -n edge -o jsonpath='stage running {.spec.template.spec.containers[0].image}{"\n"}'
```{{exec}}

`nginx:1.25` — stage is live on the old tag.

## Find where the pin actually landed

The `1.27` pin exists — the question is which overlay holds it. Grep the image transformer across all three tiers:

```bash
grep -rn 'newTag' clusters/lab-us-east-1 clusters/stage-us-east-1 clusters/prod-us-east-1
```{{exec}}

Lab pins `1.27` (correct — it cleared lab first). Stage pins `1.25` (the promotion never updated it). Prod pins `1.27` — but prod is supposed to carry *no* image pin and inherit the base `1.25` until it's approved. The pin meant for stage was written into prod's overlay instead.

```bash
cat clusters/prod-us-east-1/kustomization.yaml
```{{exec}}

There's the `images:` block that doesn't belong — a fat-fingered file, `prod` edited where `stage` was meant. The value is right; the layer is wrong, and the layer is the blast radius. On to the fix.
