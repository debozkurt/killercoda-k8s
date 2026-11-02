# Done

The verb, identity, and scope all matched the grant. The API group did not. The Forbidden said `in API group "apps"`, and the Role named `deployments` in the core group. `kubectl describe role` showed it: the resource had no `.apps` suffix. RBAC matches exact strings, so a rule for core `deployments` matches no request any client sends.

You have now broken every field of the Forbidden sentence: verb (01), identity (02), scope (03), and API group (05). Each field maps to one object.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Next scenario: **`breakfix-06-runasnonroot-root-image`**. A Pod that passes admission and still never starts.
