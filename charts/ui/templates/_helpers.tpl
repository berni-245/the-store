{{/* Common labels for the ui chart */}}
{{- define "ui.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: ui
app.kubernetes.io/instance: ui
app.kubernetes.io/component: service
app.kubernetes.io/owner: retail-store-sample
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Selector labels (stable across releases) */}}
{{- define "ui.selectorLabels" -}}
app.kubernetes.io/name: ui
app.kubernetes.io/instance: ui
app.kubernetes.io/component: service
app.kubernetes.io/owner: retail-store-sample
{{- end -}}
