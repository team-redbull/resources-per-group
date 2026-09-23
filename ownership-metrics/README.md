# ownership-metrics

Runs **one** kube-state-metrics on the MCE hub. It reads `ClusterOwner`
objects and exports one row per cluster:

    kube_cluster_ownership_info{cr_name="cluster-b", type="ClickCluster",
      merkaz="haifa", anaf="infra", mador="platform"} 1

The value is always 1 and means nothing. The **labels** are the payload.

## The registry

One `ClusterOwner` object per cluster, of any kind:

    apiVersion: cluster-owner.io/v1alpha1
    kind: ClusterOwner
    metadata:
      name: cluster-b          # = the cluster's remote-write "cluster" label
    spec:
      type: ClickCluster       # or UPI
      merkaz: haifa
      anaf: infra
      mador: platform

Hosted and UPI clusters are **identical** here. Only `type` differs.

Add a cluster = add a file. Remove one = delete the file; Argo prunes it.
Nothing is written on HostedCluster objects. No cluster-monitoring-config
is ever touched.

## Why an object and not labels or a list

- **Duplicates are impossible.** The object name is the cluster name, and
  Kubernetes will not hold two objects with the same name.
- **The API server validates.** Missing level, unknown type, or "Generic"
  instead of "generic" are all rejected on apply - not dropped silently at
  query time, which is how every earlier bug in this project behaved.
- **It is readable.** `oc get clusterowners` prints Type, Merkaz, Anaf, Mador.
- **Argo owns everything**, one file per cluster, prune included.

## Sync order

The CRD carries `argocd.argoproj.io/sync-wave: "-1"`, so Argo applies it
before any ClusterOwner. If the CRD lives in a different Application from the
objects, sync that one first.

## Traps already hit in the field - all of them silent

1. **RBAC**: needs `customresourcedefinitions` read too. Sign: "forbidden ...
   customresourcedefinitions" in the logs, pod still Ready.
2. **Memory**: 128Mi -> OOMKilled, exit 137, clean startup logs. 512Mi works.
3. **Probes**: v2.10+ serves /livez on 8080 and /readyz on 8081.
4. **Metric name**: `_info` is NOT appended for you. An Info metric must be
   NAMED with `_info` or it produces HELP and TYPE lines and no rows.

## Debug order

    oc -n <ns> get pod <pod> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode} {.status.containerStatuses[0].lastState.terminated.reason}'
    oc -n <ns> logs <pod> --previous
    oc -n <ns> port-forward svc/<svc> 8080:8080
    curl -s localhost:8080/metrics | grep -v '^#'

Then in Observe -> Metrics, on the RIGHT cluster (check `oc whoami
--show-console` against your browser):

    up{namespace="<ns>"}                              # 1 = scraping works
    scrape_samples_scraped{job=~".*ownership.*"}      # 0 = pod serves no rows

## Coverage check

These two should match. If not, a cluster has no ClusterOwner and is
invisible in the dashboard:

    count(kube_cluster_ownership_info)
    count(count by (cluster) (kube_node_info))
