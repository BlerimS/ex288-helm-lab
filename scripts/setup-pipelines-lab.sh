#!/usr/bin/env bash
# Creates project and RBAC for the EX288 OpenShift Pipelines lab.
set -euo pipefail

PROJECT="bookstore-cicd"

echo "==> Creating project ${PROJECT}"
oc new-project "${PROJECT}" --display-name="Bookstore CI/CD" 2>/dev/null || oc project "${PROJECT}"

echo "==> Checking pipeline service account"
if ! oc get sa pipeline -n "${PROJECT}" >/dev/null 2>&1; then
  echo "WARNING: ServiceAccount 'pipeline' not found in ${PROJECT}."
  echo "         OpenShift Pipelines usually creates it when the operator is installed."
  echo "         Ask your instructor or run: oc create sa pipeline -n ${PROJECT}"
fi

echo "==> Granting pipeline SA permissions to deploy in this project"
oc policy add-role-to-user edit "system:serviceaccount:${PROJECT}:pipeline" -n "${PROJECT}" 2>/dev/null || true

CLUSTER_DOMAIN=$(oc get ingresses.config/cluster -o jsonpath='{.spec.domain}' 2>/dev/null || true)
echo ""
if [[ -n "${CLUSTER_DOMAIN}" ]]; then
  echo "Cluster apps domain: ${CLUSTER_DOMAIN}"
  echo "After exposing the EventListener, route host will look like:"
  echo "  el-bookstore-listener-${PROJECT}.${CLUSTER_DOMAIN}"
else
  echo "Could not detect cluster domain (ok for offline prep)."
fi

echo ""
echo "Git source options for Task 4:"
echo "  1. Push pipelines/app-source/ to your lab Git server and use that URL"
echo "  2. Use a fork of openshift/pipelines-vote-api (deployment-name must be pipelines-vote-api)"
echo ""
echo "Internal image reference for this lab:"
echo "  image-registry.openshift-image-registry.svc:5000/${PROJECT}/bookstore-api"
echo ""
echo "Setup complete. Continue with EXERCISE-PIPELINES.md Task 2."
