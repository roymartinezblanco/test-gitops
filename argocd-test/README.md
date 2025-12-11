# Backstage Labeler for Helm/Helmfile

A tool to automatically add Backstage metadata labels to Kubernetes manifests generated from Helm or Helmfile templates.

## Overview

This tool processes Kubernetes manifests and enriches them with Backstage catalog labels based on a `servicename` label. It's designed to work with the output of `helm template` or `helmfile template` commands.

## How It Works

1. Generate Kubernetes manifests using `helm template` or `helmfile template`
2. Run the backstage-labeler on the generated YAML files
3. The labeler reads the `servicename` label from each resource
4. It looks up metadata from `services-metadata.json`
5. It adds the following labels to each resource:
   - `molops.net/team` - Team owning the service
   - `molops.net/domain` - Domain/area the service belongs to
   - `molops.net/system` - System the service is part of
   - `molops.net/criticality` - Criticality level (1-5)
   - `app.kubernetes.io/managed-by` - Set to "helmfile"

## Prerequisites

- Docker
- Helm 3.x
- Helmfile (optional, if using helmfile)
- kubectl (optional, for applying manifests)

## Setup

1. Build the Docker image:
```bash
docker build -t backstage-labeler:latest .
```

2. Create or update `services-metadata.json` with your service metadata:
```json
{
  "my-service": {
    "team": "platform-team",
    "domain": "platform",
    "system": "core-services",
    "criticality": 3
  }
}
```

## Usage

The tool is available in two versions:
- **Python version** (recommended) - `backstage-labeler.py` - Cleaner, more maintainable
- **Shell version** - `backstage-labeler.sh` - Original implementation using yq/jq

### Option 1: Helm Template (Python - Recommended)

Generate manifests from a Helm chart and process them:

```bash
# Generate manifests
helm template my-app ./charts/my-app > manifests.yaml

# Add Backstage labels with Python
docker run --rm -v $(pwd):/workspace backstage-labeler:latest \
  python3 /scripts/backstage-labeler.py manifests.yaml

# Apply to cluster
kubectl apply -f manifests.yaml
```

### Option 2: Helmfile Template (Python - Recommended)

Generate manifests from Helmfile and process them:

```bash
# Generate manifests to a directory
helmfile template --output-dir ./manifests

# Add Backstage labels to all files in the directory
docker run --rm -v $(pwd):/workspace backstage-labeler:latest \
  python3 /scripts/backstage-labeler.py ./manifests

# Apply all manifests
kubectl apply -f ./manifests
```

### Option 3: Using Shell Script Version

If you prefer the shell script version:

```bash
# Generate manifests
helmfile template --output-dir ./manifests

# Add Backstage labels with shell script
docker run --rm -v $(pwd):/workspace backstage-labeler:latest \
  /scripts/backstage-labeler.sh ./manifests

# Apply all manifests
kubectl apply -f ./manifests
```

### Option 4: With Custom Metadata File

Specify a custom metadata file location (works with both versions):

```bash
# Python version
docker run --rm \
  -v $(pwd):/workspace \
  -e METADATA_FILE=/workspace/custom-metadata.json \
  backstage-labeler:latest \
  python3 /scripts/backstage-labeler.py ./manifests

# Shell version
docker run --rm \
  -v $(pwd):/workspace \
  -e METADATA_FILE=/workspace/custom-metadata.json \
  backstage-labeler:latest \
  /scripts/backstage-labeler.sh ./manifests
```

### Option 5: Using Python Locally (without Docker)

If you have Python 3 and PyYAML installed locally:

```bash
# Install PyYAML if needed
pip install pyyaml

# Run the script directly
python3 backstage-labeler.py ./manifests

# Or with custom metadata file
METADATA_FILE=custom-metadata.json python3 backstage-labeler.py ./manifests
```

## Service Metadata File

The `services-metadata.json` file maps service names to their Backstage metadata:

```json
{
  "service-name": {
    "team": "team-identifier",
    "domain": "domain-name",
    "system": "system-name",
    "criticality": 1-5
  }
}
```

### Criticality Levels

- `1` - Low criticality
- `2` - Medium-low criticality
- `3` - Medium criticality
- `4` - High criticality
- `5` - Critical

## Required Label in Your Manifests

For the labeler to work, your Kubernetes resources must include a `servicename` label:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    servicename: my-app  # This label is required
spec:
  # ... rest of your deployment spec
```

Resources without a `servicename` label will be skipped and returned unchanged.

## Complete Workflow Example

```bash
# 1. Build the labeler image
docker build -t backstage-labeler:latest .

# 2. Configure your helmfile.yaml with your releases
# 3. Create services-metadata.json with your service mappings

# 4. Generate manifests
helmfile template --output-dir ./output

# 5. Process manifests with Backstage labels (Python recommended)
docker run --rm -v $(pwd):/workspace backstage-labeler:latest \
  python3 /scripts/backstage-labeler.py ./output

# 6. Review the labeled manifests
cat ./output/*.yaml

# 7. Apply to your cluster
kubectl apply -f ./output
```

## Environment Variables

- `METADATA_FILE` - Path to the services metadata JSON file (default: `services-metadata.json`)

## Dockerfile Contents

The Docker image includes:
- Alpine Linux 3.19
- Python 3 with PyYAML
- yq v4.44.3 - YAML processor
- jq - JSON processor
- Helm v3.16.3
- Helmfile v0.169.1
- bash, git, curl
- Both backstage-labeler.py (Python) and backstage-labeler.sh (shell) scripts

## Troubleshooting

### "No servicename label found"

Ensure your manifests include the `servicename` label in `metadata.labels`.

### "No metadata found for service"

The service name in your manifest doesn't have a corresponding entry in `services-metadata.json`. The labeler will use default values ("unset") for missing metadata.

### Permission errors in Docker

Make sure you're mounting the current directory correctly:
```bash
docker run --rm -v $(pwd):/workspace backstage-labeler:latest ...
```

## Migration from ArgoCD

This tool replaces the ArgoCD-based labeling approach with a simpler Helm/Helmfile-based workflow. The key differences:

- **Before**: ArgoCD plugin processed manifests during sync
- **After**: Process manifests with `helm template` or `helmfile template`, then apply

Benefits:
- No dependency on ArgoCD
- Works with any GitOps tool or kubectl
- Faster feedback during development
- Easier to test and debug locally
