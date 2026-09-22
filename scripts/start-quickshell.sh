#!/usr/bin/env bash

set -euo pipefail

project_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

exec quickshell -p "$project_root" "$@"