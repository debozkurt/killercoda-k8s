# Done

The prod patch targeted `{kind: Deployment, name: relay}`. A target name is an anchored regular expression, so it matched nothing, and Kustomize applied the patch to zero resources without an error. Every stage was green, because every stage checked the render you produced, not the render you meant.

The reflex: **when everything is green and a change is missing, read the render for the field you expected.**

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Next scenario: **`breakfix-05-hash-disabled-stale-config`**.
