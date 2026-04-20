#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# File: scripts/blue-green-deploy.sh
# Purpose: Execute a Blue-Green deployment on Kubernetes with zero downtime.
#
# HOW IT WORKS:
#   1. Identify which slot (blue/green) is currently LIVE
#   2. Deploy new version to the IDLE slot
#   3. Wait for idle slot to be healthy
#   4. Flip the ingress/service selector to the new slot (instant traffic switch)
#   5. Keep old slot running for 5 minutes (easy rollback)
#   6. Scale down old slot
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
NAMESPACE="production"
APP_NAME="globalmart"
IMAGE="${DOCKER_IMAGE:-project-phoenix-globalmart-api}"
NEW_VERSION="${GIT_COMMIT_SHORT:-latest}"
ROLLBACK_WAIT_SECONDS="${ROLLBACK_WAIT_SECONDS:-300}"   # Keep old slot up after switch
HEALTH_CHECK_RETRIES=20
HEALTH_CHECK_INTERVAL=10

# ── Color codes ───────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log()     { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[✅ SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[⚠ WARNING]${NC} $1"; }
error()   { echo -e "${RED}[❌ ERROR]${NC} $1"; exit 1; }

# ── Step 1: Detect current live slot ─────────────────────────────────────────
log "=== BLUE-GREEN DEPLOY START ==="
log "Image: ${IMAGE}:${NEW_VERSION}"

LIVE_SLOT=$(kubectl get service ${APP_NAME}-service -n ${NAMESPACE} \
  -o jsonpath='{.spec.selector.slot}' 2>/dev/null || echo "blue")

if [[ -z "${LIVE_SLOT}" || ( "${LIVE_SLOT}" != "blue" && "${LIVE_SLOT}" != "green" ) ]]; then
  warning "Service selector slot is missing/invalid. Defaulting live slot to blue for first switch."
  LIVE_SLOT="blue"
fi

if [[ "$LIVE_SLOT" == "blue" ]]; then
  IDLE_SLOT="green"
else
  IDLE_SLOT="blue"
fi

log "Live slot: ${LIVE_SLOT} | Idle slot (deploy target): ${IDLE_SLOT}"

# ── Step 2: Deploy to idle slot ───────────────────────────────────────────────
log "Deploying ${IMAGE}:${NEW_VERSION} to ${IDLE_SLOT} slot..."

# Ensure idle slot has running replicas before waiting for rollout
kubectl scale deployment/${APP_NAME}-${IDLE_SLOT} \
  --replicas=3 \
  --namespace=${NAMESPACE}

kubectl set image deployment/${APP_NAME}-${IDLE_SLOT} \
  ${APP_NAME}=${IMAGE}:${NEW_VERSION} \
  --namespace=${NAMESPACE}

kubectl patch deployment ${APP_NAME}-${IDLE_SLOT} \
  --namespace=${NAMESPACE} \
  --type='json' \
  -p="[{\"op\": \"replace\", \"path\": \"/spec/template/metadata/labels/slot\", \"value\": \"${IDLE_SLOT}\"}]"

# ── Step 3: Wait for idle slot to be healthy ──────────────────────────────────
log "Waiting for ${IDLE_SLOT} slot to be ready..."

kubectl rollout status deployment/${APP_NAME}-${IDLE_SLOT} \
  --namespace=${NAMESPACE} \
  --timeout=300s || error "Deployment to ${IDLE_SLOT} failed! Aborting."

# Health check loop
RETRIES=0
until [[ $RETRIES -ge $HEALTH_CHECK_RETRIES ]]; do
  POD=$(kubectl get pods -n ${NAMESPACE} \
    -l app=${APP_NAME},slot=${IDLE_SLOT} \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

  if [[ -n "$POD" ]]; then
    READY=$(kubectl get pod "$POD" -n ${NAMESPACE} \
      -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
    if [[ "$READY" == "true" ]]; then
      success "${IDLE_SLOT} slot is healthy!"
      break
    fi
  fi

  RETRIES=$((RETRIES + 1))
  log "Health check attempt ${RETRIES}/${HEALTH_CHECK_RETRIES}... waiting ${HEALTH_CHECK_INTERVAL}s"
  sleep $HEALTH_CHECK_INTERVAL
done

if [[ $RETRIES -ge $HEALTH_CHECK_RETRIES ]]; then
  error "${IDLE_SLOT} slot never became healthy! Traffic NOT switched. Old slot ${LIVE_SLOT} still serving."
fi

# ── Step 4: Switch traffic ────────────────────────────────────────────────────
log "Switching traffic from ${LIVE_SLOT} → ${IDLE_SLOT}..."

kubectl patch service ${APP_NAME}-service \
  --namespace=${NAMESPACE} \
  --type='merge' \
  -p="{\"spec\":{\"selector\":{\"app\":\"${APP_NAME}\",\"slot\":\"${IDLE_SLOT}\"}}}"

success "Traffic is now routed to ${IDLE_SLOT} slot (version: ${NEW_VERSION})"

# ── Step 5: Rollback window ───────────────────────────────────────────────────
warning "Keeping ${LIVE_SLOT} slot running for ${ROLLBACK_WAIT_SECONDS}s (rollback window)"
warning "To rollback: kubectl patch service ${APP_NAME}-service -n ${NAMESPACE} --type='json' -p='[{\"op\":\"replace\",\"path\":\"/spec/selector/slot\",\"value\":\"${LIVE_SLOT}\"}]'"

sleep $ROLLBACK_WAIT_SECONDS

# ── Step 6: Scale down old slot ───────────────────────────────────────────────
log "Scaling down old ${LIVE_SLOT} slot..."
kubectl scale deployment/${APP_NAME}-${LIVE_SLOT} \
  --replicas=0 \
  --namespace=${NAMESPACE}

success "=== BLUE-GREEN DEPLOY COMPLETE ==="
success "New version: ${IMAGE}:${NEW_VERSION}"
success "Live slot:   ${IDLE_SLOT}"
success "Old slot:    ${LIVE_SLOT} (scaled to 0)"
