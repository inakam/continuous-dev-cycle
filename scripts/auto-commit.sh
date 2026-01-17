#!/bin/bash

# Auto-Commit Script for Continuous Development Cycle
# Detects phase completion and commits changes

set -euo pipefail

# Check if continuous-dev cycle is active
CYCLE_STATE_FILE=".claude/continuous-dev.local.md"

if [[ ! -f "$CYCLE_STATE_FILE" ]]; then
  # No active cycle - exit silently
  exit 0
fi

# Check if auto-commit is enabled
AUTO_COMMIT=$(grep '^auto_commit:' "$CYCLE_STATE_FILE" | sed 's/auto_commit: *//' | sed 's/ //g')

if [[ "$AUTO_COMMIT" != "true" ]]; then
  exit 0
fi

# Check if task_plan.md exists
if [[ ! -f "task_plan.md" ]]; then
  exit 0
fi

# Parse cycle number
CYCLE=$(grep '^cycle:' "$CYCLE_STATE_FILE" | sed 's/cycle: *//')

# Function to check if a phase is complete
is_phase_complete() {
  local phase_text="$1"
  # Check if status line says complete
  if echo "$phase_text" | grep -q "^\*\*Status\*\*: complete"; then
    # Verify all checkboxes are marked [x]
    local checkboxes=$(echo "$phase_text" | grep "^- \[[x ]\]" || true)
    if [[ -n "$checkboxes" ]]; then
      local uncheck_count=$(echo "$checkboxes" | grep "\[ \]" | wc -l || echo "0")
      if [[ "$uncheck_count" -eq 0 ]]; then
        return 0  # Phase is complete
      fi
    fi
  fi
  return 1  # Phase is not complete
}

# Read task_plan.md and split into phases
CURRENT_PHASE=""
CURRENT_PHASE_TEXT=""
IN_PHASE=0
LAST_COMPLETE_PHASE=""

while IFS= read -r line; do
  if [[ "$line" =~ ^###\ Phase\ [0-9]+:\ (.+) ]]; then
    # New phase starts
    if [[ $IN_PHASE -eq 1 ]]; then
      # Check if previous phase was complete
      if is_phase_complete "$CURRENT_PHASE_TEXT"; then
        LAST_COMPLETE_PHASE="$CURRENT_PHASE"
      fi
    fi
    CURRENT_PHASE="${BASH_REMATCH[1]}"
    CURRENT_PHASE_TEXT=""
    IN_PHASE=1
  elif [[ $IN_PHASE -eq 1 ]]; then
    CURRENT_PHASE_TEXT="$CURRENT_PHASE_TEXT$line"$'\n'
    # End of phase section (next phase or end of file)
    if [[ "$line" =~ ^---$ ]] || [[ "$line" =~ ^###\ Phase\ [0-9]+ ]]; then
      IN_PHASE=0
    fi
  fi
done < task_plan.md

# Check last phase
if [[ $IN_PHASE -eq 1 ]] && is_phase_complete "$CURRENT_PHASE_TEXT"; then
  LAST_COMPLETE_PHASE="$CURRENT_PHASE"
fi

# If no complete phase found, exit
if [[ -z "$LAST_COMPLETE_PHASE" ]]; then
  exit 0
fi

# Check if this phase was already committed
COMMIT_MARKER=".claude/last_commit_phase.txt"
if [[ -f "$COMMIT_MARKER" ]]; then
  LAST_COMMITTED=$(cat "$COMMIT_MARKER" 2>/dev/null || echo "")
  if [[ "$LAST_COMMITTED" == "$LAST_COMPLETE_PHASE" ]]; then
    # Already committed this phase
    exit 0
  fi
fi

# Phase is complete and not yet committed - commit now
echo "📦 Continuous-dev: Phase complete - committing changes..."

# Get changed files
CHANGED_FILES=$(git status --short 2>/dev/null || echo "")
if [[ -z "$CHANGED_FILES" ]]; then
  # No changes to commit
  echo "$LAST_COMPLETE_PHASE" > "$COMMIT_MARKER"
  exit 0
fi

# Extract completed tasks from the phase
PHASE_TASKS=$(awk "/### Phase.*$LAST_COMPLETE_PHASE/,/---/" task_plan.md | grep "^\- \[x\]" | sed 's/^- \[x\] /  - /' || echo "  - Phase completed")

# Build commit message
COMMIT_MSG="[cycle $CYCLE] Complete phase: $LAST_COMPLETE_PHASE

$PHASE_TASKS

Files changed:
$(echo "$CHANGED_FILES" | sed 's/^/  /')"

# Commit changes
git add -A 2>/dev/null || true
if git diff --cached --quiet 2>/dev/null; then
  # Nothing to commit
  echo "$LAST_COMPLETE_PHASE" > "$COMMIT_MARKER"
  exit 0
fi

git commit -m "$COMMIT_MSG" 2>/dev/null || echo "⚠️  Git commit failed (possibly no changes)"

# Push if remote exists
if git remote get-url origin &>/dev/null; then
  git push 2>/dev/null || echo "⚠️  Git push failed (check remote)"
fi

# Get commit hash
COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

# Record this phase as committed
echo "$LAST_COMPLETE_PHASE" > "$COMMIT_MARKER"

# Update state with commit info
echo "" >> "$CYCLE_STATE_FILE"
echo "# Last commit" >> "$CYCLE_STATE_FILE"
echo "phase: $LAST_COMPLETE_PHASE" >> "$CYCLE_STATE_FILE"
echo "hash: $COMMIT_HASH" >> "$CYCLE_STATE_FILE"

echo "✅ Continuous-dev: Committed phase '$LAST_COMPLETE_PHASE' ($COMMIT_HASH)"

exit 0
