{{/*
Expand the name of the chart.
*/}}
{{- define "shopsphere.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "shopsphere.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label.
*/}}
{{- define "shopsphere.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "shopsphere.labels" -}}
helm.sh/chart: {{ include "shopsphere.chart" . }}
{{ include "shopsphere.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "shopsphere.selectorLabels" -}}
app.kubernetes.io/name: {{ include "shopsphere.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service image.
Repository contains only the service name.
Registry and tag are supplied globally.
*/}}
{{- define "shopsphere.image" -}}
{{- $registry := .root.Values.global.image.registry | trimSuffix "/" -}}
{{- $tag := required "global.image.tag must be specified" .root.Values.global.image.tag -}}
{{- if $registry -}}
{{ printf "%s/%s:%s" $registry .service.image.repository $tag }}
{{- else -}}
{{ printf "%s:%s" .service.image.repository $tag }}
{{- end -}}
{{- end }}