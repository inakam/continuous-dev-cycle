#!/bin/bash

# Continuous Development Cycle Stop Hook
# Extends ralph-loop mechanism to trigger expansion proposals on completion

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Check if continuous-dev cycle is active
CYCLE_STATE_FILE=".claude/continuous-dev.local.md"

if [[ ! -f "$CYCLE_STATE_FILE" ]]; then
  # No active cycle - allow exit
  exit 0
fi

# Parse markdown frontmatter (YAML between ---)
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$CYCLE_STATE_FILE")
CYCLE=$(echo "$FRONTMATTER" | grep '^cycle:' | sed 's/cycle: *//')
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_CYCLES=$(echo "$FRONTMATTER" | grep '^max_cycles:' | sed 's/max_cycles: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
AUTO_EXPAND=$(echo "$FRONTMATTER" | grep '^auto_expand:' | sed 's/auto_expand: *//')
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')

# Validate numeric fields
if [[ ! "$CYCLE" =~ ^[0-9]+$ ]] || [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Continuous-dev: State file corrupted" >&2
  rm "$CYCLE_STATE_FILE"
  exit 0
fi

# Check max cycles limit
if [[ "$MAX_CYCLES" =~ ^[0-9]+$ ]] && [[ "$MAX_CYCLES" -gt 0 ]] && [[ "$CYCLE" -ge "$MAX_CYCLES" ]]; then
  echo "🛑 Continuous-dev: Max cycles ($MAX_CYCLES) reached."
  rm "$CYCLE_STATE_FILE"
  exit 0
fi

# Check max iterations limit
if [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] && [[ "$MAX_ITERATIONS" -gt 0 ]] && [[ "$ITERATION" -ge "$MAX_ITERATIONS" ]]; then
  echo "🛑 Continuous-dev: Max iterations ($MAX_ITERATIONS) reached for cycle $CYCLE."
  rm "$CYCLE_STATE_FILE"
  exit 0
fi

# Get transcript path
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️  Continuous-dev: Transcript not found, stopping cycle" >&2
  rm "$CYCLE_STATE_FILE"
  exit 0
fi

# Read last assistant message
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  echo "⚠️  Continuous-dev: No assistant messages, stopping cycle" >&2
  rm "$CYCLE_STATE_FILE"
  exit 0
fi

LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
  .message.content |
  map(select(.type == "text")) |
  map(.text) |
  join("\n")
' 2>&1)

if [[ $? -ne 0 ]] || [[ -z "$LAST_OUTPUT" ]]; then
  echo "⚠️  Continuous-dev: Failed to parse output, stopping cycle" >&2
  rm "$CYCLE_STATE_FILE"
  exit 0
fi

# Check for completion promise
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")

  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
    echo "✅ Continuous-dev: Cycle $CYCLE complete - <promise>$COMPLETION_PROMISE</promise>"

    # Check if auto-expand is enabled
    if [[ "$AUTO_EXPAND" == "true" ]]; then
      echo "🔄 Continuous-dev: Triggering expansion proposal for next cycle..."

      # Update state for next cycle
      NEXT_CYCLE=$((CYCLE + 1))
      TEMP_FILE="${CYCLE_STATE_FILE}.tmp.$$"
      sed "s/^cycle: .*/cycle: $NEXT_CYCLE/" "$CYCLE_STATE_FILE" > "$TEMP_FILE"
      sed -i "s/^iteration: .*/iteration: 1/" "$TEMP_FILE"
      mv "$TEMP_FILE" "$CYCLE_STATE_FILE"

      # Build expansion prompt
      EXPANSION_PROMPT="The current development cycle ($CYCLE) is complete.

Analyze the project and propose the next expansion. Use the expansion-proposer agent to:
1. Review task_plan.md, findings.md, progress.md
2. Analyze source code for improvements
3. Generate and score proposals
4. Select the best proposal
5. Create new task_plan.md for the selected expansion

If no valuable expansions are found, output <promise>NO_EXPANSIONS</promise> and stop the cycle.
Otherwise, start implementing the new plan and output <promise>COMPLETE</promise> when done."

      # Output JSON to feed expansion prompt
      jq -n \
        --arg prompt "$EXPANSION_PROMPT" \
        --arg msg "🔄 Cycle $NEXT_CYCLE | Expansion phase" \
        '{
          "decision": "block",
          "reason": $prompt,
          "systemMessage": $msg
        }'

      exit 0
    else
      echo "✅ Continuous-dev: Cycle complete (auto-expand disabled)"
      rm "$CYCLE_STATE_FILE"
      exit 0
    fi
  fi
fi

# Check for no-expansions signal
if echo "$LAST_OUTPUT" | grep -q "<promise>NO_EXPANSIONS</promise>"; then
  echo "⏹️  Continuous-dev: No valuable expansions found. Stopping cycle."
  rm "$CYCLE_STATE_FILE"
  exit 0
fi

# Not complete - continue with current cycle
NEXT_ITERATION=$((ITERATION + 1))

# Extract prompt from state file
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$CYCLE_STATE_FILE")

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "⚠️  Continuous-dev: State file corrupted" >&2
  rm "$CYCLE_STATE_FILE"
  exit 0
fi

# Update iteration
TEMP_FILE="${CYCLE_STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$CYCLE_STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$CYCLE_STATE_FILE"

# Build system message
SYSTEM_MSG="🔄 Cycle $CYCLE | Iteration $NEXT_ITERATION | Complete task and output <promise>$COMPLETION_PROMISE</promise>"

# Output JSON to continue loop
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
