---
description: "Cancel the active continuous development cycle and stop the autonomous loop"
argument-hint: "[--keep-state]"
allowed-tools: ["Bash", "Read"]
hide-from-slash-command-tool: "false"
---

# Cancel Continuous Dev Command

Cancel the active continuous development cycle.

## Execution

Remove the cycle state file to stop the loop:

```!
STATE_FILE=".claude/continuous-dev.local.md"
if [ -f "$STATE_FILE" ]; then
  echo "🛑 Stopping continuous development cycle..."
  rm "$STATE_FILE"
  echo "✅ Cycle stopped. You can now exit normally."
  echo ""
  echo "Summary preserved in:"
  echo "  - task_plan.md"
  echo "  - findings.md"
  echo "  - progress.md"
else
  echo "ℹ️  No active continuous development cycle found."
fi
```

## Arguments

- **--keep-state**: Keep the state file for inspection (cycle won't actually stop)

## What Happens

1. Removes `.claude/continuous-dev.local.md`
2. Stop hook no longer blocks exit
3. Ralph-loop terminates
4. All work preserved in planning files
5. Git commits remain

## After Cancellation

- All planning files remain (task_plan.md, findings.md, progress.md)
- All commits remain in git history
- GitHub repository remains intact
- You can restart with `/continuous-dev` anytime

## Example

```bash
/cancel-continuous-dev
```

Output:
```
🛑 Stopping continuous development cycle...
✅ Cycle stopped. You can now exit normally.

Summary preserved in:
  - task_plan.md
  - findings.md
  - progress.md
```
