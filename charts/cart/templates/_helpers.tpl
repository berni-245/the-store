{{/* Common labels for the cart chart */}}
{{- define "cart.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: cart
app.kubernetes.io/instance: cart
app.kubernetes.io/component: service
app.kubernetes.io/owner: retail-store-sample
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Selector labels (stable across releases) */}}
{{- define "cart.selectorLabels" -}}
app.kubernetes.io/name: cart
app.kubernetes.io/instance: cart
app.kubernetes.io/component: service
app.kubernetes.io/owner: retail-store-sample
{{- end -}}
