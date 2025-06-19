# Usage

If you're not already running admission controllers, add this job to your cluster to have ghcr-sercret be automatically updated using a Github App.
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ghcr-secret-bootstrap
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  template:
    spec:
      serviceAccountName: ghcr-secret-writer
      restartPolicy: OnFailure
      containers:
        - name: secret-writer
          image: ghcr.io/flytit/utility/update-ghcr-secret:latest
          env:
            - name: GITHUB_APP_ID
              valueFrom:
                secretKeyRef:
                  name: github-app-secret
                  key: app_id
            - name: GITHUB_INSTALLATION_ID
              valueFrom:
                secretKeyRef:
                  name: github-app-secret
                  key: installation_id
          volumeMounts:
            - name: key
              mountPath: /mnt/key
              readOnly: true
      volumes:
        - name: key
          secret:
            secretName: github-app-secret
            items:
              - key: private-key.pem
                path: private-key.pem
```
