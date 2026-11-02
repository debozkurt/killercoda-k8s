# Done

The crash loop had no application bug. The logs held a 403: `cannot list resource "endpoints" … in the namespace "media"`. The identity was the intended ServiceAccount, so the permission was short. The Role granted `get` and `watch`, and a collection read needs `list`. One verb turned `kubectl auth can-i` from `no` to `yes`.

The reflex: **a crash loop whose logs say `Forbidden` is an RBAC fault.** Read the five fields, prove the denial with `auth can-i`, and change the one object that does not match.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Next scenario: **`breakfix-02-serviceaccount-default`**. The 403 looks the same, but the identity differs.
