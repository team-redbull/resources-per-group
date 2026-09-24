{{- define "cluster-owner.configMapName" -}}
{{- default (printf "owner-%s" .Values.cluster) .Values.configMapName -}}
{{- end -}}

{{- define "cluster-owner.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{/* Everything a CRD would have enforced, enforced here instead.
     Each check stops the render, so Argo shows the error and
     nothing reaches the cluster. */}}
{{- define "cluster-owner.validate" -}}

{{- if not .Values.cluster -}}
{{- fail "cluster is required. Set it to this cluster's name, matching its remote-write \"cluster\" label." -}}
{{- end -}}

{{- if not (regexMatch .Values.valuePattern .Values.cluster) -}}
{{- fail (printf "cluster is \"%s\". It must match %s - lowercase letters, digits and hyphens." .Values.cluster .Values.valuePattern) -}}
{{- end -}}

{{- if not (has .Values.type .Values.types) -}}
{{- fail (printf "type is \"%s\". It must be one of: %s." (toString .Values.type) (join ", " .Values.types)) -}}
{{- end -}}

{{- $root := . -}}
{{- range $f := .Values.ownershipFields -}}
{{- $v := index $root.Values.owners $f -}}
{{- if not $v -}}
{{- fail (printf "owners.%s is empty. Set every level, using \"generic\" where it does not apply." $f) -}}
{{- end -}}
{{- if not (regexMatch $root.Values.valuePattern $v) -}}
{{- fail (printf "owners.%s is \"%s\". It must match %s - so \"generic\", never \"Generic\"." $f (toString $v) $root.Values.valuePattern) -}}
{{- end -}}
{{- end -}}

{{- end -}}
