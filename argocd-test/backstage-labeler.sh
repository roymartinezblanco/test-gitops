#!/bin/sh
set -e

# Get target directory from argument, default to current directory
TARGET_DIR="${1:-.}"

# Process all YAML files and inject labels
find "$TARGET_DIR" -name "*.yaml" -o -name "*.yml" | while read file; do
  # Extract service name from the servicename label
  SERVICE_NAME=$(yq eval '.metadata.labels.servicename // ""' "$file")
  
  # Skip if no servicename label found
  if [ -z "$SERVICE_NAME" ] || [ "$SERVICE_NAME" = "null" ]; then
    echo "Warning: No 'servicename' label found in $file, skipping" >&2
    cat "$file"
    continue
  fi
  
  # Look up metadata from ConfigMap
  METADATA=$(jq -r ".\"$SERVICE_NAME\" // {}" services-metadata.json)
  TEAM=$(echo "$METADATA" | jq -r '.team // "unset"')
  DOMAIN=$(echo "$METADATA" | jq -r '.domain // "unset"')
  SYSTEM=$(echo "$METADATA" | jq -r '.system // "unset"')
  CRITICALITY=$(echo "$METADATA" | jq -r '.criticality // "unset"')
  
  # Warn if metadata not found
  if [ "$TEAM" = "unknown" ]; then
    echo "Warning: No metadata found for service '$SERVICE_NAME' in $file, using defaults" >&2
  fi
  
  # Inject labels
  yq eval "
    select(.kind != null) |
    .metadata.labels.\"molops.net/team\" = \"$TEAM\" |
    .metadata.labels.\"molops.net/domain\" = \"$DOMAIN\" |
    .metadata.labels.\"molops.net/system\" = \"$SYSTEM\" |
    .metadata.labels.\"molops.net/criticality\" = \"$CRITICALITY\" |
    .metadata.labels.\"app.kubernetes.io/managed-by\" = \"argocd\"
  " "$file"
done
