{{/*
Expand the name of the chart.
*/}}
{{- define "eas-app-v3-child.name" -}}
{{ .Chart.Name }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "eas-app-v3-child.fullname" -}}
{{ printf "%s-%s" .Release.Name .Chart.Name }}
{{- end }}

{{/*
Create chart label
*/}}
{{- define "eas-app-v3-child.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "eas-app-v3-child.labels" -}}
app.kubernetes.io/name: {{ include "eas-app-v3-child.name" . }}
helm.sh/chart: {{ include "eas-app-v3-child.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
