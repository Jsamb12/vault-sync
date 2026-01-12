#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd " $(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$ROOTDIR/config/config.sh"
LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$LOG_DIR"

# Timestamp helper function used for history of sync runs
timestamp() { date "+%Y-%m-%d_%H-%M-%S"; }
log_file="$LOG_DIR/sync_$(timestamp).log"

# Checks if the config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Missing config: $CONFIG_FILE"
    echo "Create it from config/config.example.sh"
    exit 1
fi

# Runs the config file so all variables are defined in it become available
source "$CONFIG_FILE"

# Note on syntax: `${VAR:-}` means "use VAR if set, otherwise use empty string"
# Important since in set -u mode, refing an unset var would crash script
if [[ -z "${ICLOUD_VAULT_PATH:-}" ]]; then
    echo "ICLOUD_VAULT_PATH is empty in config/config.sh" | tee -a "$log_file"
    exit 1
fi
if [[ -z "${USB_VOLUME_NAME:-}" ]]; then
    echo "USB_VOLUME_NAME is eempty in config/config.sh" | tee -a "$log_file"
    exit 1
fi


