# Custom AWX Docker Image

This directory contains the custom AWX Docker image with patched `jobs.py` to support Cloudflare survey operations.

## Contents

- **Dockerfile** - Custom AWX image based on `quay.io/ansible/awx:24.6.1`
- **jobs.py** - Patched AWX jobs module with Cloudflare survey support

## What's Patched?

The patched `jobs.py` file includes modifications to support:
- Cloudflare API survey parameters
- Enhanced variable handling for Cloudflare operations
- Custom field types for Cloudflare zones and operations

## Building the Image

### Manually

```bash
cd awx-image
docker build -t localhost:5000/awx-custom:latest .
docker push localhost:5000/awx-custom:latest
```

### Via Makefile

```bash
# From project root
make build-awx-image
```

This will:
1. Start a local Docker registry (if not running)
2. Build the custom AWX image
3. Push to local registry
4. Load into Kind cluster

## Using the Image

The image is automatically used when deploying AWX via `config/awx-instance.yaml`:

```yaml
spec:
  image: localhost:5000/awx-custom
  image_version: latest
  image_pull_policy: Always
```

## Updating the Patch

If you need to update `jobs.py`:

1. Edit `awx-image/jobs.py`
2. Rebuild the image: `make build-awx-image`
3. Restart AWX: `make awx-restart`

## Image Details

- **Base Image:** `quay.io/ansible/awx:24.6.1`
- **Target Path:** `/var/lib/awx/venv/awx/lib/python3.11/site-packages/awx/main/tasks/jobs.py`
- **User:** root (for installation), then reverts to uid 1000
- **Registry:** localhost:5000 (local development)

## Troubleshooting

### Image not found in cluster

```bash
# Reload image into Kind
kind load docker-image localhost:5000/awx-custom:latest --name cf-demo-cluster
```

### AWX not using custom image

Check AWX instance configuration:

```bash
kubectl get awx -n awx -o yaml | grep image:
```

Should show:
```yaml
image: localhost:5000/awx-custom
```

### Jobs.py changes not taking effect

1. Verify image was rebuilt: `docker images | grep awx-custom`
2. Check image timestamp
3. Restart AWX pods: `make awx-restart`
4. Verify patch is in place:
   ```bash
   kubectl exec -n awx -it <awx-task-pod> -- \
     cat /var/lib/awx/venv/awx/lib/python3.11/site-packages/awx/main/tasks/jobs.py | grep -A 5 "cloudflare"
   ```

## Production Considerations

For production use:

1. **Use a proper container registry:**
   - Push to Docker Hub, ECR, GCR, or private registry
   - Update `config/awx-instance.yaml` with registry URL

2. **Version tagging:**
   - Tag with specific versions instead of `latest`
   - Example: `your-registry.com/awx-custom:1.0.0`

3. **Image scanning:**
   - Scan for vulnerabilities before deployment
   - Use tools like Trivy, Clair, or Anchore

4. **Automated builds:**
   - Set up CI/CD pipeline to build on changes
   - Run tests before pushing

## License

This image is based on AWX (Apache 2.0 License) with custom modifications.
