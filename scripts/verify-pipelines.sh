#!/usr/bin/env bash
# Verifies EX288 OpenShift Pipelines lab resources.
# Usage: ./scripts/verify-pipelines.sh [quick|full]
set -euo pipefail

MODE="${1:-quick}"
PROJECT="bookstore-cicd"
PIPELINE="bookstore-build-deploy"

PASS=0
FAIL=0

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "==> Verifying project: ${PROJECT}"
oc project "${PROJECT}" >/dev/null

tkn task list -n "${PROJECT}" | grep -q apply-manifests && pass "Task apply-manifests exists" || fail "Task apply-manifests exists"
tkn task list -n "${PROJECT}" | grep -q update-deployment && pass "Task update-deployment exists" || fail "Task update-deployment exists"
tkn pipeline list -n "${PROJECT}" | grep -q "${PIPELINE}" && pass "Pipeline ${PIPELINE} exists" || fail "Pipeline ${PIPELINE} exists"

oc get triggerbinding bookstore-binding -n "${PROJECT}" >/dev/null 2>&1 && pass "TriggerBinding bookstore-binding exists" || fail "TriggerBinding bookstore-binding exists"
oc get triggertemplate bookstore-template -n "${PROJECT}" >/dev/null 2>&1 && pass "TriggerTemplate bookstore-template exists" || fail "TriggerTemplate bookstore-template exists"
oc get trigger bookstore-trigger -n "${PROJECT}" >/dev/null 2>&1 && pass "Trigger bookstore-trigger exists" || fail "Trigger bookstore-trigger exists"
oc get eventlistener bookstore-listener -n "${PROJECT}" >/dev/null 2>&1 && pass "EventListener bookstore-listener exists" || fail "EventListener bookstore-listener exists"

EL_POD=$(oc get pods -n "${PROJECT}" -l eventlistener=bookstore-listener -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "")
[[ "${EL_POD}" == "Running" ]] && pass "EventListener pod is Running" || fail "EventListener pod is Running (phase=${EL_POD})"

ROUTE=$(oc get route -n "${PROJECT}" -o name 2>/dev/null | grep el-bookstore-listener || true)
[[ -n "${ROUTE}" ]] && pass "EventListener route exists" || fail "EventListener route exists (oc expose svc el-bookstore-listener)"

if [[ "${MODE}" == "full" ]]; then
  LAST_STATUS=$(tkn pipelinerun list -n "${PROJECT}" -o jsonpath='{.items[0].status.conditions[?(@.type=="Succeeded")].status}' 2>/dev/null || echo "")
  [[ "${LAST_STATUS}" == "True" ]] && pass "Latest PipelineRun succeeded" || fail "Latest PipelineRun succeeded (status=${LAST_STATUS})"

  oc get deploy bookstore-api -n "${PROJECT}" >/dev/null 2>&1 && pass "Deployment bookstore-api exists" || fail "Deployment bookstore-api exists"
fi

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
