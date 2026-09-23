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
{{/* The CRD does the validating now: required levels, allowed types,
     and the value pattern are all enforced by the API server. */}}
