#!/bin/bash
# Checks: the release installed and owns the Service. The Service keeps the
# UID it had before the install (adopted, not deleted and recreated), carries
# the release annotations, and has the voicemail Pods as endpoints.
command -v helm >/dev/null 2>&1 || { echo "helm CLI not found on PATH" >&2; exit 1; }

helm status voicemail -n app-services 2>/dev/null | grep -q '^STATUS: deployed' \
  || { echo "voicemail release is not deployed. Adopt the Service, then helm install." >&2; exit 1; }

OWNER=$(kubectl get service voicemail -n app-services -o jsonpath='{.metadata.annotations.meta\.helm\.sh/release-name}' 2>/dev/null)
[ "$OWNER" = "voicemail" ] || { echo "The voicemail Service is not owned by the voicemail release" >&2; exit 1; }

UID_NOW=$(kubectl get service voicemail -n app-services -o jsonpath='{.metadata.uid}' 2>/dev/null)
UID_BEFORE=$(cat /tmp/.m17-svc-uid 2>/dev/null)
[ -z "$UID_BEFORE" ] || [ "$UID_NOW" = "$UID_BEFORE" ] \
  || { echo "The voicemail Service was deleted and recreated (new UID and ClusterIP). The scenario asks to adopt it in place." >&2; exit 1; }

READY=$(kubectl get deployment voicemail -n app-services -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "${READY:-0}" -ge 2 ] || { echo "Expected 2 ready voicemail Pods, got ${READY:-0}. Wait a few seconds and check again." >&2; exit 1; }

EPS=$(kubectl get endpoints voicemail -n app-services -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w)
[ "$EPS" -ge 2 ] || { echo "The voicemail Service has $EPS endpoints, expected 2" >&2; exit 1; }

echo "✓ Service adopted in place: release deployed, $READY Pods ready, $EPS endpoints"
exit 0
