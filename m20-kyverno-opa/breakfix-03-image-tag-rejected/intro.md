# M20 — Break/fix 03: Image Admission Rejects the Tag

> Pre-req: the M20 baseline tour. You've seen `disallow-latest-tag` refuse a `:latest` image; this is that rejection stalling a real rollout.

A new tenant workload, `call-recorder`, was deployed to `tenant-apps` and never came up. `kubectl get deploy -n tenant-apps` shows it `0/1`, and — like breakfix-01 — there are **no Pods at all**. Same top-line signature as the resource-limits scenario: an admission rejection of the Pods the ReplicaSet keeps trying to create, so the count stays at zero and the reason lives on the ReplicaSet.

But this time the rejecting rule is different, and so is the fix. This is the **supply-chain gate** — the policy that decides *what image is allowed to run here*. The platform bans the mutable `:latest` tag: an image tagged `latest` can change under a running Pod with no manifest change, which is both a reproducibility problem and a classic supply-chain foothold. Somebody shipped `call-recorder` on `:latest`.

Your job: read the `FailedCreate` denial, confirm it's the image policy (not the limits one), and pin the image to an explicit version. The cluster plus Kyverno take about 2–4 minutes to come up. Click **Start** when ready.
