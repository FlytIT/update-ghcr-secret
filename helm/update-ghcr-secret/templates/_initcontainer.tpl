{{- define "ghcr-secret-injector.initContainer" }}
{{- if .Values.initContainer.enabled }}
- name: ghcr-secret-init
  image: "{{ .Values.initContainer.image }}:{{ default .Chart.Version .Values.initContainer.tag }}"
  imagePullPolicy: {{ .Values.initContainer.pullPolicy }}
  env:
    - name: GITHUB_APP_ID
      valueFrom:
        secretKeyRef:
          name: {{ .Values.initContainer.secretName }}
          key: {{ .Values.initContainer.appIdKey }}
    - name: GITHUB_INSTALLATION_ID
      valueFrom:
        secretKeyRef:
          name: {{ .Values.initContainer.secretName }}
          key: {{ .Values.initContainer.installationIdKey }}
  volumeMounts:
    - name: ghcr-app-key
      mountPath: {{ .Values.initContainer.keyMountPath }}
      readOnly: true
{{- end }}
{{- end }}

{{- define "ghcr-secret-injector.volume" }}
- name: ghcr-app-key
  secret:
    secretName: {{ .Values.initContainer.secretName }}
    items:
      - key: {{ .Values.initContainer.privateKeyFile }}
        path: {{ .Values.initContainer.privateKeyFile }}
{{- end }}

{{- define "ghcr-secret-injector.imagePullSecret" }}
- name: {{ .Values.initContainer.secretOutputName }}
{{- end }}
