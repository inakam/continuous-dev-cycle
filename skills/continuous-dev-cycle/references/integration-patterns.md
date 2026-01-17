# Integration Patterns: Ralph-Loop + Planning-with-Files

This document describes how continuous-dev-cycle integrates ralph-loop and planning-with-files.

## Architecture Overview

```
continuous-dev-cycle
├── planning-with-files (plan creation & tracking)
├── ralph-loop (iterative execution)
├── auto-commit (progress checkpointing)
└── expansion-proposer (continuous improvement)
```

## Component Integration

### 1. Planning-with-Files Integration

**How it's used:**
- Creates 3-file pattern at cycle start
- Uses templates from `templates/` directory
- Tracks progress in `task_plan.md`

**Template locations:**
```
continuous-dev-plugin/
└── templates/
    ├── task_plan.md
    ├── findings.md
    └── progress.md
```

**Hooks from planning-with-files that we adapt:**
- **PreToolUse**: Re-read plan before major decisions
- **PostToolUse**: Remind to update status
- **Stop**: Verify completion

### 2. Ralph-Loop Integration

**How it's used:**
- Uses Stop hook mechanism for loop continuation
- Stores state in `.claude/continuous-dev.local.md`
- Feeds prompt back on each iteration

**Key differences from vanilla ralph-loop:**
| Ralph-Loop | Continuous-Dev-Cycle |
|------------|---------------------|
| Single task, fixed prompt | Evolving tasks, expanding scope |
| Manual exit via promise | Auto-transition on completion |
| No commit tracking | Auto-commit on phase complete |
| Terminates on completion | Continues with expansions |

**Shared mechanisms:**
- Stop hook with "block" decision
- State file in `.claude/` directory
- Iteration counter in frontmatter
- Prompt feeding via "reason" field

### 3. Auto-Commit Integration

**Trigger condition:**
```bash
# In PostToolUse hook, after Write/Edit:
grep -q "^\- \[x\]" task_plan.md  # Phase completion check
```

**Commit logic:**
```bash
# scripts/auto-commit.sh
# 1. Parse task_plan.md for completed phase
# 2. Generate commit message
# 3. git add, commit, push
# 4. Update state with commit hash
```

**Commit message templates:**
```
[cycle N] Complete phase: ${phase_name}

${completed_bullets}

Files:
${changed_files}
```

### 4. Expansion-Proposer Integration

**Trigger:** Stop hook detects all phases complete

**Flow:**
```
Stop hook
  ↓
Check all phases complete
  ↓
Launch expansion-proposer agent
  ↓
Agent analyzes project and proposals
  ↓
Agent selects best proposal
  ↓
Create new task_plan.md for expansion
  ↓
Update cycle state (increment cycle)
  ↓
Feed new plan into ralph-loop
```

## State File Structure

### Ralph-Loop State (original)
```yaml
---
iteration: 1
max_iterations: 50
completion_promise: "COMPLETE"
---
[prompt text]
```

### Continuous-Dev-Cycle State (extended)
```yaml
---
cycle: 1
iteration: 1
max_cycles: 0
max_iterations: 0
task: "Build a todo API"
auto_commit: true
auto_expand: true
github_repo: "https://github.com/user/repo"
commit_history: []
expansions_completed: 0
---
[prompt text]
```

## Hook Chain Order

### PostToolUse Hook Chain
```
1. planning-with-files: "File updated. Update plan."
2. continuous-dev-cycle: Check phase completion
3. If complete: Trigger auto-commit
4. Update state with commit info
```

### Stop Hook Chain
```
1. planning-with-files: check-complete.sh
2. continuous-dev-cycle:
   a. Check all phases complete
   b. If yes: Trigger expansion proposal
   c. If no: Continue ralph-loop
3. ralph-loop: Continue iteration or exit
```

## File Coordination

### Phase Completion Detection
```bash
# In task_plan.md:
## Phase 1
- [x] Task 1.1
- [x] Task 1.2
- [ ] Task 1.3

# Detection:
# Count checkboxes in phase, count checked
# If equal, phase is complete
```

### Task Completion Detection
```bash
# In task_plan.md:
## Phase 1
- [x] All tasks

## Phase 2
- [x] All tasks

## Phase 3
- [x] All tasks

# Detection:
# If all phases have all checkboxes checked
# Task is complete, trigger expansion
```

## Prompt Evolution

### Cycle 1: Original Task
```
Build a REST API for todos.

Requirements:
- CRUD operations
- Input validation
- Tests

Output <promise>COMPLETE</promise> when all phases done.
```

### Cycle 2: Expansion Task
```
Previous cycle complete: Built REST API for todos.

Current expansion: Add filtering to list endpoints.

Requirements:
- Query parameter filtering (?status=active)
- Update tests
- Update docs

Output <promise>COMPLETE</promise> when all phases done.
```

### Cycle 3: Another Expansion
```
Previous cycles complete:
1. Built REST API
2. Added filtering

Current expansion: Add pagination.

Requirements:
- Page/limit parameters
- Update tests
- Update docs

Output <promise>COMPLETE</promise> when all phases done.
```

## Error Recovery

### If commit fails:
```bash
# Log error to progress.md
# Continue with cycle (don't block)
# Update state: last_commit_failed: true
```

### if expansion fails:
```bash
# Log error to progress.md
# Ask user for input (break automation)
# Or: Stop cycle gracefully
```

### If GitHub push fails:
```bash
# Log warning to progress.md
# Keep local commits
# Update state: sync_pending: true
```

## Best Practices

### 1. Always Read Plan First
```bash
# In PreToolUse hook:
cat task_plan.md | head -30
```

### 2. Update Plan Frequently
```bash
# After completing tasks:
# - Mark checkbox as [x]
# - Log any errors
# - Note files created
```

### 3. Commit Granularly
```
Good: "Complete phase: Add user model"
Bad: "Lots of stuff done"
```

### 4. Provide Context
```markdown
# In task_plan.md, at top:
**Cycle**: 2
**Previous**: Added filtering
**Current**: Adding pagination
**Next**: TBD (will be auto-generated)
```

### 5. Track Decisions
```markdown
## Decisions

### Cycle 1
- Chose Express.js for simplicity
- Used SQLite for zero-config

### Cycle 2
- Filtering via query params (not headers)
- Kept it simple for now

### Cycle 3
- Pagination: cursor-based (not offset)
```
