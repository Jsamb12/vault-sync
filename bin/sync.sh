#!/usr/bin/env bash
set -euo pipefail

# Resolve the real path of this script (handles symlinks)
SCRIPT_PATH="$0"
if [[ "$SCRIPT_PATH" != /* ]]; then
  SCRIPT_PATH="$PWD/$SCRIPT_PATH"
fi
while [[ -L "$SCRIPT_PATH" ]]; do
  LINK_TARGET="$(readlink "$SCRIPT_PATH")"
  if [[ "$LINK_TARGET" == /* ]]; then
    SCRIPT_PATH="$LINK_TARGET"
  else
    SCRIPT_PATH="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)/$LINK_TARGET"
  fi
done

SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$ROOT_DIR/config/config.sh"
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

# If EXCLUDES is an array, build --exclude=... arguments
if declare -p EXCLUDES 2>/dev/null | grep -q 'declare \-a'; then
  for ex in "${EXCLUDES[@]}"; do
    RSYNC_EXCLUDES+=( "--exclude=$ex" )
  done
fi

RSYNC_FLAGS=( -a -u --itemize-changes --human-readable )

if [[ "${RSYNC_FLAGS_OVERRIDE:-}" == "--dry-run" ]]; then
    RSYNC_FLAGS+=( --dry-run )
fi

echo "--- Pass 1: iCloud -> USB (copy/update) ---" | tee -a "$log_file"
rsync "${RSYNC_FLAGS[@]}" "${RSYNC_EXCLUDES[@]:-}" \
    "$ICLOUD_VAULT_PATH/" "$USB_VAULT_PATH/" | tee -a "$log_file"

echo "--- Pass 2: USB -> iCloud (copy/update) ---" | tee -a "$log_file"
rsync "${RSYNC_FLAGS[@]}" "${RSYNC_EXCLUDES[@]:-}" \
    "$USB_VAULT_PATH/" "$ICLOUD_VAULT_PATH/" | tee -a "$log_file"

echo "Done. Log saved to: $log_file" | tee -a "$log_file"