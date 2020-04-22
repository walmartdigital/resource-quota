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

```console
NAMESPACE          pod.qty  used.cpu  requests.cpu  limits.cpu  used.mem  requests.mem  limits.mem
n1                 3        3         60            600         67        192           384
n2                 1        0         150           150         0         256           256
n3                 10       45        500           2600        1517      2160          4096
n4                 26       263       1625          4500        1813      5366          10988
n5                 13       47        460           9920        2734      2792          12864
n6                 12       469       830           5470        2202      3052          6800
n7                 6        17        225           1530        564       1248          3936
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