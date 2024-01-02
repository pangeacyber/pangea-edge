# pangea-edge Helm Chart

This helm chart deploys pangea edge services to a kubernetes cluster.

Contact [support](mailto:support@pangea.cloud) for access to our edge images.

## Installation

### Prerequisites

-   Access to kubernetes ([kind](https://kind.sigs.k8s.io/), [eks](https://aws.amazon.com/eks/), [gke](https://cloud.google.com/kubernetes-engine?hl=en))
-   [kubectl](https://kubernetes.io/docs/reference/kubectl/) installed
-   [helm](https://helm.sh/) installed

### Install with Helm

Pangea is a security company and thus tries to follow security best practices. Thus this chart does not expect any sensitive
information directly.

1. Create a namespace for deployment (optional)

```bash
kubectl create namespace pangea
```

2. Add image pull secrets (optional)

Pangea edge images are private, therefore you need to [request access](mailto:michael.combs@pangea.cloud), then
either pull the images to a container registry such as [ecr](https://aws.amazon.com/ecr/) or [artifact registry](https://cloud.google.com/artifact-registry), or
use [dockerhub](https://hub.docker.com/) credentials in your cluster.

Dockerhub Example:

```bash
#!/bin/bash
docker login
cat ~/.docker/config.json | base64 | pbcopy
```

Image pull secret manifest example:

```yaml
apiVersion: v1
kind: Secret
metadata:
    name: pangeaRegistryKey
    namespace: pangea
type: kubernetes.io/dockerconfigjson
data:
    .dockerconfigjson: <base64-encoded-docker-config>
```

3. Add the [pangea vault edge token](https://console.pangea.cloud/service/redact/proxy) as a kubernetes secret

```yaml
apiVersion: v1
kind: Secret
metadata:
    name: vault-token
    namespace: pangea
type: Opaque
data:
    PANGEA_TOKEN: <base 64 encoded token value>
```

4. Add a service token for testing (optional)

This token is a standard service token you would use to make calls to your desired Pangea service.
Helm will use this token to test to ensure the deployment is running, in this case, redact.

You can get a token from the project [tokens page](https://console.pangea.cloud/project/tokens)

```yaml
apiVersion: v1
kind: Secret
metadata:
    name: test-redact-token
    namespace: pangea
type: Opaque
data:
    PANGEA_TOKEN: <base 64 encoded service token>
```

5. Create a Persistent volume claim

This volume is used to store usage metrics and metadata used to update Pangea metrics dashboards.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: usage-metrics-claim
    namespace: pangea
spec:
    accessModes:
        - ReadWriteMany #
    storageClassName: "" # or your desired storage class
    resources:
        requests:
            Storage: 5Gi
```

Note: You may need to create a persistent volume if your storage provider doesn't support automatic allocation

6. Configure & install the chart

Make sure you fetch your vault secret ID from the [edge proxy page](https://console.pangea.cloud/service/redact/proxy)

```bash
cat <<EOF  > /tmp/redact.yaml
pangeaVaultServiceTokenID: "<vault token ID from console>"
pangeaVaultTokenSecretName: "vault-token"
common:
  pangeaDomain: "aws.us.pangea.cloud"
  # If pull secrets are desired as configured in step 2
  imagePullSecrets:
    - pangeaRegistryKey
services:
  redact:
    enabled: true
    tests:
      enabled: true
      serviceTokenSecretName: "test-redact-token"
metricsVolume:
  existingClaim: "usage-metrics-claim"
EOF

helm install -n pangea -f /tmp/redact.yaml pangea-edge <location of helm chart>
helm test -n pangea pangea-edge # if you configured the token
```

The Redact Edge service can then be used in the same way that the Redact cloud service is used. For more information about the Redact service in general, you can visit our [Redact documentation](https://pangea.cloud/docs/redact/).
