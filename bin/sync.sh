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

USB_MOUNT="/Volumes/$USB_VOLUME_NAME"
USB_VAULT_PATH="$USB_MOUNT/${USB_VAULT_SUBDIR:-Obsidian}"

# Print a header so I can sanity check.
echo "=== Vault sync $(date) ===" | tee -a "$log_file"
echo "iCloud Vault: $ICLOUD_VAULT_PATH" | tee -a "$log_file"
echo "USB Vault:    $USB_VAULT_PATH" | tee -a "$log_file"

if [[ ! -d "$ICLOUD_VAULT_PATH" ]]; then
    echo "ERROR: iCloud vault path not found: $ICLOUD_VAULT_PATH" | tee -a "$log_file"
    exit 1
fi
if [[ ! -d "$USB_MOUNT" ]]; then
    echo "ERROR: USB not mounted at: $USB_MOUNT" | tee -a "$log_file"
    exit 1
fi

mkdir -p "$USB_VAULT_PATH"

# Check whether the excludes array exists. We then loop thrpugh each patter and append --exclude=...
RSYNC_EXCLUDES=()
if declare -p EXCLUDES &>/dev/nul; then
    for ex in "${EXCLUDES[@]}"; do
        RSYNC_EXCLUDES+=( "--exclude=$ex")
    done
fi

RSYNC_FLAGS=( -a -u --itemize-changes --human-readable )

if [[ "${RSYNC_FLAGS_OVERRIDE:-}" == "--dry-run" ]]; then
    RSYNC_FLAGS+=( --dry-run )
fi

echo "--- Pass 1: iCloud -> USB (copy/update) ---" | tee -a "$log_file"
rsync "${RSYNC_FLAGS[@]}" "${RSYNC_EXCLUDES[@]}" \
    "$ICLOUD_VAULT_PATH/" "$USB_VAULT_PATH/" | tee -a "$log_file"

echo "--- Pass 2: USB -> iCloud (copy/update) ---" | tee -a "$log_file"
rsync "${RSYNC_FLAGS[@]}" "${RSYNC_EXCLUDES[@]}" \
    "$USB_VAULT_PATH/" "$ICLOUD_VAULT_PATH/" | tee -a "$log_file"

echo "Done. Log saved to: $log_file" | tee -a "$log_file"