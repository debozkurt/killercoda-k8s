# M17 — Break/fix 05: Release Stuck Pending

> Pre-req: the M17 baseline and breakfix-02, or working knowledge of `helm history` and `helm rollback`.

Earlier today a deploy job ran `helm upgrade voicemail --wait` to change its memory settings. The CI runner was cancelled during the wait. Now you need to ship a new voicemail greeting, and the upgrade fails at once:

```text
helm upgrade voicemail /root/voicemail --namespace app-services --reuse-values \
  --set config.greeting="Please leave a message after the tone."
```

```text
+-----------------------------------------------------+
| deploy voicemail (app-services): FAILED             |
| helm upgrade exited 1 -- retried 3 times            |
| no other deploy job running for voicemail           |
+-----------------------------------------------------+
```

Find out what blocks the upgrade, return `voicemail` to its healthy settings, and ship the greeting.

Setup takes about three minutes. Click **Start** when the terminal says the cluster is ready.
