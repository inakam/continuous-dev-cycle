---
name: continuous-dev-cycle
version: "0.1.0"
description: This skill should be used when the user invokes "/continuous-dev" or "/continuous-dev-cycle", asks to "start continuous development", "enable auto-expanding development loop", or mentions combining planning-with-files with ralph-loop for perpetual development cycles. Integrates planning (task_plan.md/findings.md/progress.md), iterative execution (ralph-loop), auto-committing, and autonomous expansion proposals.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebFetch
  - WebSearch
---

# Continuous Development Cycle

Autonomous development cycle combining planning-with-files and ralph-loop. Plan, execute, commit, and expand forever.

## Overview

This skill creates a self-sustaining development loop:
1. **Plan**: Create task_plan.md with phases
2. **Execute**: Ralph-loop iterates until complete
3. **Commit**: Auto-commit on phase completion
4. **Expand**: Propose and select next improvement
5. **Repeat**: Cycle continues with new expansion

## Core Principle

```
Planning (task_plan.md) → Execution (ralph-loop) → Completion → Expansion → New Plan → ...
                                   ↓
                            Auto-commit on phase complete
```

## Quick Start

Invoke the cycle:
```
/continuous-dev "Build a REST API for todos with CRUD operations"
```

The cycle will:
1. Create planning files (task_plan.md, findings.md, progress.md)
2. Initialize git and GitHub repository
3. Start ralph-loop execution
4. Auto-commit on phase completion
5. When complete, propose expansions and continue

## File Structure

Create these files in your project directory (not in plugin directory):

```
project-root/
├── .claude/
│   └── continuous-dev.local.md  # Cycle state (auto-created)
├── task_plan.md                 # Your current plan
├── findings.md                  # Research and discoveries
└── progress.md                  # Session logs
```

**Templates**: Use templates in `templates/` directory as starting points.

## The 3-File Pattern (from planning-with-files)

### task_plan.md
Track phases, checkboxes, completion status:
```markdown
## Phase 1: Implementation
- [x] Set up project structure
- [x] Implement API endpoints
- [ ] Add tests

**Status**: in_progress
```

### findings.md
Store research, discoveries, documentation:
```markdown
## Express.js Patterns
- Use middleware for auth
- Async/await for routes
```

### progress.md
Log session activity, test results:
```markdown
### Session 1
- Implemented GET /todos
- Tests passing
```

## Phase Completion & Auto-Commit

**When a phase completes** (all checkboxes marked `[x]`):
1. PostToolUse hook detects completion
2. Auto-commit script runs:
   - Commits with message: `[cycle N] Complete phase: {Phase Name}`
   - Pushes to GitHub
3. Updates cycle state with commit hash

**To mark phase complete**:
1. Check all boxes: `- [x]` for each task
2. Update status: `**Status**: complete`
3. Update completion date
4. Next Write/Edit triggers the commit

## Ralph-Loop Integration

The cycle uses ralph-loop's Stop hook mechanism:

**State file** (`.claude/continuous-dev.local.md`):
```yaml
---
cycle: 1
iteration: 1
max_cycles: 0  # 0 = unlimited
auto_commit: true
auto_expand: true
---
Build a REST API...
```

**How it works**:
1. You work on task from prompt
2. Try to exit
3. Stop hook checks if complete
4. If not complete: feeds same prompt back
5. If complete: triggers expansion proposal

## Expansion & Auto-Continuation

**When all phases complete**:
1. Stop hook detects task completion
2. Launches expansion-proposer agent
3. Agent analyzes project for improvements:
   - Code quality (refactoring, cleanup)
   - Testing (coverage, edge cases)
   - Documentation (API docs, README)
   - Performance (optimizations)
   - Features (natural extensions)
4. Agent selects highest-value proposal
5. Creates new task_plan.md for expansion
6. Increments cycle counter
7. Ralph-loop continues with new plan

**Example expansions**:
```
Cycle 1: Build basic API
Cycle 2: Add filtering (improvement)
Cycle 3: Add pagination (feature)
Cycle 4: Improve error handling (quality)
Cycle 5: Add rate limiting (feature)
...continues until no valuable improvements found
```

## Completion Criteria

To complete a cycle and trigger expansion:
1. All phases marked complete: `**Status**: complete`
2. All checkboxes checked: `- [x]`
3. Output completion promise: `<promise>COMPLETE</promise>`

The Stop hook verifies all criteria before triggering expansion.

## Cancellation

Stop the cycle at any time:
```
/cancel-continuous-dev
```

This:
1. Removes `.claude/continuous-dev.local.md`
2. Allows normal exit
3. Preserves all work and commits

## GitHub Integration

**On cycle start** (if auto_create is true):
1. Initializes git repo if needed
2. Creates GitHub repo via `gh repo create`
3. Sets remote origin
4. Pushes initial commit

**Each auto-commit**:
1. Stages all changes: `git add -A`
2. Commits with descriptive message
3. Pushes to origin

## Critical Rules

### 1. Always Read Plan First
Before making decisions, read task_plan.md to stay aligned with goals.

### 2. Update Plan Frequently
Mark checkboxes as you complete tasks. Don't batch updates.

### 3. Log Discoveries
Save research to findings.md before context resets.

### 4. Mark Phases Complete
When all phase tasks are done:
- Mark all checkboxes: `- [x]`
- Set status: `**Status**: complete`
- Add completion date
- Next file write triggers auto-commit

### 5. Trust the Cycle
The cycle will:
- Detect completion automatically
- Commit your progress
- Propose next steps
- Continue the work

## When to Use This Pattern

**Use for**:
- Complex multi-step tasks (3+ phases)
- Projects requiring iteration and refinement
- Tasks with clear success criteria
- Greenfield projects you can walk away from
- Continuous improvement scenarios

**Don't use for**:
- Single-line bug fixes
- Trivial changes
- Tasks requiring human judgment
- Production debugging emergencies

## Templates

Use these templates to start planning files:

- **templates/task_plan.md** - Phase tracking
- **templates/findings.md** - Research storage
- **templates/progress.md** - Session logging

Copy templates to your project directory and customize.

## Advanced Configuration

**Cycle state options** (in `.claude/continuous-dev.local.md`):
```yaml
---
auto_commit: true      # Enable auto-commit
auto_expand: true      # Enable auto-expansion
max_cycles: 0          # 0 = unlimited, N = limit
github_repo: "auto"    # "auto" or URL
---
```

## Additional Resources

### Reference Files

For detailed workflow and integration patterns:
- **references/cycle-workflow.md** - Complete cycle phases and state management
- **references/integration-patterns.md** - How ralph-loop and planning-with-files integrate

### Scripts

Utility scripts in `scripts/`:
- **setup-cycle.sh** - Initialize cycle state
- **auto-commit.sh** - Auto-commit on phase complete
- **propose-expansion.sh** - Generate expansion proposals
