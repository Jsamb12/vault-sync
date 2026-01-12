# vault-sync

A small Bash utility to safely keep an Obsidian vault in sync between iCloud and a portable USB drive.

The script performs a conservative two-way sync using `rsync`, ensuring that:
- new and updated notes are copied in both directions
- newer files are never overwritten
- nothing is deleted automatically
- detailed logs are kept for every run

Designed for my daily use.

## Features
- Two-way iCloud ↔ USB sync (copy/update only)
- Dry-run support for safe testing
- Automatic detection of mounted USB drives
- Config-based paths (no hard-coded locations)
- Excludes transient files (e.g. `.git`, Obsidian cache)
- Timestamped logs for auditing and debugging

## Motivation
Code is already backed up via Git, but notes are not. This project exists to keep a my notes up to date on a physical drive.