# Solution Guide — EX288 OpenShift Pipelines Lab

> **Instructor use only.** Do not distribute to students before the lab.

---

## Setup

```bash
cd ~/ex288-helm-lab
./scripts/setup-pipelines-lab.sh
oc project bookstore-cicd
```

---

## Task 2 — Tasks

```bash
cd ~/ex288-helm-lab/pipelines
oc apply -f tasks/apply-manifests.yaml
oc apply -f tasks/update-deployment.yaml
```

---

## Task 3 — Fixed `pipeline.yaml`

Key fixes:

1. `$(params.git_url)` → `$(params.git-url)`
2. `build-image` add `runAfter: [fetch-repository]`
3. `apply-manifests` add `runAfter: [build-image]`

```yaml
# pipelines/pipeline.yaml (corrected excerpts)
    - name: fetch-repository
      ...
      params:
        - name: URL
          value: $(params.git-url)
    - name: build-image
      ...
      runAfter:
        - fetch-repository
    - name: apply-manifests
      ...
      runAfter:
        - build-image
```

```bash
oc apply -f pipeline.yaml
```

---

## Task 4 — Manual pipeline run

```bash
tkn pipeline start bookstore-build-deploy \
  --serviceaccount pipeline \
  -w name=shared-workspace,volumeClaimTemplateFile=workspace-template.yaml \
  -p deployment-name=bookstore-api \
  -p git-url=https://YOUR-GIT-SERVER/bookstore-api.git \
  -p git-revision=main \
  -p IMAGE=image-registry.openshift-image-registry.svc:5000/bookstore-cicd/bookstore-api \
  --showlog
```

---

## Task 5–6 — Fixed trigger resources

### triggerbinding.yaml

```yaml
    - name: git-repo-url
      value: $(body.repository.url)
```

### triggertemplate.yaml

```yaml
        pipelineRef:
          name: bookstore-build-deploy
        params:
          ...
          - name: IMAGE
            value: image-registry.openshift-image-registry.svc:5000/bookstore-cicd/bookstore-api
```

### trigger.yaml

```yaml
  bindings:
    - ref: bookstore-binding
  template:
    ref: bookstore-template
```

### eventlistener.yaml

```yaml
  triggers:
    - triggerRef: bookstore-trigger
```

Apply all:

```bash
oc apply -f triggers/triggerbinding.yaml
oc apply -f triggers/triggertemplate.yaml
oc apply -f triggers/trigger.yaml
oc apply -f triggers/eventlistener.yaml
oc expose svc el-bookstore-listener
```

---

## Task 7 — Test webhook

```bash
ROUTE=$(oc get route el-bookstore-listener -o jsonpath='{.spec.host}')
curl -X POST "http://${ROUTE}" \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -d @triggers/webhook-payload-sample.json

tkn pipelinerun list
```

---

## Verify

```bash
./scripts/verify-pipelines.sh full
```

---

## Uninstall

```bash
oc delete project bookstore-cicd
```
