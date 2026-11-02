# Done

The controller returned a 404 because no rule matched /index.html. The backend served that path directly. The rule used pathType Exact on /, which matches only /. The fix changed pathType to Prefix.

The reflex: **404 is a rule problem, so compare the request's host and path with the rule.** A direct call to the Service tells you whether the backend serves the path. The controller's access log names the upstream that handled the request. upstream-default-backend means no rule did.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the why, read [`LESSON.md`](../LESSON.md) § Ingress.
- You finished the module. Together the five scenarios cover the differential: a silent timeout, a cross-namespace allow, a 503, a DNS egress timeout and a 404.
