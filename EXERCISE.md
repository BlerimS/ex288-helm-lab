# EX288 Practice Lab: Multi-Container Application with Helm

**Objective:** Deploy a multi-container bookstore application to two OpenShift projects using Helm, with environment-specific configuration.

**Estimated time:** 45–60 minutes  
**Exam alignment:** Deploy multi-container applications, Helm charts, projects, resources, labels, routes/TLS

---

## Scenario

Your team maintains a bookstore application composed of two containers:

| Component | Role |
|-----------|------|
| **web** | Nginx front end; proxies `/api` to the API service |
| **api** | Simple HTTP API returning JSON book data |

You must package and deploy this stack with **Helm** into:

- `bookstore-devel` — development (custom image registry, labels, resource limits)
- `bookstore-prod` — production (labels, resource limits, **TLS** route)

All work is done from the cluster node as user **`student`** (or your lab user). Use `oc` and `helm`.

---

## Lab prerequisites

On the OpenShift lab system you should have:

- Logged in: `oc login -u developer -p developer` (or your lab credentials)
- Helm 3 installed (`helm version`)
- This exercise copied to `~/ex288-helm-lab` (or `/home/student/ex288-helm-lab`)

```bash
cd ~/ex288-helm-lab
chmod +x scripts/*.sh
```

---

## Provided artifacts

```
ex288-helm-lab/
├── EXERCISE.md              # This file
├── charts/bookstore/        # Helm chart (complete — do not modify templates for grading)
│   ├── devel.yaml           # Development values (resources, labels, image repos)
│   └── prod.yaml            # Production values (resources, labels, TLS)
└── scripts/
    ├── setup-lab.sh         # Creates projects + patches cluster domain in values files
    └── verify.sh            # Checks your deployment
```

---

## Task 1 — Prepare projects (5 min)

Create two OpenShift projects:

| Project | Display name |
|---------|----------------|
| `bookstore-devel` | Bookstore Development |
| `bookstore-prod` | Bookstore Production |

**Requirements:**

- Both projects must exist and you must be able to deploy into them.
- Use `oc new-project` or `oc create project`.

**Hint:** Run the helper script if your instructor allows it:

```bash
./scripts/setup-lab.sh
```

---

## Task 2 — Review the Helm chart (5 min)

Inspect the chart under `charts/bookstore/`:

```bash
cd charts/bookstore
helm show values .
cat devel.yaml
helm template bookstore . -f devel.yaml
```

Understand which values control:

- `image.repository` / `image.tag` (per component: `web`, `api`)
- `resources` (requests and limits per component)
- `labels` (applied to all resources)
- `route.host`, `route.tls.enabled`, `route.tls.termination`

---

## Task 3 — Deploy to development (15 min)

Deploy release name **`bookstore`** into project **`bookstore-devel`** using **`devel.yaml`** only.

All development settings (resources, labels, image repositories, route host, TLS off) are defined in `charts/bookstore/devel.yaml`. Review that file before deploying.

### Required configuration for devel (in `devel.yaml`)

| Parameter | Required value |
|-----------|----------------|
| **Image repository** | `registry.redhat.io/rhel9/httpd-24` (web) and `registry.redhat.io/ubi9/python-311` (api) |
| **Labels** | `app.kubernetes.io/part-of: bookstore`, `environment: development` |
| **Resources — web** | requests: `cpu: 50m`, `memory: 64Mi`; limits: `cpu: 100m`, `memory: 128Mi` |
| **Resources — api** | requests: `cpu: 25m`, `memory: 32Mi`; limits: `cpu: 50m`, `memory: 64Mi` |
| **Route** | HTTP only (TLS disabled); hostname `bookstore-devel.apps.<cluster-domain>` |

Run `./scripts/setup-lab.sh` first — it patches `REPLACE_CLUSTER_DOMAIN` in the values files. Or set the domain manually:

```bash
oc get ingresses.config/cluster -o jsonpath='{.spec.domain}'
```

### Deploy command

```bash
oc project bookstore-devel
cd ~/ex288-helm-lab/charts/bookstore

helm upgrade --install bookstore -f devel.yaml .
```

### Verify devel

```bash
oc get pods -l app.kubernetes.io/instance=bookstore
oc get route bookstore-web
curl -k http://$(oc get route bookstore-web -o jsonpath='{.spec.host}')/
curl -k http://$(oc get route bookstore-web -o jsonpath='{.spec.host}')/api/books
```

Expected: HTTP 200, JSON book list from `/api/books`.

---

## Task 4 — Deploy to production (20 min)

Deploy release name **`bookstore`** into project **`bookstore-prod`** using **`prod.yaml`** only.

All production settings (resources, labels, TLS, route host) are defined in `charts/bookstore/prod.yaml`.

### Required configuration for prod (in `prod.yaml`)

| Parameter | Required value |
|-----------|----------------|
| **Labels** | `app.kubernetes.io/part-of: bookstore`, `environment: production` |
| **Resources — web** | requests: `cpu: 100m`, `memory: 128Mi`; limits: `cpu: 250m`, `memory: 256Mi` |
| **Resources — api** | requests: `cpu: 50m`, `memory: 64Mi`; limits: `cpu: 100m`, `memory: 128Mi` |
| **TLS** | Edge termination enabled (`route.tls.enabled: true`, `route.tls.termination: edge`) |
| **Route host** | `bookstore.apps.<cluster-domain>` |

Production image repositories are set in `prod.yaml` (both components use `registry.redhat.io/rhel9/httpd-24`).

### Deploy command

```bash
oc project bookstore-prod
cd ~/ex288-helm-lab/charts/bookstore

helm upgrade --install bookstore -f prod.yaml .
```

### Verify prod

```bash
oc project bookstore-prod
oc get route bookstore-web -o yaml | grep -A5 tls
curl -k https://$(oc get route bookstore-web -o jsonpath='{.spec.host}')/api/books
```

Expected: Route shows TLS edge termination; HTTPS endpoint returns JSON.

---

## Task 5 — Self-check (5 min)

Run the verification script from each project context:

```bash
./scripts/verify.sh devel
./scripts/verify.sh prod
```

Both should report **PASS** for all checks.

---

## Grading checklist (instructor / self-assessment)

| # | Criterion | devel | prod |
|---|-----------|-------|------|
| 1 | Helm release `bookstore` installed | ☐ | ☐ |
| 2 | Two running pods (web + api) | ☐ | ☐ |
| 3 | Correct labels on Deployments | ☐ | ☐ |
| 4 | Resource requests/limits match spec | ☐ | ☐ |
| 5 | Custom image repositories (devel only) | ☐ | — |
| 6 | Route reachable | ☐ | ☐ |
| 7 | TLS edge termination | — | ☐ |

---

## Troubleshooting

| Symptom | Check |
|---------|--------|
| `ImagePullBackOff` | Image name/pull secret; devel uses `registry.redhat.io` — ensure Red Hat registry login if required |
| Route not found | Release name and chart create route `bookstore-web` |
| 502 from `/api` | API pod not ready; `oc logs deploy/bookstore-api` |
| Helm permission denied | `oc project` set correctly; user has `edit` role |

---

## Clean up

```bash
helm uninstall bookstore -n bookstore-devel
helm uninstall bookstore -n bookstore-prod
oc delete project bookstore-devel bookstore-prod
```

---

## Reference: useful commands

```bash
# Helm
helm list -A
helm get values bookstore -n bookstore-devel
helm history bookstore -n bookstore-prod

# OpenShift
oc get all -l app.kubernetes.io/instance=bookstore
oc describe deploy bookstore-web
oc get route,ingress
```

Good luck — this mirrors the style of EX288 tasks: read requirements, parameterize Helm, deploy per environment, verify with `oc` and HTTP checks.
