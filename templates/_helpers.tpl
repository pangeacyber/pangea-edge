{{/*
Default Selector labels
*/}}
{{- define "defaultSelectorLabels" -}}
{{- dict
    "app.kubernetes.io/name" (include "pangea-edge.name" .)
    "app.kubernetes.io/instance" .Release.Name
    "app.kubernetes.io/managed-by" "helm"
| toYaml
-}}
{{- end -}}

{{/*
Default labels
*/}}
{{- define "defaultLabels" -}}
{{-
  merge
    (dict "helm.sh/chart" (include "pangea-edge.chart" .))
    (fromYaml (include "defaultSelectorLabels" .))
| toYaml
-}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "pangea-edge.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pangea-edge.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "pangea-edge.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Pangea CSP
*/}}
{{- define "pangea-edge.csp" -}}
{{ required "Split is required" (index (regexSplit "\\." (required "'common.pangeaDomain' is required" .Values.common.pangeaDomain) -1) 0) }}
{{- end}}

{{/*
Pangea Region
*/}}
{{- define "pangea-edge.region" -}}
{{ required "Split is required" (index (regexSplit "\\." (required "'common.pangeaDomain' is required" .Values.common.pangeaDomain) -1) 1) }}
{{- end}}

{{/*
Convert seconds to a cron expression.
*/}}
{{- define "chart.secondsToCron" -}}
{{- $minutes := div . 60 -}}
{{- printf "*/%d * * * *" $minutes -}}
{{- end -}}

{{/*
Metrics volume claim name
*/}}
{{- define "pangea-edge.claim" -}}
{{- if .Values.metricsVolume.existingClaim }}
{{- .Values.metricsVolume.existingClaim -}}
{{- else }}
{{- required "If an existing claim is not provided, you must provide a claim name" .Values.metricsVolume.name -}}
{{- end}}
{{- end}}
