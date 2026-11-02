# M11 — Break/fix 03: Rotation Not Propagated

> The healthy pipeline from the baseline, after a credential rotation. Work breakfix-01 and 02 first.

Overnight, the database password was rotated in the store. The operator synced the new value, and every `SecretSync` reads `Synced`. Yet the database team reports that `billing-processor` in `provisioning` still connects with the old password.

Every status in the pipeline is green. The failure lives past the last object that has a status. A headline status can lie: `Running` is not `Ready` (M01), `Complete` is not correct (M01b), and `Synced` is not adopted.

Your job: find where the old value is still alive, explain why the rotation stopped short of it, and make the new value reach the process.

The cluster takes 90–150 seconds to come up. Click **Start** when ready.
