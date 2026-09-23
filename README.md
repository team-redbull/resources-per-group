# ownership-metrics

Runs **one** kube-state-metrics on the MCE hub. It reads the owner
ConfigMaps this chart generates, and exports one row per cluster:

    kube_cluster_ownership_info{cr_name="cluster-b", type="ClickCluster",
      merkaz="haifa", anaf="infra", mador="platform"} 1

The value is always 1 and means nothing. The **labels** are the payload.

## The registry

The `clusters` list in `values.yaml` - normally set from the Argo
Application - is the single source of truth:

    clusters:
      - cluster: cluster-b        # = that cluster's remote-write "cluster" label
        type: ClickCluster        # or UPI
        merkaz: haifa
        anaf: infra
        mador: platform

Hosted and UPI clusters are **identical** here. Only `type` differs.

Add a cluster = add four lines. Remove it = delete them, and Argo prunes
its ConfigMap and its metric row.

Nothing is written on HostedCluster objects. No cluster-monitoring-config
is touched. No CRD is installed.

## Why no CRD

A CRD would validate at the API server, but it is cluster-wide, usually
needs cluster-admin, and `oc delete crd` wipes every object of that kind at
once. The Helm guards below give the same **loud, early** failure without
any of that.

## What is checked before anything deploys

The chart REFUSES TO RENDER, and Argo shows the error, when:

- the clusters list is empty
- a `cluster` name is missing, or appears twice
- `type` is anything but ClickCluster or UPI
- an ownership level is empty
- any value breaks `valuePattern` - so "generic" passes, "Generic" does not

That last one matters: silent spelling drift is how one group quietly
becomes two.

## Rules

1. `cluster` must be **unique across all clusters**, both types.
2. It must equal that cluster's remote-write `cluster` external label.
3. Use `generic` for a level that does not apply.

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

These two should match. If not, a cluster is missing from the list and is
invisible in the dashboard:

    count(kube_cluster_ownership_info)
    count(count by (cluster) (kube_node_info))
