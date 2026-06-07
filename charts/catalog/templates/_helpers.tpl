{{/* Common labels for the catalog chart */}}
{{- define "catalog.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: catalog
app.kubernetes.io/instance: catalog
app.kubernetes.io/component: service
app.kubernetes.io/owner: retail-store-sample
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Selector labels (stable across releases) */}}
{{- define "catalog.selectorLabels" -}}
app.kubernetes.io/name: catalog
app.kubernetes.io/instance: catalog
app.kubernetes.io/component: service
app.kubernetes.io/owner: retail-store-sample
{{- end -}}
