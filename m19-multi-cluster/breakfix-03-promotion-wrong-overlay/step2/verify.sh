#!/bin/bash
# Checks the promotion ladder is monotonic again: stage RENDERS and RUNS the
# promoted nginx:1.27, and prod RENDERS the gated base default nginx:1.25 (the pin
# moved out of prod). Asserts the outcome, not the method.
FLEET=/root/fleet
NS=edge

STG=$(kubectl kustomize "$FLEET/clusters/stage-us-east-1" 2>/dev/null | grep -m1 'image: nginx' | awk '{print $2}')
PRD=$(kubectl kustomize "$FLEET/clusters/prod-us-east-1" 2>/dev/null | grep -m1 'image: nginx' | awk '{print $2}')

[ "$STG" = "nginx:1.27" ] || { echo "stage-us-east-1 should render nginx:1.27 (the promoted tag), got '${STG:-<none>}'. Set stage's newTag to 1.27." >&2; exit 1; }
[ "$PRD" = "nginx:1.25" ] || { echo "prod-us-east-1 should render nginx:1.25 (inherit the base default), got '${PRD:-<none>}'. Remove the images pin from prod's overlay." >&2; exit 1; }

LIVE=$(kubectl get deploy edge-relay -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[ "$LIVE" = "nginx:1.27" ] || { echo "stage is rendered correctly, but the live cluster still runs '${LIVE:-<none>}'. Re-apply: kubectl apply -k clusters/stage-us-east-1." >&2; exit 1; }

echo "✓ Promotion ladder monotonic: stage renders+runs nginx:1.27, prod holds at nginx:1.25 — the pin moved to the overlay that owns the stage step."
exit 0
