#!/bin/bash
set -e
helmfile template --output-dir ./manifests
poetry install
poetry run backstage-labeler ./manifests
