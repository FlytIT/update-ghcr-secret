# Usage

Create a service account
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ghcr-secret-writer
```
Create a role
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ghcr-secret-writer
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "create", "update", "patch"]
```
Bind the role to the account
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ghcr-secret-writer-binding
roleRef:
  kind: Role
  name: ghcr-secret-writer
  apiGroup: rbac.authorization.k8s.io
subjects:
  - kind: ServiceAccount
    name: ghcr-secret-writer
```
Create a job
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: update-ghcr-secret
spec:
  schedule: "0 1 * * *"
  startingDeadlineSeconds: 300
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          serviceAccountName: ghcr-secret-writer
          volumes:
            - name: rsa-key
              secret:
                secretName: <github-app-secret>
                items:
                  - key: private-key.pem
                    path: private-key.pem
          containers:
            - name: token-updater
              image: ghcr.io/FlytIT/utility/update-ghcr-secret:latest
              volumeMounts:
                - name: rsa-key
                  mountPath: /mnt/key
                  readOnly: true
              env:
                - name: GITHUB_APP_ID
                  valueFrom:
                    secretKeyRef:
                      name: <github-app-secret>
                      key: app_id
                - name: GITHUB_INSTALLATION_ID
                  valueFrom:
                    secretKeyRef:
                      name: <github-app-secret>
                      key: installation_id
                - name: GITHUB_PRIVATE_KEY
                  valueFrom:
                    secretKeyRef:
                      name: <github-app-secret>
                      key: private-key.pem
                - name: REFRESH_INTERVAL
                  value: 86400 # 24 hours
```
