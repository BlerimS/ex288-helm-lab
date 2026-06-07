# Solution Guide — EX288 Helm Multi-Container Lab

> **Instructor use only.** Do not distribute to students before the lab.

---

## Setup

```bash
cd ~/ex288-helm-lab
./scripts/setup-lab.sh
```

`setup-lab.sh` creates both projects and replaces `REPLACE_CLUSTER_DOMAIN` in `charts/bookstore/devel.yaml` and `prod.yaml`.

---

## Development deployment

```bash
oc project bookstore-devel
cd ~/ex288-helm-lab/charts/bookstore

helm upgrade --install bookstore -f devel.yaml .
```

### Verify devel

```bash
cd ~/ex288-helm-lab
./scripts/verify.sh devel
curl http://$(oc get route bookstore-web -n bookstore-devel -o jsonpath='{.spec.host}')/api/books
```

---

## Production deployment

```bash
oc project bookstore-prod
cd ~/ex288-helm-lab/charts/bookstore

helm upgrade --install bookstore -f prod.yaml .
```

### Verify prod

```bash
cd ~/ex288-helm-lab
./scripts/verify.sh prod
curl -k https://$(oc get route bookstore-web -n bookstore-prod -o jsonpath='{.spec.host}')/api/books
```

---

## Expected resource output

```bash
oc get deploy bookstore-web -o jsonpath='{.spec.template.spec.containers[0].resources}' | jq .
oc get deploy bookstore-api -o jsonpath='{.spec.template.spec.containers[0].resources}' | jq .
```

---

## Uninstall

```bash
helm uninstall bookstore -n bookstore-devel
helm uninstall bookstore -n bookstore-prod
```
