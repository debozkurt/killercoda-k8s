# M19 — Break/fix 03: Promotion in the Wrong Overlay

> Pre-req: break/fix 01 and 02. You've fixed a stale value and a shadowed one. This time the value is *correct* — it's just in the wrong layer.

`nginx:1.27` cleared lab and was promoted to stage this morning. Two things are wrong now. Stage still runs `1.25` — the promotion didn't take. And prod, which should be nowhere near `1.27` yet, is rendering it. A promotion that was supposed to advance one tier managed to skip the one it targeted and jump to the one it should never have touched.

Nothing here is stale and nothing is being shadowed. The `1.27` pin is exactly the value you wanted — it's sitting in the wrong file. This is the third way a fleet value goes wrong: right value, wrong layer, and the layer sets the blast radius. Your job is to read the two-sided symptom, find where the pin actually landed, and move it to the overlay that owns that promotion step.

The fleet repo is at `/root/fleet`. The `stage-us-east-1` cluster is applied into the `edge` namespace, running the tag it never should have kept. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
