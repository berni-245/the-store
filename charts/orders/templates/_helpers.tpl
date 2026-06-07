{{/* Common labels for the orders chart */}}
{{- define "orders.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: orders
app.kubernetes.io/instance: orders
app.kubernetes.io/component: service
app.kubernetes.io/owner: retail-store-sample
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Selector labels (stable across releases) */}}
{{- define "orders.selectorLabels" -}}
app.kubernetes.io/name: orders
app.kubernetes.io/instance: orders
app.kubernetes.io/component: service
app.kubernetes.io/owner: retail-store-sample
{{- end -}}
