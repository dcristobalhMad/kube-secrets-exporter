# kube-secrets-exporter

kube-secrets-exporter is a Prometheus exporter written in Go that retrieves information about Kubernetes secrets and exposes metrics for monitoring. It allows you to track the last modification time of secrets, scan duration, and the number of modifications detected in secrets.

## Features

- Exposes Prometheus metrics for Kubernetes secrets.
- Tracks the last modification time of secrets.
- Calculates the duration of the scan process.
- Counts the total number of modifications detected in secrets.
- Supports multi-threaded processing for faster scanning.

## Getting Started

### Build from Source

To build kube-secrets-exporter from source, you need to have Go installed. Follow these steps:

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/dcristobalhMad/kube-secrets-exporter.git
   ```

2. **Build the Binary:**
   ```bash
   cd kube-secrets-exporter
   go build -o kube-secrets-exporter cmd/main.go
   ```

### Running with Kubernetes Configuration

If you have a `.kube/config` file to access a Kubernetes cluster, you can run kube-secrets-exporter directly without building the Docker image. Follow these steps:

1. **Ensure you have `kubectl` Installed:**
   If you don't have `kubectl` installed, follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to install it.

2. **Set Up Kubernetes Configuration:**
   Ensure that your `.kube/config` file is correctly configured to access your Kubernetes cluster.

3. **Run the Binary:**
   ```bash
   ./kube-secrets-exporter
   ```

### Accessing Metrics

Once kube-secrets-exporter is running, you can access the Prometheus metrics by opening a web browser and navigating to [http://localhost:8080/metrics](http://localhost:8080/metrics).

## Configuration

kube-secrets-exporter uses the Kubernetes client to communicate with the cluster. It automatically detects whether it is running inside a Kubernetes cluster or uses the kubeconfig file if running outside the cluster.

## Metrics

The following Prometheus metrics are exposed by kube-secrets-exporter:

- `kube_secret_last_modified_time`: The Unix timestamp of the last modification time of the secret.
- `kube_secret_scan_duration_seconds`: Duration of the last scan for checking secret modifications in seconds.
- `kube_secret_modifications_total`: Total number of modifications detected in secrets.
- `kube_secret_last_scan_success`: Indicates if the last scan was successful (1 for success, 0 for failure).

## Contributing

Contributions to kube-secrets-exporter are welcome! If you find a bug or have a feature request, please open an issue or submit a pull request.
