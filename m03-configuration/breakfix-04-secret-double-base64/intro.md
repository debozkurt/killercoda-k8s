# M03 — Break/fix 04: Running, but the credential is wrong

> Pre-req: the M03 baseline tour, or comfort with how a Secret's `data` is base64-encoded.

Tenant provisioning is failing. `account-provisioner` in `provisioning` is `Running` and `Ready` — no crashes, no restarts, every health check green — but it can't authenticate to its database. The password it's presenting is being rejected.

This is the fourth and sharpest config-failure shape: there is **no error state to find**. The Pod is healthy by every status Kubernetes reports. The wiring resolved, a value was injected, the container started. The value is just *wrong*. You can't diagnose this from `get` or `describe` — you have to read the value the container actually received, and recognize what's off about it.

This is the configuration version of an instinct the whole curriculum keeps sharpening: a green headline that's still wrong. `Running` doesn't mean *correct*. Your job: read the injected credential, see why it's garbage, and fix the Secret it came from. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
