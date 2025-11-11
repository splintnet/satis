# Satis

Self-hosted Composer repository (Satis) with Nginx, Auth-Proxy and Webhook support.

## Project Structure

```
.
├── src/                    # Docker image source files
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── default.conf
│   ├── webhook.py
│   └── start.sh
├── satis/                  # Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── README.md              # This file
└── helmfile.yaml.example  # Helmfile example
```

## Docker Image

The Docker image is built from files in the `src/` directory and automatically published to GitHub Container Registry on push.

## Helm Chart Installation

### Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.8+ (for OCI registry support)
- Access to GitHub Container Registry (ghcr.io)

### Add Helm Registry (optional)

If using a private repository, authenticate with GitHub Container Registry:

```bash
helm registry login ghcr.io -u YOUR_GITHUB_USERNAME
```

### Install from OCI Registry

```bash
helm install my-satis oci://ghcr.io/splintnet/satis/satis --version 0.1.0
```

### Install with Custom Values

```bash
helm install my-satis oci://ghcr.io/splintnet/satis/satis \
  --version 0.1.0 \
  -f values.yaml
```

### Upgrade

```bash
helm upgrade my-satis oci://ghcr.io/splintnet/satis/satis --version 0.2.0
```

## Configuration

### Required Values

At minimum, configure the Docker image and Satis configuration:

```yaml
image:
  repository: ghcr.io/splintnet/satis/satis
  tag: "latest"

satis:
  configJson: |
    {
      "name": "my/composer-repository",
      "description": "My Composer Repository",
      "homepage": "https://repo.example.com",
      "repositories": [
        { "type": "vcs", "url": "https://github.com/myorg/myrepo.git" }
      ],
      "require-all": true
    }
```

### Authentication (Optional)

To protect packages with authentication:

```yaml
ingress:
  enabled: true
  authUrl: "https://auth.example.com" # Base URL (without /api/auth)
  hosts:
    - host: repo.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: repo-tls
      hosts:
        - repo.example.com
```

### Webhook (Optional)

Enable webhook for manual rebuild triggers:

```yaml
webhook:
  enabled: true
  authSecret: "your-secret-here" # MUST be set if enabled
  rebuildCommand: "/satis/bin/satis build /build/config/satis.json /build/output"
```

### GitHub OAuth (Optional)

For private repositories:

```yaml
github:
  oauth:
    enabled: true
    token: "ghp_YOUR_TOKEN_HERE"
```

### Persistence

Persistent storage for Satis output:

```yaml
persistence:
  enabled: true
  size: 2Gi
  storageClass: "" # Use default storage class
```

## Complete Example

See `helmfile.yaml.example` for a complete configuration example.

## Values Reference

| Parameter                   | Description                      | Default                         |
| --------------------------- | -------------------------------- | ------------------------------- |
| `image.repository`          | Docker image repository          | `ghcr.io/splintnet/satis/satis` |
| `image.tag`                 | Docker image tag                 | `latest`                        |
| `satis.configPath`          | Path to Satis config.json        | `/build/config/satis.json`      |
| `satis.outputPath`          | Path for Satis output            | `/build/output`                 |
| `satis.forceBuildOnStartup` | Force build on container startup | `true`                          |
| `satis.configJson`          | Satis configuration JSON         | See values.yaml                 |
| `ingress.enabled`           | Enable ingress                   | `false`                         |
| `ingress.authUrl`           | Auth API base URL                | `""`                            |
| `webhook.enabled`           | Enable webhook service           | `false`                         |
| `webhook.authSecret`        | Webhook auth secret              | `CHANGE_ME`                     |
| `persistence.enabled`       | Enable persistent storage        | `true`                          |
| `persistence.size`          | Storage size                     | `2Gi`                           |

## Uninstall

```bash
helm uninstall my-satis
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=satis
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=satis
```

### Check ConfigMap

```bash
kubectl get configmap my-satis-config -o yaml
```

### Test Webhook

```bash
curl -X POST https://repo.example.com/webhook \
  -H "X-Satis-Auth-Secret: your-secret"
```

## License

See LICENSE file in the repository.
