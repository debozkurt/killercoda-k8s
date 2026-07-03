# Done

This one looked fixed before you started — an allow policy existed and even named `sip-app`. The trap was the peer: a bare `podSelector` is evaluated in the *policy's* namespace, so `podSelector: { app: sip-app }` in a `media` policy means "sip-app pods in media," of which there are none. The allow matched an empty set; the default-deny handled everything else; the cross-namespace caller was dropped.

Adding a `namespaceSelector` — combined with the `podSelector` in one `from` element, an AND — pointed the peer at `sip-app` pods in `app-services`. The reflex to carry: **cross-namespace allows always need a `namespaceSelector`; a `podSelector` alone never leaves the policy's namespace.** And mind the list shape — two selectors in one element is an AND, two separate elements is an OR, and the difference is a security boundary.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Peers and selectors.
- Next scenario: **`breakfix-03-ingress-misrouting`** — leave east-west behind; an Ingress returns `503` with a perfectly healthy backend.
