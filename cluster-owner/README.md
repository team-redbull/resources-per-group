# Chart B - cluster-owner

Writes **one** ConfigMap describing who owns **this** cluster. Chart A
(`ownership-metrics`) reads it and turns it into a metric row.

    kube_cluster_ownership_info{cr_name="upi-prod-1", type="UPI",
      merkaz="haifa", anaf="generic", mador="security"} 1

The ConfigMap has an empty body. All the data is in its **labels**, because
that is what kube-state-metrics can read.

## Delivery differs by cluster type

**UPI**: its own Argo Application, one per cluster. See
`apps/cluster-owner-upi-prod-1.yaml`.

**ClickCluster**: created together with the cluster, in whatever provisions
it. The chart is the same - only the values change:

    cluster: cluster-b
    type: ClickCluster

## The contract with chart A

Four things must line up, or the exporter reads nothing and the cluster
disappears from the dashboard **with no error anywhere**:

| | must match |
|---|---|
| namespace | both charts deploy to the SAME namespace |
| `labelPrefix` | chart A's `labelPrefix` |
| `labelSeparator` | chart A's `labelSeparator` |
| `ownershipFields` | chart A's `ownershipFields` |

## What is checked before anything deploys

The chart REFUSES TO RENDER, and Argo shows the error, when:

- `cluster` is missing, or breaks the value pattern
- `type` is anything but ClickCluster or UPI
- an owner level is empty
- any value breaks the pattern - so "generic" passes, "Generic" does not

That last one matters: silent spelling drift is how one group quietly
becomes two.

## Rules

1. `cluster` must be **unique across all clusters**, both types.
2. It must equal this cluster's remote-write `cluster` external label.
3. Use `generic` for a level that does not apply.

## Verify

    oc -n <ns> get cm --show-labels | grep owner-
