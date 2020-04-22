# Resource quota

View and generate manifest for namespaces [resources quota](https://v1-16.docs.kubernetes.io/docs/tasks/administer-cluster/manage-resources/quota-memory-cpu-namespace/).

* Display of current resources usage, request and limits
* Don't consider default namespaces as default and kube-*
* Clean all the failed pod in order to get and accurate quota

## Run

Currently we only support cpu and memory limits

```
cd resource-quota
./usage.sh
```

## Example output

Show aggregate resource requests and limits. This is the same information
displayed by `kubectl describe nodes` but in a easier to view format.

```
NAMESPACE      used.cpu  requests.cpu  limits.cpu  used.mem  requests.mem  limits.mem
n1             2         10            40          57        64            256
n2             10        670           2300        1459      2768          5376
n3             5         2305          5300        1728      5676          11552
n4             4         250           8520        2617      1992          11008
n5             1         735           2632        2149      2756          6352
n6             2         275           1760        576       1464          4608
```

## Manifests output example
Also creates que manifests files in order to apply namespaces resource-quota.

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: mem-cpu-quota-<namespace>
  namespace: <namespace>
spec:
  hard:
    requests.cpu: 130m
    limits.cpu: 520m
    requests.memory: 166Mi
    limits.memory: 332Mi
```

## Apply resource quota
You need to select the desired manifest in order to apply or apply the entire folder.

### single manifest
```
kubectl apply -f <namespape>-mem-cpu-quota.yaml
```

### all manifest
```
kubectl apply -f k8s-namespaces-quota
```

with :heart: underworld