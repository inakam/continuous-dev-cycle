# Continuous Dev Cycle

A Claude Code plugin that creates self-sustaining development cycles by integrating planning-with-files and ralph-loop. Plan, execute, commit progress, and autonomously propose expansions—forever.

## What is Continuous Dev Cycle?

This plugin combines two powerful patterns into an autonomous development loop:

1. **Planning with Files** - Uses persistent markdown files (task_plan.md, findings.md, progress.md) as "working memory on disk"
2. **Ralph Loop** - Iterative execution that continues until task completion
3. **Auto-Commit** - Commits progress automatically when phases complete
4. **Autonomous Expansion** - AI-generated proposals for next improvements/features

The result: A development cycle that plans, executes, commits, and then proposes and implements the next improvement—continuing indefinitely until no valuable expansions remain.

## Quick Start

```bash
# Start a continuous development cycle
/continuous-dev "Build a REST API for todos with CRUD operations, tests, and documentation"

# The cycle will:
# 1. Create planning files (task_plan.md, findings.md, progress.md)
# 2. Initialize git and GitHub repository
# 3. Execute the task with ralph-loop iterations
# 4. Auto-commit when phases complete
# 5. When complete, propose and implement next expansion
# 6. Repeat forever (or until canceled)

# Stop the cycle at any time
/cancel-continuous-dev
```

## How It Works

### The Cycle Flow

```
┌─────────────────────────────────────────────────────────────┐
│  START: /continuous-dev "Build a todo API"                  │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  PHASE 1: Planning                                          │
│  - Create task_plan.md with phases                          │
│  - Create findings.md for research                          │
│  - Create progress.md for logs                              │
│  - Initialize git/GitHub repository                         │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  PHASE 2: Execution (Ralph Loop)                           │
│  - Read task_plan.md before decisions                       │
│  - Work on current phase tasks                              │
│  - Mark tasks complete: [x]                                 │
│  - Update phase status: **Status**: complete                │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  PHASE 3: Auto-Commit                                       │
│  - Detect phase completion (all [x] + status: complete)     │
│  - git add, commit, push                                    │
│  - Commit message: "[cycle N] Complete phase: {name}"      │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
                All phases complete?
                           │
              ┌────────────┴────────────┐
              │ No                       │ Yes
              ▼                          ▼
┌──────────────────────┐    ┌─────────────────────────────┐
│ Continue Ralph Loop  │    │ PHASE 4: Expansion Proposal │
│ (next iteration)     │    │ - Analyze project            │
└──────────────────────┘    │ - Generate proposals         │
                            │ - Score by impact/effort     │
                            │ - Select best proposal       │
                            │ - Create new task_plan.md    │
                            │ - Increment cycle number     │
                            └──────────────┬───────────────┘
                                           │
                                           └──────────► Back to PHASE 2
```

### Phase Completion & Auto-Commit

When you complete all tasks in a phase:
1. Mark all checkboxes: `- [x]`
2. Set status: `**Status**: complete`
3. The next Write/Edit triggers auto-commit
4. Changes are committed and pushed to GitHub

### Task Completion & Expansion

When ALL phases are complete:
1. Output: `<promise>COMPLETE</promise>`
2. Stop hook detects completion
3. Expansion-proposer agent analyzes project
4. Generates proposals (refactoring, features, tests, docs, performance)
5. Selects highest-value proposal
6. Creates new task_plan.md
7. Ralph-loop continues with new expansion
8. Cycle repeats

### Termination

The cycle stops when:
- **User cancellation**: `/cancel-continuous-dev`
- **No expansions found**: Agent can't identify valuable improvements
- **Max cycles reached**: If `--max-cycles N` was set

## Commands

### /continuous-dev

Start the autonomous development cycle.

**Usage:**
```bash
/continuous-dev "<TASK_DESCRIPTION>" [options]
```

**Arguments:**
- `TASK_DESCRIPTION` (required): What you want to build
- `--max-cycles N`: Stop after N cycles (default: unlimited)
- `--max-iterations N`: Max ralph-loop iterations per cycle (default: unlimited)
- `--no-commit`: Disable auto-committing
- `--no-expand`: Disable auto-expansion
- `--github-repo URL`: Use existing GitHub repo

**Examples:**
```bash
/continuous-dev "Build a REST API for todos"
/continuous-dev "Create a web scraper for news sites" --max-cycles 5
/continuous-dev "Add authentication system" --no-commit --github-repo https://github.com/user/repo
```

### /cancel-continuous-dev

Stop the active development cycle.

**Usage:**
```bash
/cancel-continuous-dev
```

**What happens:**
- Removes cycle state file
- Allows normal exit
- All work preserved in planning files
- All commits remain in git history

## Planning Files

The cycle creates three markdown files in your project directory:

### task_plan.md
Tracks phases and progress:
```markdown
## Phase 1: Implementation
- [x] Set up project structure
- [x] Create API endpoints
- [ ] Add tests

**Status**: in_progress
```

### findings.md
Stores research and discoveries:
```markdown
## Express.js Patterns
- Use middleware for authentication
- Async/await for route handlers
```

### progress.md
Logs session activity:
```markdown
### Session 1
- Implemented GET /todos
- Tests passing (5/5)
```

## Example Cycle

```
User: /continuous-dev "Build a REST API for todos"

[Cycle 1]
Plan: Create REST API with CRUD operations
Execute: Implement endpoints, tests, docs
Commit: "Complete phase: API implementation"
Complete: All phases done, output <promise>COMPLETE</promise>

[Cycle 2 - Auto]
Analyze: Find improvements
Proposals:
  - Add filtering (High priority)
  - Add pagination (Medium priority)
  - Improve error handling (Low priority)
Select: Add filtering
Plan: Implement filtering on list endpoints
Execute: Add query parameters, update tests
Complete: <promise>COMPLETE</promise>

[Cycle 3 - Auto]
Analyze: More improvements
Proposals:
  - Add pagination (High priority)
  - Add sorting (Medium priority)
Select: Add pagination
...continues until no valuable expansions found
```

## Expansion Categories

The expansion-proposer agent considers these categories:

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

## Configuration

Cycle state is stored in `.claude/continuous-dev.local.md`:

```yaml
---
cycle: 1
iteration: 1
max_cycles: 0  # 0 = unlimited
max_iterations: 0
auto_commit: true
auto_expand: true
github_repo: "auto-created"
started_at: 2026-01-17T23:00:00+00:00
---
```

## Requirements

- Claude Code installed
- Git installed
- gh CLI (optional, for GitHub auto-creation)

## Installation

### From Marketplace (Coming Soon)

```bash
/plugin marketplace add ibuki-nakamura/continuous-dev-cycle
/plugin install continuous-dev-cycle@continuous-dev-cycle
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/ibuki-nakamura/continuous-dev-cycle.git ~/.claude/plugins/continuous-dev-cycle

# Or add to your plugin marketplace list
```

## Philosophy

This plugin embodies several principles:

### 1. Filesystem as Memory
```
Context Window = RAM (volatile, limited)
Filesystem = Disk (persistent, unlimited)

→ Anything important goes to disk
```

### 2. Iteration > Perfection
Don't aim for perfect on first try. Let the cycle refine the work through multiple iterations.

### 3. Continuous Improvement
Every completion is a starting point for the next expansion. The best code is constantly evolving.

### 4. Autonomous Development
Once started, the cycle manages itself:
- Tracks progress
- Commits changes
- Proposes improvements
- Executes expansions

## Best Practices

### 1. Be Specific with Tasks
```
Good: "Build a REST API for todos with CRUD operations, input validation, tests"
Bad: "Build a todo thing"
```

### 2. Trust the Cycle
The cycle will detect completion automatically. Don't rush to mark things complete.

### 3. Review Proposals
Each expansion proposal includes impact/effort scoring. Review the agent's reasoning.

### 4. Monitor Commits
Check commit history to see progress. Each commit represents a completed phase.

### 5. Know When to Stop
If expansions aren't valuable, use `/cancel-continuous-dev` to stop the cycle.

## When to Use

**Good for:**
- Multi-step projects (3+ phases)
- Tasks requiring iteration and refinement
- Projects with clear success criteria
- Greenfield development
- Continuous improvement scenarios

**Not good for:**
- Single-line bug fixes
- Trivial changes
- Tasks requiring human judgment
- Production debugging emergencies

## Architecture

### Components

**Commands:**
- `/continuous-dev` - Start cycle
- `/cancel-continuous-dev` - Stop cycle

**Agents:**
- `expansion-proposer` - Analyzes project and generates proposals
- `progress-tracker` - Monitors phase completion

**Skills:**
- `continuous-dev-cycle` - Main cycle knowledge and workflows

**Hooks:**
- Stop hook - Detects completion and triggers expansion
- PostToolUse hook - Detects phase completion and commits

**Scripts:**
- `setup-cycle.sh` - Initializes cycle state
- `auto-commit.sh` - Commits on phase completion
- `stop-hook.sh` - Handles loop continuation

### Integration

This plugin integrates:
- **planning-with-files** - 3-file planning pattern
- **ralph-loop** - Iterative execution mechanism

## Troubleshooting

### Cycle won't stop
```bash
/cancel-continuous-dev
# Or manually remove:
rm .claude/continuous-dev.local.md
```

### Auto-commit not working
- Check if auto_commit is true in state file
- Verify phase status is "**Status**: complete"
- Ensure all checkboxes are marked `[x]`

### GitHub push failing
- Check gh CLI is installed and authenticated
- Verify remote origin is set correctly
- Check network connectivity

### No expansions generated
- This is normal if project is complete
- Cycle will terminate gracefully
- All work is preserved

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - feel free to use, modify, and distribute.

## Acknowledgments

- **planning-with-files** by Ahmad Othman Ammar Adi - File-based planning pattern
- **ralph-loop** by Anthropic - Iterative execution mechanism
- **Manus AI** - Context engineering principles

## Author

ibuki-nakamura

## Version

0.1.0 (Alpha)
