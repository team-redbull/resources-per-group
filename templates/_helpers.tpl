{{- define "ownership-metrics.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ownership-metrics.fullname" -}}
{{- $name := include "ownership-metrics.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "ownership-metrics.labels" -}}
app.kubernetes.io/name: {{ include "ownership-metrics.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "ownership-metrics.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ownership-metrics.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* Stop bad input before it becomes a silent empty dashboard. */}}
{{/* Without a CRD, THIS is what makes bad input fail loudly.
     Every check below stops the render, so Argo shows an error and
     nothing reaches the cluster. */}}
{{- define "ownership-metrics.validate" -}}
{{- if not .Values.clusters -}}
{{- fail "clusters list is empty. Add one entry per cluster." -}}
{{- end -}}
{{- $root := . -}}
{{- $seen := dict -}}
{{- range $i, $c := .Values.clusters -}}

{{- if not $c.cluster -}}
{{- fail (printf "clusters[%d]: \"cluster\" is required." $i) -}}
{{- end -}}

{{- if hasKey $seen $c.cluster -}}
{{- fail (printf "clusters: \"%s\" appears twice. Cluster names must be unique." $c.cluster) -}}
{{- end -}}
{{- $_ := set $seen $c.cluster true -}}

{{- if not (regexMatch $root.Values.valuePattern $c.cluster) -}}
{{- fail (printf "clusters[%s]: name must match %s (lowercase letters, digits, hyphens)." $c.cluster $root.Values.valuePattern) -}}
{{- end -}}

{{- if not (has $c.type $root.Values.types) -}}
{{- fail (printf "clusters[%s]: type is \"%s\". Must be one of: %s." $c.cluster (toString $c.type) (join ", " $root.Values.types)) -}}
{{- end -}}

{{- range $f := $root.Values.ownershipFields -}}
{{- $v := index $c $f -}}
{{- if not $v -}}
{{- fail (printf "clusters[%s]: %s is empty. Set every level, using \"generic\" where it does not apply." $c.cluster $f) -}}
{{- end -}}
{{- if not (regexMatch $root.Values.valuePattern $v) -}}
{{- fail (printf "clusters[%s]: %s is \"%s\". Must match %s - so \"generic\", never \"Generic\"." $c.cluster $f (toString $v) $root.Values.valuePattern) -}}
{{- end -}}
{{- end -}}

{{- end -}}
{{- end -}}
