# EX288 Practice Labs

Practice labs for **Red Hat EX288** — Helm deployments and OpenShift Pipelines (Tekton).

| Lab | Focus | Student guide |
|-----|--------|----------------|
| **Lab 1** | Multi-container app + Helm | [EXERCISE.md](EXERCISE.md) |
| **Lab 2** | Pipeline YAML + triggers | [EXERCISE-PIPELINES.md](EXERCISE-PIPELINES.md) |

## Quick start (on OpenShift lab VM)

```bash
# Copy this directory to the lab node, then:
cd ~/ex288-helm-lab
chmod +x scripts/*.sh

oc login -u developer -p developer   # or your lab credentials
./scripts/setup-lab.sh
```

- **Lab 1 (Helm):** [EXERCISE.md](EXERCISE.md) — instructors: [SOLUTION.md](SOLUTION.md)
- **Lab 2 (Pipelines):** [EXERCISE-PIPELINES.md](EXERCISE-PIPELINES.md) — instructors: [SOLUTION-PIPELINES.md](SOLUTION-PIPELINES.md)

## What you practice

### Lab 1 — Helm

| Skill | devel | prod |
|-------|-------|------|
| Helm `upgrade --install -f devel.yaml .` | ✓ | ✓ |
| Environment values files | ✓ | ✓ |
| Resource requests/limits | ✓ | ✓ |
| Custom labels | ✓ | ✓ |
| Image repository override | ✓ | — |
| OpenShift Route + TLS edge | — | ✓ |

### Lab 2 — Pipelines

| Skill | Covered |
|-------|---------|
| Tekton Tasks & Pipeline YAML | ✓ |
| `tkn pipeline start` / PipelineRun | ✓ |
| TriggerBinding & TriggerTemplate | ✓ |
| Trigger & EventListener | ✓ |
| Webhook → automated PipelineRun | ✓ |

## Layout

```
charts/bookstore/       Lab 1 — Helm chart + values files
pipelines/              Lab 2 — pipeline.yaml, tasks, triggers, app-source
scripts/                setup & verify scripts for both labs
EXERCISE.md             Lab 1 student guide
EXERCISE-PIPELINES.md   Lab 2 student guide
SOLUTION.md             Lab 1 instructor guide
SOLUTION-PIPELINES.md   Lab 2 instructor guide
```

## Deploy commands

```bash
cd charts/bookstore
oc project bookstore-devel
helm upgrade --install bookstore -f devel.yaml .

oc project bookstore-prod
helm upgrade --install bookstore -f prod.yaml .
```

## Registry note

Images pull from `registry.redhat.io`. If pulls fail, log in with your Red Hat account or use lab-provided pull secrets:

```bash
podman login registry.redhat.io
# or ensure cluster has redhat-registry secret linked to namespace
```
