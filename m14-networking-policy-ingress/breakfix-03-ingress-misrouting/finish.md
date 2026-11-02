# Done

A 503 meant the controller matched a rule and had no backend. The backend was healthy: portal-ui had endpoints and answered on port 80. The break sat in the rule. It forwarded to portal-ui port 8080, a port the Service never exposed.

The reflex: **503 is a backend problem (Service name, port or endpoints). 404 is a rule problem (host or path).** Read the code first. Then read the Ingress rule against the Service it names.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the why, read [`LESSON.md`](../LESSON.md) § Ingress.
- Next scenario: **breakfix-04-egress-dns-timeout**. Every name lookup in a namespace times out while CoreDNS is healthy.
