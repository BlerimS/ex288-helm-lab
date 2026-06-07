#!/usr/bin/env bash
# Creates OpenShift projects for the EX288 Helm lab.
set -euo pipefail

echo "==> Creating bookstore-devel project"
oc new-project bookstore-devel --display-name="Bookstore Development" 2>/dev/null || \
  oc project bookstore-devel

echo "==> Creating bookstore-prod project"
oc new-project bookstore-prod --display-name="Bookstore Production" 2>/dev/null || \
  oc project bookstore-prod

echo "==> Projects ready:"
oc get projects | grep bookstore || true

CLUSTER_DOMAIN=$(oc get ingresses.config/cluster -o jsonpath='{.spec.domain}' 2>/dev/null || true)
if [[ -n "${CLUSTER_DOMAIN}" ]]; then
  CHART_DIR="$(cd "$(dirname "$0")/../charts/bookstore" && pwd)"
  for VALUES_FILE in devel.yaml prod.yaml; do
    if [[ -f "${CHART_DIR}/${VALUES_FILE}" ]]; then
      sed -i "s/REPLACE_CLUSTER_DOMAIN/${CLUSTER_DOMAIN}/g" "${CHART_DIR}/${VALUES_FILE}"
      echo "==> Patched ${VALUES_FILE} with cluster domain"
    fi
  done
  echo ""
  echo "Cluster apps domain: ${CLUSTER_DOMAIN}"
  echo "  devel route host: bookstore-devel.apps.${CLUSTER_DOMAIN}"
  echo "  prod route host:  bookstore.apps.${CLUSTER_DOMAIN}"
else
  echo "WARNING: Could not detect cluster domain. Edit REPLACE_CLUSTER_DOMAIN in charts/bookstore/devel.yaml and prod.yaml before deploying."
fi

echo ""
echo "Setup complete. Continue with EXERCISE.md Task 3."
