# Step 1 — Diagnose the allow that allows nothing

The timeout matches break/fix 01, and an allow already exists. Reproduce the failure as the real caller, then read the allow.

## Reproduce it as sip-app

The caller lives in app-services and carries the label app=sip-app. Test with the same identity:

```bash
kubectl run sip-app --rm -i --restart=Never --labels app=sip-app \
  --image=busybox:1.36 -n app-services -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/
```{{exec}}

The call hangs and times out. Rule out the earlier layers:

```bash
kubectl get endpoints session-broker -n media
```{{exec}}

Endpoints exist, and the name resolves as it did in the baseline. A policy drops the call. One policy names sip-app, so read it.

## Read the allow and its peer

```bash
kubectl get networkpolicy -n media
kubectl describe networkpolicy allow-broker-from-app -n media
```{{exec}}

Two policies exist: the default-deny, and the allow that selects session-broker. In the allow, the From section holds one PodSelector, app=sip-app, and no NamespaceSelector. A bare podSelector selects Pods in the policy's own namespace. This peer means "Pods labeled app=sip-app in media".

## Confirm the reasoning

```bash
kubectl get pods -n media -l app=sip-app
kubectl get pods -n app-services -l app=sip-app
```{{exec}}

media holds no sip-app Pod. The real one is in app-services. The allow matches an empty set, the deny handles everything else, and the call is dropped. The peer must name the namespace. On to the fix.
