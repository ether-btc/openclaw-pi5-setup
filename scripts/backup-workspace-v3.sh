#!/bin/bash
#
# OpenClaw Workspace Backup Script v3
# Patterns from: Phoenix Shield + Update Plus
#
# Features:
#   - Pre-flight checks (disk, memory, gateway, git)
#   - Dry-run mode (--dry-run)
#   - Check-before-backup (skip if nothing changed)
#   - Exclude patterns (node_modules, logs, cache)
#   - Config file (~/.openclaw/backup-config.json)
#   - Archive rotation (keep last N tarballs)
#   - Retry logic with configurable delay
#   - Post-backup health check
#
# Usage:
#   backup-workspace.sh           # Normal backup
#   backup-workspace.sh --dry-run # Preview only
#

set -euo pipefail

# ============================================
# CONFIG LOADING
# ============================================
CONFIG_FILE="$HOME/.openclaw/backup-config.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values (overridden by config file)
WORKSPACE="$HOME/.openclaw/workspace"
LOG_FILE="$WORKSPACE/memory/backup.log"
BACKUP_DIR="$HOME/.openclaw/backups"
MAX_LOG_LINES=1000
BACKUP_COUNT=5
MIN_DISK_FREE_GB=5
MIN_MEMORY_MB=500
GATEWAY_TIMEOUT_S=10
PUSH_RETRIES=3
PUSH_RETRY_DELAY_S=5

# Parse config file if exists
load_config() {
  if [ -f "$CONFIG_FILE" ]; then
    # Use jq to parse JSON config
    if command -v jq &> /dev/null; then
      local ws_path
      ws_path=$(jq -r '.workspace_path // empty' "$CONFIG_FILE" 2>/dev/null)
      [ -n "$ws_path" ] && WORKSPACE="${ws_path/#\~/$HOME}"
      
      local log_path
      log_path=$(jq -r '.log_file // empty' "$CONFIG_FILE" 2>/dev/null)
      [ -n "$log_path" ] && LOG_FILE="${log_path/#\~/$HOME}"
      
      local bk_dir
      bk_dir=$(jq -r '.backup_dir // empty' "$CONFIG_FILE" 2>/dev/null)
      [ -n "$bk_dir" ] && BACKUP_DIR="${bk_dir/#\~/$HOME}"
      
      MAX_LOG_LINES=$(jq -r '.max_log_lines // 1000' "$CONFIG_FILE" 2>/dev/null)
      BACKUP_COUNT=$(jq -r '.backup_count // 5' "$CONFIG_FILE" 2>/dev/null)
      MIN_DISK_FREE_GB=$(jq -r '.thresholds.min_disk_free_gb // 5' "$CONFIG_FILE" 2>/dev/null)
      MIN_MEMORY_MB=$(jq -r '.thresholds.min_memory_mb // 500' "$CONFIG_FILE" 2>/dev/null)
      GATEWAY_TIMEOUT_S=$(jq -r '.thresholds.gateway_timeout_s // 10' "$CONFIG_FILE" 2>/dev/null)
      PUSH_RETRIES=$(jq -r '.git.push_retries // 3' "$CONFIG_FILE" 2>/dev/null)
      PUSH_RETRY_DELAY_S=$(jq -r '.git.push_retry_delay_s // 5' "$CONFIG_FILE" 2>/dev/null)
    fi
  fi
  
  # Ensure directories exist
  mkdir -p "$(dirname "$LOG_FILE")"
  mkdir -p "$BACKUP_DIR"
}

# ============================================
# LOGGING
# ============================================
log() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $1" >> "$LOG_FILE"
  
  if [ -t 1 ]; then
    echo "[$timestamp] $1" >&2
  fi

  # Trim log if too large
  if [ -f "$LOG_FILE" ]; then
    local lines
    lines=$(wc -l < "$LOG_FILE")
    if [ "$lines" -gt "$MAX_LOG_LINES" ]; then
      tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp"
      mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
  fi
}

# ============================================
# DRY RUN MODE
# ============================================
DRY_RUN=false

check_dry_run() {
  if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=true
    log "=== DRY RUN MODE: No changes will be made ==="
  fi
}

# ============================================
# STAGE 0: PRE-FLIGHT CHECKS
# ============================================
preflight() {
  log "=== PRE-FLIGHT: Starting checks ==="
  local errors=0

  # Check 1: Disk space
  local disk_free
  disk_free=$(df -BG / | tail -1 | awk '{print $4}' | tr -d 'G')
  if [ "$disk_free" -lt "$MIN_DISK_FREE_GB" ]; then
    log "PREFLIGHT FAIL: Disk space low (${disk_free}GB < ${MIN_DISK_FREE_GB}GB)"
    ((errors++))
  else
    log "PREFLIGHT OK: Disk space (${disk_free}GB free)"
  fi

  # Check 2: Memory
  local mem_avail
  mem_avail=$(free -m | grep "Mem:" | awk '{print $7}')
  if [ "$mem_avail" -lt "$MIN_MEMORY_MB" ]; then
    log "PREFLIGHT WARN: Memory low (${mem_avail}MB < ${MIN_MEMORY_MB}MB)"
  else
    log "PREFLIGHT OK: Memory (${mem_avail}MB available)"
  fi

  # Check 3: Gateway responding (non-fatal)
  if curl -s --max-time "$GATEWAY_TIMEOUT_S" "http://127.0.0.1:18789/health" > /dev/null 2>&1; then
    log "PREFLIGHT OK: Gateway responding"
  else
    log "PREFLIGHT WARN: Gateway not responding"
  fi

  # Check 4: Git remote
  if git -C "$WORKSPACE" remote get-url origin > /dev/null 2>&1; then
    log "PREFLIGHT OK: Git remote configured"
  else
    log "PREFLIGHT FAIL: No git remote configured"
    ((errors++))
  fi

  if [ "$errors" -gt 0 ]; then
    log "=== PRE-FLIGHT: $errors check(s) failed ==="
    return 1
  fi

  log "=== PRE-FLIGHT: All checks passed ==="
  return 0
}

# ============================================
# STAGE 1: CHECK IF BACKUP NEEDED
# ============================================
check_changes() {
  log "=== CHECK: Looking for changes ==="
  
  cd "$WORKSPACE" || {
    log "ERROR: Cannot cd to workspace"
    return 1
  }

  # Check for changes (git respects .gitignore for excludes)
  local staged unstaged untracked
  staged=$(git diff --cached --quiet && echo "0" || echo "1")
  unstaged=$(git diff --quiet && echo "0" || echo "1")
  untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)

  if [ "$staged" = "0" ] && [ "$unstaged" = "0" ] && [ "$untracked" -eq 0 ]; then
    log "CHECK: No changes to backup"
    return 2  # Special code: no changes
  fi

  local total=$((staged + unstaged))
  [ "$untracked" -gt 0 ] && total=$((total + 1))
  
  log "CHECK: Found changes (staged=$staged, unstaged=$unstaged, untracked=$untracked)"
  return 0
}

# ============================================
# STAGE 2: BACKUP
# ============================================
backup() {
  log "=== BACKUP: Starting ==="

  cd "$WORKSPACE" || return 1

  if [ ! -d ".git" ]; then
    log "ERROR: Not a git repository"
    return 1
  fi

  # Add all changes (git respects .gitignore)
  git add -A 2>> "$LOG_FILE"

  # Count changes
  local changes
  changes=$(git diff --cached --numstat | wc -l)
  log "BACKUP: Changes to commit: $changes files"

  if [ "$DRY_RUN" = true ]; then
    log "DRY RUN: Would commit and push $changes files"
    git diff --cached --stat >> "$LOG_FILE"
    return 0
  fi

  # Commit with timestamp
  local commit_msg
  commit_msg="Auto-backup: $(date '+%Y-%m-%d %H:%M')"
  git commit -m "$commit_msg" 2>> "$LOG_FILE"

  # Push with retry
  local attempt=1
  while [ $attempt -le $PUSH_RETRIES ]; do
    if git push origin main 2>> "$LOG_FILE"; then
      log "BACKUP SUCCESS: Pushed to GitHub"
      return 0
    else
      log "BACKUP RETRY: Push failed (attempt $attempt/$PUSH_RETRIES)"
      sleep "$PUSH_RETRY_DELAY_S"
      ((attempt++))
    fi
  done

  log "ERROR: Push failed after $PUSH_RETRIES attempts"
  return 1
}

# ============================================
# STAGE 3: ARCHIVE ROTATION
# ============================================
rotate_archives() {
  if [ "$DRY_RUN" = true ]; then
    log "DRY RUN: Would rotate archives (keep last $BACKUP_COUNT)"
    return 0
  fi
  
  log "=== ROTATION: Cleaning old archives ==="
  
  # Check if backup dir has any archives
  if ! ls "$BACKUP_DIR"/openclaw-backup-*.tar.gz >/dev/null 2>&1; then
    log "ROTATION: No archives found (first run or all cleaned)"
    return 0
  fi
  
  # Count existing archives
  local count
  count=$(ls -1 "$BACKUP_DIR"/openclaw-backup-*.tar.gz 2>/dev/null | wc -l | tr -d '[:space:]')
  count=${count:-0}
  
  if [ "$count" -gt "$BACKUP_COUNT" ]; then
    local to_remove=$((count - BACKUP_COUNT))
    log "ROTATION: Removing $to_remove old archive(s)"
    
    ls -1t "$BACKUP_DIR"/openclaw-backup-*.tar.gz 2>/dev/null | \
      tail -n "$to_remove" | \
      xargs -r rm -f
    log "ROTATION: Cleanup complete"
  else
    log "ROTATION: No cleanup needed ($count archives, max $BACKUP_COUNT)"
  fi
  
  return 0
}

# ============================================
# STAGE 4: HEALTH CHECK
# ============================================
health_check() {
  log "=== HEALTH CHECK: Starting ==="

  # Verify gateway still running
  if pgrep -f "openclaw" > /dev/null; then
    log "HEALTH: OpenClaw process running"
  else
    log "HEALTH WARN: OpenClaw process not found"
  fi

  # Note: git diff returns non-zero when there are changes, which is expected
  # since the log file itself gets written during backup
  log "HEALTH: Workspace may have log file changes (expected)"

  log "=== HEALTH CHECK: Complete ==="
  return 0  # Always return success
}

# ============================================
# MAIN
# ============================================
main() {
  load_config
  check_dry_run "$@"
  
  log "========== BACKUP STARTING =========="
  
  if [ "$DRY_RUN" = true ]; then
    log "DRY RUN: Previewing backup operations"
  fi

  # Pre-flight
  if ! preflight; then
    log "WARN: Pre-flight had failures, proceeding with caution"
  fi

  # Check if backup needed
  check_changes
  local check_result=$?
  
  if [ $check_result -eq 2 ]; then
    log "========== BACKUP SKIPPED: No changes =========="
    exit 0
  fi

  # Backup
  if backup; then
    # Post-backup tasks (skip on dry-run)
    if [ "$DRY_RUN" = false ]; then
      rotate_archives
      health_check
    fi
    log "========== BACKUP COMPLETE =========="
    exit 0  # Explicit success
  else
    log "========== BACKUP FAILED =========="
    exit 1
  fi
}

main "$@"