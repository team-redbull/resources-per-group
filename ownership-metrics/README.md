# Chart A - ownership-metrics (the exporter)

One kube-state-metrics per cluster. **Identical on every cluster**,
ClickCluster and UPI alike. It holds no cluster data.

It reads the owner ConfigMap that **chart B (`cluster-owner`)** creates in the
same namespace, and exports one row:

    kube_cluster_ownership_info{cr_name="cluster-b", type="ClickCluster",
      merkaz="haifa", anaf="infra", mador="platform"} 1

## The contract with chart B

Three values must match **exactly**, or the exporter reads nothing:

| value | must equal chart B's |
|---|---|
| `labelPrefix` | `labelPrefix` |
| `labelSeparator` | `labelSeparator` |
| `ownershipFields` | the keys under `owners` |

And both charts must be deployed to the **same namespace**.

## Requirements on each cluster

1. **User workload monitoring enabled** - this exporter is a user workload,
   so the platform Prometheus will not scrape it.
2. **Remote write from user workload monitoring** to your central store, so
   the row reaches Grafana. That is a different ConfigMap from the platform
   one:

       oc -n openshift-user-workload-monitoring get cm user-workload-monitoring-config

3. The cluster's `cluster` external label must equal the `cluster` value in
   chart B.

## Traps already hit in the field - all of them silent

1. **RBAC**: needs `customresourcedefinitions` read too. Sign: "forbidden ...
   customresourcedefinitions" in the logs, pod still Ready.
2. **Memory**: 128Mi -> OOMKilled, exit 137, clean startup logs. 512Mi works.
3. **Probes**: v2.10+ serves /livez on 8080 and /readyz on 8081.
4. **Metric name**: `_info` is NOT appended for you. An Info metric must be
   NAMED with `_info` or it produces HELP and TYPE lines and no rows.

## Debug order

    oc -n <ns> get cm --show-labels | grep owner-        # chart B did its job?
    oc -n <ns> get pods
    oc -n <ns> port-forward svc/<svc> 8080:8080
    curl -s localhost:8080/metrics | grep -v '^#'        # real rows, not just HELP/TYPE

Then in Observe -> Metrics, on the RIGHT cluster (check `oc whoami
--show-console` against your browser):

    up{namespace="<ns>"}
    scrape_samples_scraped{job=~".*ownership.*"}
