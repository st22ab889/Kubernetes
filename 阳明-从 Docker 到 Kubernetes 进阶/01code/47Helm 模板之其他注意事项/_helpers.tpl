{{/* ⽣成基本的 labels 标签 */}}
{{- define "mychart.labels" }}
from: helm
data: {{ now | htmlDate }}
chart: {{ .Chart.Name }}
version: {{ .Chart.Version }}
{{- end }}