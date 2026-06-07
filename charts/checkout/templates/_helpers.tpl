{{/* Common labels for the checkout chart */}}
{{- define "checkout.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: checkout
app.kubernetes.io/instance: checkout
app.kubernetes.io/component: service
app.kubernetes.io/owner: retail-store-sample
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Selector labels (stable across releases) */}}
{{- define "checkout.selectorLabels" -}}
app.kubernetes.io/name: checkout
app.kubernetes.io/instance: checkout
app.kubernetes.io/component: service
app.kubernetes.io/owner: retail-store-sample
{{- end -}}
