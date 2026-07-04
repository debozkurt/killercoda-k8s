# Step 2 — Move the pin to the right overlay and verify

Promotion is *moving* the pin, not copying it. Put `1.27` where it was headed — the stage overlay — and take it out of prod, which should go back to inheriting the base default:

```bash
cd /root/fleet
# advance stage to the promoted tag
sed -i 's/newTag: "1.25"/newTag: "1.27"/' clusters/stage-us-east-1/kustomization.yaml
# remove the pin that overshot into prod (prod inherits base 1.25 again)
sed -i '/^images:/,/newTag/d' clusters/prod-us-east-1/kustomization.yaml
```{{exec}}

Or edit by hand: set stage's `newTag` to `1.27`, and delete the whole `images:` block from `clusters/prod-us-east-1/kustomization.yaml`.

## Render before you apply

Check the ladder is monotonic again — no tier behind the one after it:

```bash
for t in lab stage prod; do
  echo -n "$t: "
  kubectl kustomize clusters/$t-us-east-1 | grep -m1 'image: nginx'
done
```{{exec}}

lab `1.27`, stage `1.27`, prod `1.25` — `1.27` has advanced through stage; prod correctly holds at the base default, awaiting its own promotion. Apply the stage cluster that was live on the stale tag:

```bash
kubectl apply -k clusters/stage-us-east-1
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```{{exec}}

## Verify

Confirm stage is running the promoted image, and prod would render the gated one:

```bash
kubectl get deploy edge-relay -n edge -o jsonpath='stage running {.spec.template.spec.containers[0].image}{"\n"}'
kubectl kustomize clusters/prod-us-east-1 | grep -m1 'image: nginx'
```{{exec}}

Stage on `nginx:1.27`, prod renders `nginx:1.25`. The pin moved one tier, exactly as a promotion should. The diagnosis was reading a non-monotonic ladder and finding the layer the value landed in. For the full write-up see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
