#!/usr/bin/env bash

set -euo pipefail

root_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
config_path="${1:-$root_dir/config/config.example.json}"
python3 - "$config_path" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as stream:
    config = json.load(stream)

if config.get("schemaVersion") != 1:
    raise SystemExit("schemaVersion must be 1")
if not isinstance(config.get("autostart"), bool):
    raise SystemExit("autostart must be boolean")
modules = config.get("modules")
module_names = {"wifi", "volume", "battery", "bluetooth", "inputLayout", "notifications", "controlCenter", "userSession"}
if not isinstance(modules, dict) or not modules or any(k not in module_names or not isinstance(v, bool) for k, v in modules.items()):
    raise SystemExit("modules must be a non-empty object of booleans")
dock = config.get("dock", {})
if not isinstance(dock.get("pinnedIds", []), list) or not all(isinstance(v, str) for v in dock.get("pinnedIds", [])):
    raise SystemExit("dock.pinnedIds must be an array of strings")
if config.get("logging", {}).get("level") not in {"debug", "info", "warning", "error"}:
    raise SystemExit("logging.level is invalid")
print(f"ok config: {path}")
PY
