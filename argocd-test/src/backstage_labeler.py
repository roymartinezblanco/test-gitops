#!/usr/bin/env python3
"""
Backstage Labeler for Kubernetes Manifests

This script processes Kubernetes manifests from helm/helmfile template output
and adds Backstage metadata labels based on a configurable YAML configuration.

Usage:
    python backstage-labeler.py <file-or-directory>
    python backstage-labeler.py output.yaml
    python backstage-labeler.py ./manifests
    python backstage-labeler.py --config custom-config.yaml ./manifests
"""

import argparse
from ast import Not
import json
import os
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Any, List, Optional
import yaml


@dataclass
class FieldConfig:
    """Configuration for a metadata field."""
    name: str
    default: str = "unset"
    required: bool = True


@dataclass
class Config:
    """Configuration for the Backstage labeler."""
    label_prefix: str = "molops.net"
    metadata_source_file: str = "services-metadata.json"
    lookup_label: str = "servicename"
    fields: List[FieldConfig] = field(default_factory=list)
    static_labels: Dict[str, str] = field(default_factory=dict)
    preserve_existing: bool = True
    verbose: bool = False


class BackstageLabeler:
    """Processes Kubernetes manifests and adds Backstage labels."""

    def __init__(self, config_file: str = "config.yaml"):
        """
        Initialize the labeler.

        Args:
            config_file: Path to the YAML configuration file
        """
        self.config = self._load_config(config_file)
        self.metadata = self._load_metadata()

    def _load_config(self, config_file: str) -> Config:
        """Load configuration from YAML file."""
        if not os.path.exists(config_file):
            print(
                f"Warning: Config file '{config_file}' not found, using defaults",
                file=sys.stderr,
            )
            return Config()

        try:
            with open(config_file, "r") as f:
                config_data = yaml.safe_load(f)

            # Parse fields
            fields = []
            for field_data in config_data.get("fields", []):
                fields.append(
                    FieldConfig(
                        name=field_data["name"],
                        default=field_data.get("default", "unset"),
                        required=field_data.get("required", True),
                    )
                )

            # Build config object
            return Config(
                label_prefix=config_data.get("label_prefix", "molops.net"),
                metadata_source_file=config_data.get("metadata", {}).get(
                    "source_file", "services-metadata.json"
                ),
                lookup_label=config_data.get("metadata", {}).get("lookup_label", "servicename"),
                fields=fields,
                static_labels=config_data.get("static_labels", {}),
                preserve_existing=config_data.get("options", {}).get("preserve_existing", True),
                verbose=config_data.get("options", {}).get("verbose", False),
            )
        except (yaml.YAMLError, KeyError) as e:
            print(
                f"Error: Failed to parse config file '{config_file}': {e}",
                file=sys.stderr,
            )
            return Config()

    def _load_metadata(self) -> Dict[str, Dict[str, Any]]:
        """Load service metadata from JSON file."""
        metadata_file = self.config.metadata_source_file

        if not os.path.exists(metadata_file):
            print(
                f"Warning: Metadata file '{metadata_file}' not found, "
                f"using default labels",
                file=sys.stderr,
            )
            return {}

        try:
            with open(metadata_file, "r") as f:
                return json.load(f)
        except json.JSONDecodeError as e:
            print(
                f"Error: Failed to parse metadata file '{metadata_file}': {e}",
                file=sys.stderr,
            )
            return {}

    def _get_service_metadata(self, service_name: str) -> Dict[str, Any]:
        """
        Get metadata for a service based on configured fields.

        Args:
            service_name: Name of the service

        Returns:
            Dictionary containing metadata field values
        """
        result = {}

        if service_name in self.metadata:
            source_metadata = self.metadata[service_name]
            for field in self.config.fields:
                value = source_metadata.get(field.name, field.default)
                # Convert to string to ensure consistent label values
                result[field.name] = str(value)
        else:
            # Use defaults for all fields
            for field in self.config.fields:
                result[field.name] = field.default

        return result

    def _add_labels_to_document(self, document: Dict[str, Any]) -> Dict[str, Any]:
        """
        Add Backstage labels to a single Kubernetes resource document.

        Args:
            document: Kubernetes resource as a dictionary

        Returns:
            Modified document with added labels
        """
        # Skip if document doesn't have required fields
        if not document or "kind" not in document or "metadata" not in document:
            return document

        # Ensure metadata.labels exists
        if "labels" not in document["metadata"]:
            document["metadata"]["labels"] = {}

        labels = document["metadata"]["labels"]

        # Get lookup label value (e.g., servicename)
        lookup_value = labels.get(self.config.lookup_label)

        # Skip if no lookup label found
        if not lookup_value:
            if self.config.verbose:
                print(
                    f"  Skipping resource (no '{self.config.lookup_label}' label found)",
                    file=sys.stderr,
                )
            return document

        # Get metadata for this service
        service_metadata = self._get_service_metadata(lookup_value)

        # Add configured field labels with prefix
        for field in self.config.fields:
            label_key = f"{self.config.label_prefix}/{field.name}"
            label_value = service_metadata.get(field.name, field.default)

            # Only add if preserving existing or label doesn't exist
            if not self.config.preserve_existing or label_key not in labels:
                if label_value is not field.default:
                    labels[label_key] = label_value
            elif self.config.verbose:
                print(
                    f"  Preserving existing label: {label_key}={labels[label_key]}",
                    file=sys.stderr,
                )

        # Add static labels
        for label_key, label_value in self.config.static_labels.items():
            if not self.config.preserve_existing or label_key not in labels:
                labels[label_key] = label_value

        return document

    def process_file(self, file_path: Path) -> None:
        """
        Process a single YAML file and rewrite it with added labels.

        Args:
            file_path: Path to the YAML file to process
        """
        if self.config.verbose:
            print(f"Processing: {file_path}", file=sys.stderr)
        else:
            print(f"Processing: {file_path}", file=sys.stderr)

        try:
            # Load all documents from the YAML file
            with open(file_path, "r") as f:
                documents = list(yaml.safe_load_all(f))

            # Process each document
            processed_documents = []
            for doc in documents:
                if doc is not None:  # Skip empty documents
                    processed_doc = self._add_labels_to_document(doc)
                    processed_documents.append(processed_doc)

            # Write back to file
            with open(file_path, "w") as f:
                yaml.dump_all(
                    processed_documents,
                    f,
                    default_flow_style=False,
                    sort_keys=False,
                    explicit_start=True,
                )

        except yaml.YAMLError as e:
            print(f"Error: Failed to parse YAML file '{file_path}': {e}", file=sys.stderr)
        except Exception as e:
            print(f"Error: Failed to process file '{file_path}': {e}", file=sys.stderr)

    def process_directory(self, directory: Path) -> None:
        """
        Process all YAML files in a directory recursively.

        Args:
            directory: Path to the directory containing YAML files
        """
        yaml_files = list(directory.rglob("*.yaml")) + list(directory.rglob("*.yml"))

        if not yaml_files:
            print(f"Warning: No YAML files found in '{directory}'", file=sys.stderr)
            return

        for yaml_file in yaml_files:
            if yaml_file.is_file():
                self.process_file(yaml_file)

    def process(self, target: Path) -> None:
        """
        Process a file or directory.

        Args:
            target: Path to file or directory to process
        """
        if not target.exists():
            print(f"Error: '{target}' does not exist", file=sys.stderr)
            sys.exit(1)

        if target.is_file():
            self.process_file(target)
        elif target.is_dir():
            self.process_directory(target)
        else:
            print(f"Error: '{target}' is not a valid file or directory", file=sys.stderr)
            sys.exit(1)

        print("Processing complete!", file=sys.stderr)


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="Add Backstage labels to Kubernetes manifests based on YAML configuration",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s manifests.yaml
  %(prog)s ./manifests
  %(prog)s --config custom-config.yaml ./output
  %(prog)s --verbose ./manifests
        """,
    )
    parser.add_argument(
        "target",
        nargs="?",
        default=".",
        help="File or directory to process (default: current directory)",
    )
    parser.add_argument(
        "--config",
        "-c",
        default="config.yaml",
        help="Path to configuration YAML file (default: config.yaml)",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose logging",
    )
    parser.add_argument(
        "--version",
        action="version",
        version="%(prog)s 2.0.0",
    )

    args = parser.parse_args()

    # Create labeler and process target
    labeler = BackstageLabeler(config_file=args.config)

    # Override verbose if specified in CLI
    if args.verbose:
        labeler.config.verbose = True

    labeler.process(Path(args.target))


if __name__ == "__main__":
    main()
