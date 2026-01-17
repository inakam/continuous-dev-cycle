---
description: "Start the continuous development cycle with planning, iterative execution, auto-committing, and autonomous expansion"
argument-hint: "<TASK_DESCRIPTION> [--max-cycles N] [--max-iterations N] [--no-commit] [--no-expand] [--github-repo URL]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-cycle.sh:*)", "Read", "Write", "Edit", "Glob", "Grep"]
hide-from-slash-command-tool: "false"
---

# Continuous Dev Command

Start the autonomous development cycle that integrates planning-with-files and ralph-loop.

## Execution

Initialize the continuous development cycle:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-cycle.sh" $ARGUMENTS
```

After initialization, work on the task following the plan in `task_plan.md`. The cycle will:
1. Track progress in planning files (task_plan.md, findings.md, progress.md)
2. Auto-commit when phases complete
3. When all phases complete, propose and start next expansion
4. Continue indefinitely until canceled or no expansions found

## Arguments

- **TASK_DESCRIPTION** (required): The main task to work on
- **--max-cycles N**: Stop after N cycles (default: unlimited)
- **--max-iterations N**: Max ralph-loop iterations per cycle (default: unlimited)
- **--no-commit**: Disable auto-committing
- **--no-expand**: Disable auto-expansion
- **--github-repo URL**: Use existing GitHub repo instead of auto-creating

## Examples

```bash
/continuous-dev "Build a REST API for todos with CRUD operations, tests, and documentation"
/continuous-dev "Create a web scraper" --max-cycles 5
/continuous-dev "Implement authentication system" --no-commit --github-repo https://github.com/user/repo
```

## Completion

To complete a phase:
1. Mark all checkboxes: `- [x]` in task_plan.md
2. Set status: `**Status**: complete`
3. Next file write triggers auto-commit

To complete the entire cycle:
1. All phases must be complete
2. Output: `<promise>COMPLETE</promise>`

The cycle will then propose expansions and continue automatically.

## Cancellation

Stop the cycle at any time:
```
/cancel-continuous-dev
```

## Important Notes

- Planning files are created in current working directory
- GitHub repo auto-created via `gh` CLI if --github-repo not specified
- Auto-commits happen on phase completion
- Expansions are AI-generated and auto-selected
- Cycle continues until canceled or no valuable expansions found
