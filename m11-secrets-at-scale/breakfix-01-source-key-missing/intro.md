# M11 — Break/fix 01: Missing Source Key

> The healthy pipeline from the baseline, with one link broken.

An alert fires: `partner-connector` in the `media` namespace has no ready Pod. The billing side of the fleet is healthy.

The Secret that `partner-connector` reads is not hand-written. The `secret-operator` materializes it from a `SecretSync`. So the question is not only "which Secret is missing" but "why did the pipeline not produce it".

Your job: find the broken link, fix it at the source, and confirm that the consumer recovers without a manual restart.

The cluster takes 90–150 seconds to come up. Click **Start** when ready.
