# ownership-metrics

Exports `res-owner.io` ownership labels from `HostedCluster` objects
as a Prometheus metric, so Grafana can group cluster usage by
**merkaz**, **anaf** and **mador**.

## The problem it solves

Prometheus cannot see labels on a custom resource.
This chart runs a small, read-only `kube-state-metrics` that reads
`HostedCluster` objects and exports their ownership labels.

## What you edit

Only `values.yaml`.

| Value | Meaning |
|---|---|
| `labelPrefix` | The prefix on your HostedCluster labels. |
| `ownershipFields` | Your hierarchy levels, in order. |
| `metric.prefix` / `metric.name` | The exported metric name. |
| `image.repository` | Point this at your internal mirror if disconnected. |

Adding a level is one line in `ownershipFields`. Everything follows.

## Install

    helm install ownership-metrics ./ownership-metrics \
      -n cluster-ownership-metrics --create-namespace

Or via Argo, using `apps/ownership-metrics.yaml`.

## Prerequisite

User workload monitoring must be on. This chart does NOT manage it,
on purpose: that ConfigMap usually holds other settings that Argo
would overwrite.

    oc -n openshift-monitoring get cm cluster-monitoring-config -o yaml

If missing, add `enableUserWorkload: true` under `config.yaml`.

## Verify

    oc -n cluster-ownership-metrics port-forward svc/ownership-metrics 8080:8080
    curl -s localhost:8080/metrics | grep hostedcluster

Expect:

    kube_hostedcluster_ownership_info{cr_name="cluster-b",cr_namespace="hcp",
      merkaz="haifa",anaf="infra",mador="platform"} 1

Then in the console: **Observe -> Metrics**.

## Label a cluster

    oc label hostedcluster cluster-b -n hcp \
      res-owner.io/merkaz=haifa \
      res-owner.io/anaf=infra \
      res-owner.io/mador=platform

## Example query

RAM used per mador, joined on the cluster name:

    sum by (merkaz, anaf, mador) (
      sum by (cluster) (container_memory_working_set_bytes{container!=""})
      * on (cluster) group_left(merkaz, anaf, mador)
      label_replace(kube_hostedcluster_ownership_info,
                    "cluster", "$1", "cr_name", "(.*)")
    )

Grafana must point at the **Thanos Querier**, not at Prometheus.
Your metric lives in user workload monitoring; usage metrics live in
platform monitoring. Only Thanos Querier sees both.

    https://thanos-querier.openshift-monitoring.svc:9091
