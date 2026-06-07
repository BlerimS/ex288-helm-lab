#!/usr/bin/env bash
# Verifies bookstore Helm deployment for devel or prod.
# Usage: ./scripts/verify.sh devel|prod
set -euo pipefail

ENV="${1:-}"
if [[ "${ENV}" != "devel" && "${ENV}" != "prod" ]]; then
  echo "Usage: $0 devel|prod"
  exit 1
fi

PROJECT="bookstore-${ENV}"
EXPECTED_ENV="development"
[[ "${ENV}" == "prod" ]] && EXPECTED_ENV="production"

PASS=0
FAIL=0

pass() {
  echo "[PASS] $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "[FAIL] $1"
  FAIL=$((FAIL + 1))
}

echo "==> Verifying project: ${PROJECT}"
oc project "${PROJECT}" >/dev/null

if helm status bookstore -n "${PROJECT}" >/dev/null 2>&1; then pass "Helm release 'bookstore' exists"; else fail "Helm release 'bookstore' exists"; fi
if oc get deploy bookstore-web -n "${PROJECT}" >/dev/null 2>&1; then pass "Deployment bookstore-web exists"; else fail "Deployment bookstore-web exists"; fi
if oc get deploy bookstore-api -n "${PROJECT}" >/dev/null 2>&1; then pass "Deployment bookstore-api exists"; else fail "Deployment bookstore-api exists"; fi

WEB_PHASE=$(oc get pods -l app.kubernetes.io/component=web -o jsonpath='{.items[0].status.phase}' -n "${PROJECT}" 2>/dev/null || echo "")
[[ "${WEB_PHASE}" == "Running" ]] && pass "Web pod is Running" || fail "Web pod is Running (phase=${WEB_PHASE})"

API_PHASE=$(oc get pods -l app.kubernetes.io/component=api -o jsonpath='{.items[0].status.phase}' -n "${PROJECT}" 2>/dev/null || echo "")
[[ "${API_PHASE}" == "Running" ]] && pass "API pod is Running" || fail "API pod is Running (phase=${API_PHASE})"

LABEL_ENV=$(oc get deploy bookstore-web -o jsonpath='{.metadata.labels.environment}' -n "${PROJECT}" 2>/dev/null || echo "")
[[ "${LABEL_ENV}" == "${EXPECTED_ENV}" ]] && pass "Label environment=${EXPECTED_ENV}" || fail "Label environment=${EXPECTED_ENV} (got ${LABEL_ENV})"

LABEL_PART=$(oc get deploy bookstore-web -o jsonpath='{.metadata.labels.app\.kubernetes\.io/part-of}' -n "${PROJECT}" 2>/dev/null || echo "")
[[ "${LABEL_PART}" == "bookstore" ]] && pass "Label app.kubernetes.io/part-of=bookstore" || fail "Label app.kubernetes.io/part-of=bookstore"

if [[ "${ENV}" == "devel" ]]; then
  WEB_IMG=$(oc get deploy bookstore-web -o jsonpath='{.spec.template.spec.containers[0].image}' -n "${PROJECT}")
  [[ "${WEB_IMG}" == *"registry.redhat.io/rhel9/httpd-24"* ]] && pass "Web image is rhel9/httpd-24" || fail "Web image is rhel9/httpd-24 (got ${WEB_IMG})"

  API_IMG=$(oc get deploy bookstore-api -o jsonpath='{.spec.template.spec.containers[0].image}' -n "${PROJECT}")
  [[ "${API_IMG}" == *"registry.redhat.io/ubi9/python-311"* ]] && pass "API image is ubi9/python-311" || fail "API image is ubi9/python-311 (got ${API_IMG})"

  TLS_TERM=$(oc get route bookstore-web -o jsonpath='{.spec.tls.termination}' -n "${PROJECT}" 2>/dev/null || echo "")
  [[ -z "${TLS_TERM}" ]] && pass "Route TLS is disabled" || fail "Route TLS is disabled (termination=${TLS_TERM})"

  WEB_CPU=$(oc get deploy bookstore-web -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' -n "${PROJECT}")
  [[ "${WEB_CPU}" == "100m" ]] && pass "Web CPU limit is 100m" || fail "Web CPU limit is 100m (got ${WEB_CPU})"
else
  TLS_TERM=$(oc get route bookstore-web -o jsonpath='{.spec.tls.termination}' -n "${PROJECT}" 2>/dev/null || echo "")
  [[ "${TLS_TERM}" == "edge" ]] && pass "Route TLS edge termination" || fail "Route TLS edge termination (got ${TLS_TERM})"

  WEB_CPU=$(oc get deploy bookstore-web -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' -n "${PROJECT}")
  [[ "${WEB_CPU}" == "250m" ]] && pass "Web CPU limit is 250m" || fail "Web CPU limit is 250m (got ${WEB_CPU})"
fi

ROUTE_HOST=$(oc get route bookstore-web -o jsonpath='{.spec.host}' -n "${PROJECT}" 2>/dev/null || echo "")
if [[ -n "${ROUTE_HOST}" ]]; then
  if [[ "${ENV}" == "prod" ]]; then
    if curl -sk "https://${ROUTE_HOST}/api/books" | grep -q '"books"'; then
      pass "HTTPS /api/books returns JSON"
    else
      fail "HTTPS /api/books returns JSON"
    fi
  else
    if curl -s "http://${ROUTE_HOST}/api/books" | grep -q '"books"'; then
      pass "HTTP /api/books returns JSON"
    else
      fail "HTTP /api/books returns JSON"
    fi
  fi
else
  fail "Route bookstore-web has a host"
fi

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
