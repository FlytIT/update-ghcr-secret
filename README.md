# Usage

In your app Helm chart, Add `ghcr-secret-injector` as a dependency in `Chart.yaml`
```yaml
dependencies:
  - name: ghcr-secret-injector
    version: 0.1.0
    repository: "file://../ghcr-secret-injector"  # or a remote repo
```
Next, enable the init container in your `values.yaml`:
```yaml
ghcr-secret-injector:
  initContainer:
    enabled: true
    image: ghcr.io/flytit/utility/update-ghcr-secret:latest
```
And lastly, edit your `deployment.yaml`:
```yaml
spec:
  serviceAccountName: ghcr-secret-writer
  initContainers:
    {{- include "ghcr-secret-injector.initContainer" . | nindent 4 }}
  containers:
    - name: your-app
      image: ghcr.io/your-org/your-app:tag
      ...
  volumes:
    {{- include "ghcr-secret-injector.volume" . | nindent 4 }}
  imagePullSecrets:
    {{- include "ghcr-secret-injector.imagePullSecret" . | nindent 4 }}
```
