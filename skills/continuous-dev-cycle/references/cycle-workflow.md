# Continuous Development Cycle Workflow

This document describes the detailed workflow of the continuous development cycle.

## The Cycle Phases

### Phase 1: Initial Planning

When the user invokes `/continuous-dev` with a task:

1. **Create planning files** using planning-with-files templates:
   - `task_plan.md` - Track phases and progress
   - `findings.md` - Store research and discoveries
   - `progress.md` - Session log and test results

2. **Set up ralph-loop state** in `.claude/continuous-dev.local.md`:
   ```yaml
   ---
   cycle: 1
   iteration: 1
   max_cycles: 0  # 0 = unlimited
   task: "Original user task description"
   auto_commit: true
   auto_expand: true
   github_repo: "auto-created"
   ---
   ```

3. **Initialize git repository** if not already initialized:
   - Run `git init` if needed
   - Create GitHub repository using `gh repo create`
   - Set remote origin

### Phase 2: Execution Loop

The ralph-loop mechanism iterates until task completion:

1. **Read plan** before each decision (via PreToolUse hook)
2. **Execute work** on the current phase
3. **Update progress** after file operations (via PostToolUse hook)
4. **Check for phase completion** after each file write

### Phase 3: Auto-Commit on Phase Complete

When a phase is marked complete in `task_plan.md`:

1. **PostToolUse hook** detects the completion
2. **Auto-commit script** runs:
   ```bash
   git add -A
   git commit -m "Complete phase: [phase name]

   - [completed tasks]
   - [files changed]"
   git push
   ```
3. **Update cycle state** with commit hash

### Phase 4: Task Completion Detection

When all phases in `task_plan.md` are complete:

1. **Stop hook** intercepts the exit attempt
2. **Triggers expansion proposal** agent
3. **Analyzes current project** for improvements and new features

### Phase 5: Expansion Proposal

The expansion-proposer agent:

1. **Analyzes project**:
   - Code quality issues (refactoring opportunities)
   - Missing tests
   - Documentation gaps
   - Performance optimizations
   - New feature opportunities based on existing functionality

2. **Generates proposals** with scores:
   - Impact: High/Medium/Low
   - Effort: High/Medium/Low
   - Priority: Calculated (Impact/Effort)

3. **Selects best proposal** (highest Priority)

4. **Creates new plan** from selected proposal

### Phase 6: Cycle Continuation

1. **Updates cycle state**:
   ```yaml
   ---
   cycle: 2  # Incremented
   iteration: 1  # Reset
   previous_cycle_summary: "..."
   ---
   ```

2. **Feeds new plan** into ralph-loop

3. **Process repeats** from Phase 2

### Phase 7: Termination

The cycle stops when:

1. **No expansions found** - Agent cannot identify valuable improvements
2. **User cancellation** - `/cancel-continuous-dev` invoked
3. **Max cycles reached** - If `max_cycles` is set

## File Structure

```
project-root/
├── .claude/
│   └── continuous-dev.local.md  # Cycle state
├── task_plan.md                 # Current plan phases
├── findings.md                  # Research and discoveries
├── progress.md                  # Session logs
└── [project files]
```

## State Management

The cycle state file (`.claude/continuous-dev.local.md`) tracks:

- **cycle**: Current cycle number (starts at 1)
- **iteration**: Current ralph-loop iteration
- **max_cycles**: Maximum cycles before stop (0 = unlimited)
- **task**: Original user task or current expansion
- **auto_commit**: Enable/disable auto-commits
- **auto_expand**: Enable/disable auto-expansion
- **github_repo**: Repository URL or "auto-created"
- **commit_history**: List of commit hashes for this cycle

## Commit Strategy

Commits happen at specific checkpoints:

1. **Phase complete** - All checkboxes in a phase marked
2. **Task complete** - All phases complete
3. **Expansion start** - New cycle begins

Commit message format:
```
[cycle N] Complete phase: [Phase Name]

- Completed task 1
- Completed task 2

Files changed:
- path/to/file1.ts (new)
- path/to/file2.ts (modified)
```

## Expansion Categories

The agent considers these expansion types:

### Code Quality
- Refactoring opportunities
- Code duplication elimination
- Design pattern improvements

### Testing
- Missing unit tests
- Integration test coverage
- End-to-end test scenarios

### Documentation
- API documentation
- README improvements
- Code comments and docstrings

### Performance
- Optimization opportunities
- Caching strategies
- Resource usage improvements

### Features
- Natural feature extensions
- Configuration options
- Integration opportunities

## Example Cycle Flow

```
User: /continuous-dev "Build a todo API"

[Cycle 1]
Plan: Create REST API with CRUD operations
Execute: Implement endpoints, tests, docs
Commit: "Complete phase: API implementation"
Complete: All phases done

[Cycle 2 - Auto]
Analyze: Find improvements
Propose: Add rate limiting, add filtering, improve docs
Select: Add filtering (highest priority)
Plan: Implement filtering on list endpoints
Execute: Add query parameters, update tests
Commit: "Complete phase: Filtering implementation"
Complete: All phases done

[Cycle 3 - Auto]
Analyze: Find more improvements
Propose: Add pagination, add sorting, add rate limiting
Select: Add pagination (highest priority)
...continues until no valuable expansions found
```
