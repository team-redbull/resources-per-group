# Chart B - cluster-owner

Writes **one** ConfigMap describing who owns **this** cluster. Chart A
(`ownership-metrics`) reads it and turns it into a metric row.

    kube_configmap_labels{configmap="owner-cluster-b",
      label_cluster_owner_record="true",
      label_cluster_owner_cluster="cluster-b",
      label_cluster_owner_type="ClickCluster",
      label_cluster_owner_merkaz="haifa",
      label_cluster_owner_anaf="infra",
      label_cluster_owner_mador="platform"} 1

The ConfigMap body is **empty on purpose**. Everything lives in its labels,
because labels are the only part kube-state-metrics can read.

## One release per cluster

**ClickCluster**: deployed on the MCE hub, together with whatever creates the
HostedCluster. The hub ends up with one owner ConfigMap per hosted cluster,
all in the exporter's namespace.

**UPI**: deployed on that UPI cluster, in the exporter's namespace there.

Same chart both times. Only the values differ.

## Values

| value | meaning |
|---|---|
| `cluster` | **required.** This cluster's name. |
| `type` | ClickCluster or UPI. |
| `owners.*` | **required.** Every level. Use `generic` where one does not apply. |
| `configMapName` | optional. Defaults to `owner-<cluster>`. |

## The contract with chart A

Four things must line up, or the exporter lifts nothing and the cluster
disappears from the dashboard **with no error anywhere**:

| | must match |
|---|---|
| namespace | both charts deploy to the SAME namespace |
| `labelPrefix` | chart A's `labelPrefix` |
| `labelSeparator` | chart A's `labelSeparator` |
| `markerKey` | chart A's `markerKey` |
| `ownershipFields` | chart A's `ownershipFields` |

## And one rule outside both charts

`cluster` must equal that cluster's remote-write `cluster` external label.
That string is the join key between the owner record and the node metrics.
If they differ, the dashboard shows owners with nothing attached.

## What is checked before anything deploys

The chart REFUSES TO RENDER, and Argo shows the error, when:

- `cluster` is missing, or breaks `valuePattern`
- `type` is anything but ClickCluster or UPI
- an owner level is empty
- any value breaks the pattern - so `generic` passes, `Generic` does not

That last one matters: silent spelling drift is how one group quietly
becomes two.

## Verify

    oc -n <ns> get cm -l cluster-owner/record=true --show-labels

Then, on that cluster, in Observe -> Metrics:

    kube_configmap_labels{label_cluster_owner_record="true"}

## Note on NOTES.txt

There isn't one, deliberately. A NOTES.txt only prints text after a manual
`helm install`; Argo never shows it. It cannot create anything, but a stale
reference inside it CAN break a sync - which it did, once.
