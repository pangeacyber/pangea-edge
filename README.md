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

## Configuration

| Parameter                                                     | Description                                                                                                                                   | Required? |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| pangeaVaultTokenSecretName                                    | This secret is used to submit usage back to pangea cloud note: Secret file must be named `PANGEA_VAULT_TOKEN`                                 | Y         |
| pangeaVaultServiceTokenID                                     | The Edge Proxy instance requires a service token stored in vault with specific edge permissions                                               | Y         |
| common.pangeaDomain                                           | The pangea cloud domain specifying the specific pangea cluster this service is running on eg. `aws.us.pangea.cloud`                           | Y         |
| common.labels                                                 | Kubernetes labels that will be added to all resources deployed by this helm chart                                                             | N         |
| common.logLevel                                               | `(debug\|info\|error)` the log level for services deployed by this helm chart                                                                 | N         |
| common.annotations                                            | Annotations added to all resources deployed by this chart                                                                                     | N         |
| common.imagePullSecrets                                       | Kubernetes pull secrets applied to each resource, will be overridden by each resource's imagePullSecrets                                      | N         |
| serviceMonitor.annotations                                    | If prometheus metrics are desired, each service monitor resource will include these annotations                                               | N         |
| serviceMonitor.labels                                         | If prometheus metrics are desired, each service monitor resource will include these labels                                                    | N         |
| metricsVolume.existingClaim                                   | Use an existing volume claim for the required metrics volume                                                                                  | N         |
| metricsVolume.storageClass                                    | The chart can generate a volume, it will use the provided storage class                                                                       | N         |
| metricsVolume.size                                            | If using the chart generated volume, this will be the volume size                                                                             | N         |
| metricsVolume.name                                            | The name of the chart generated storage claim if using chart generated volume                                                                 | N         |
| metricsVolume.annotations                                     | Annotations on the helm chart generated volume                                                                                                | N         |
| metricsVolume.labels                                          | Labels on the helm chart generated volume                                                                                                     | N         |
| services.submission.image.repository                          | The image repository for the submission image                                                                                                 | N         |
| services.submission.image.pullPolicy                          | Kubernetes [pull policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) for the submission image                   | N         |
| services.submission.image.tag                                 | Version tag for the submission image                                                                                                          | N         |
| services.submission.image.imagePullSecrets                    | Kubernetes image pull secrets for the submission image                                                                                        | N         |
| services.submission.schedulerName                             | [Kubernetes scheduler](https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/) name if using a different scheduler | N         |
| services.submission.annotations                               | Annotations attached to the submission cronjob                                                                                                | N         |
| services.submission.labels                                    | Labels attached to the submission cronjob                                                                                                     | N         |
| services.submission.linkerd                                   | Are we using linkerd?                                                                                                                         | N         |
| services.submission.tests.annotations                         | Annotations attached to the submission job helm test pod                                                                                      | N         |
| services.submission.tests.labels                              | Labels attached to the submission job helm test pod                                                                                           | N         |
| services.redact.enabled                                       | Enable the redact edge service?                                                                                                               | N         |
| services.redact.minReplicas                                   | The minimum number of replicas for the deployment, defaults to 1                                                                              | N         |
| services.redact.serviceAccountName                            | A kubernetes service account name if one is required                                                                                          | N         |
| services.redact.annotations                                   | Annotations attached to the redact edge deployment                                                                                            | N         |
| services.redact.labels                                        | Labels attached to the redact edge deployment                                                                                                 | N         |
| services.redact.podSecurityContext                            | [Kubernetes pod security context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)                                 | N         |
| services.redact.securityContext                               | [Kubernetes security context for the container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)                   | N         |
| services.redact.nodeSelector                                  | [Kubernetes node selector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector)                             | N         |
| services.redact.affinity                                      | [Kubernetes node selector affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)      | N         |
| services.redact.tolerations                                   | [Kubernets tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)                                        | N         |
| services.redact.image.repository                              | The image repository for the redact image                                                                                                     | N         |
| services.redact.image.pullPolicy                              | Kubernetes [pull policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) for the redact image                       | N         |
| services.redact.image.tag                                     | Version tag for the redact image                                                                                                              | N         |
| services.redact.image.imagePullSecrets                        | Kubernetes image pull secrets for the redact image                                                                                            | N         |
| services.redact.resources                                     | [Kubernetes resources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)                                        | N         |
| services.redact.autoscaling                                   | Configuration for a horizontal pod autoscaling resource                                                                                       | N         |
| services.redact.autoscaling.enabled                           | Enable the creation of an autoscaling resource for redact?                                                                                    | N         |
| services.redact.autoscaling.annotations                       | Annotations attached to the redact edge deployment HPA resource                                                                               | N         |
| services.redact.autoscaling.labels                            | Labels attached to the redact edge deployment HPA resource                                                                                    | N         |
| services.redact.autoscaling.maxReplicas                       | Maximum number of redact replicas allowed to the HPA resource                                                                                 | N         |
| services.redact.autoscaling.targetMemoryUtilizationPercentage | How high should memory usage be before autoscaling kicks in?                                                                                  | N         |
| services.redact.autoscaling.targetCPUUtilizationPercentage    | How high should CPU usage be before autoscaling kicks in?                                                                                     | N         |
| services.redact.service.type                                  | The [kubernetes service type](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) for redact  | N         |
| services.redact.service.name                                  | Service name, generally the desired internal DNS name                                                                                         | N         |
| services.redact.service.labels                                | Labels attached to the redact service resource                                                                                                | N         |
| services.redact.service.annotations                           | Annotations attached to the redact service resource                                                                                           | N         |
| services.redact.service.ports                                 | Kubernetes port configuration deciding which port to expose on the service                                                                    | N         |
| services.redact.serviceMonitor.enabled                        | Enable a prometheus service monitor on the redact service?                                                                                    | N         |
| services.redact.serviceMonitor.portName                       | The name of the port from `services.redact.service.ports` if edited                                                                           | N         |
| services.redact.tests.serviceTokenSecretName                  | The kubernetes secret name associated to a test token to ensure the redact container is ready                                                 | N         |
| services.redact.tests.testPort                                | The port targeted by the test container on the redact service                                                                                 | N         |
