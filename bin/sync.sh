#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd " $(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$ROOTDIR/config/config.sh"
LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$LOG_DIR"

timestamp() { date "+%Y-%m-%d_%H-%M-%S"; }