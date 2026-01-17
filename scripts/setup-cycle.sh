#!/bin/bash

# Setup Script for Continuous Development Cycle
# Initializes planning files, git repository, and cycle state

set -euo pipefail

# Default values
MAX_CYCLES=0
MAX_ITERATIONS=0
AUTO_COMMIT=true
AUTO_EXPAND=true
GITHUB_REPO=""
TASK_DESCRIPTION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --max-cycles)
      MAX_CYCLES="$2"
      shift 2
      ;;
    --max-iterations)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --no-commit)
      AUTO_COMMIT=false
      shift
      ;;
    --no-expand)
      AUTO_EXPAND=false
      shift
      ;;
    --github-repo)
      GITHUB_REPO="$2"
      shift 2
      ;;
    *)
      if [[ -z "$TASK_DESCRIPTION" ]]; then
        TASK_DESCRIPTION="$1"
      fi
      shift
      ;;
  esac
done

# Validate task description
if [[ -z "$TASK_DESCRIPTION" ]]; then
  echo "❌ Error: Task description is required" >&2
  echo "Usage: /continuous-dev <TASK_DESCRIPTION> [options]" >&2
  exit 1
fi

echo "🚀 Initializing Continuous Development Cycle..."
echo ""

# Create .claude directory if it doesn't exist
mkdir -p .claude

# Create planning files from templates if they don't exist
if [[ ! -f "task_plan.md" ]]; then
  echo "📄 Creating task_plan.md..."
  cat > task_plan.md << 'EOF'
# Task Plan: [Task Title]

**Cycle**: 1
**Started**: [DATE]
**Previous**: None

## Goal
[TASK_DESCRIPTION]

## Phases

### Phase 1: Planning & Analysis
- [ ] Analyze requirements and dependencies
- [ ] Create project structure
- [ ] Set up development environment

**Status**: pending
**Started**: [DATE]
**Completed**: [DATE]

---

### Phase 2: Implementation
- [ ] Implement core functionality
- [ ] Add error handling
- [ ] Write tests

**Status**: pending
**Started**: [DATE]
**Completed**: [DATE]

---

### Phase 3: Documentation & Polish
- [ ] Write documentation
- [ ] Add examples
- [ ] Final review

**Status**: pending
**Started**: [DATE]
**Completed**: [DATE]

---

## Decisions

### [Decision 1]
**Context**: [what needed deciding]
**Decision**: [what was chosen]
**Rationale**: [why this choice]

---

## Errors Encountered

| Error | Attempt | Resolution |
|-------|---------|------------|
| [error description] | 1 | [how fixed] |

---

## Files Created/Modified

**Created**:
- `path/to/file1.ext` - {purpose}
- `path/to/file2.ext` - {purpose}

**Modified**:
- `path/to/file3.ext` - {changes made}

---

## Completion Criteria

This task is complete when:
- [ ] All phases implemented and tested
- [ ] Documentation complete
- [ ] Tests passing

**Completion**: Output `<promise>COMPLETE</promise>` when all criteria met.
EOF

  # Replace placeholders
  sed -i "s/\[TASK_DESCRIPTION\]/$TASK_DESCRIPTION/g" task_plan.md
  sed -i "s/\[DATE\]/$(date -Iseconds)/g" task_plan.md
  sed -i "s/\[Task Title\]/${TASK_DESCRIPTION:0:50}/g" task_plan.md
else
  echo "ℹ️  task_plan.md already exists"
fi

if [[ ! -f "findings.md" ]]; then
  echo "📄 Creating findings.md..."
  cat > findings.md << 'EOF'
# Findings: [Task Title]

**Cycle**: 1
**Last Updated**: [DATE]

## Research

### [Research Topic]
**Source**: [where found]
**Key Finding**: [what learned]
**Relevance**: [how it applies]

---

## Codebase Discoveries

### [Component/Feature]
**Location**: `path/to/file.ext:line`
**Discovery**: [what found]
**Implications**: [what it means]

---

## API/Library Notes

### [Library/Tool]
**Documentation**: [link or reference]
**Usage Pattern**: [how to use]
**Gotchas**: [common pitfalls]

---

## Configuration

### [Config Item]
**File**: `path/to/config`
**Setting**: {key} = {value}
**Purpose**: [what it controls]

---

## Notes

[General notes, observations, insights]
EOF
  sed -i "s/\[DATE\]/$(date -Iseconds)/g" findings.md
  sed -i "s/\[Task Title\]/${TASK_DESCRIPTION:0:50}/g" findings.md
else
  echo "ℹ️  findings.md already exists"
fi

if [[ ! -f "progress.md" ]]; then
  echo "📄 Creating progress.md..."
  cat > progress.md << 'EOF'
# Progress Log: [Task Title]

**Cycle**: 1
**Session Started**: [DATE]

## Session Timeline

### [Date/Time] - Session 1
**Iteration**: 1
**Focus**: Initial setup and planning

**Actions**:
- Created planning files
- Initialized git repository
- Set up project structure

**Results**:
- Project structure ready
- Cycle initialized

---

## Test Results

### [Test Suite/Name]
**Date**: [date]
**Status**: PASS | FAIL

```
[test output]
```

---

## Milestones Reached

### [Milestone Name]
**Date**: [date]
**Achievement**: [what was accomplished]

---

## Next Steps

1. [Next step 1]
2. [Next step 2]
3. [Next step 3]
EOF
  sed -i "s/\[DATE\]/$(date -Iseconds)/g" progress.md
  sed -i "s/\[Task Title\]/${TASK_DESCRIPTION:0:50}/g" progress.md
else
  echo "ℹ️  progress.md already exists"
fi

echo ""

# Initialize git repository if not already initialized
if [[ ! -d ".git" ]]; then
  echo "🔧 Initializing git repository..."
  git init
  git config user.email "continuous-dev@cycle"
  git config user.name "Continuous Dev Cycle"

  # Create GitHub repository if gh CLI is available and no repo specified
  if [[ -z "$GITHUB_REPO" ]]; then
    if command -v gh &>/dev/null; then
      echo "📦 Creating GitHub repository..."
      REPO_NAME=$(basename "$(pwd)")
      gh repo create "$REPO_NAME" --public --source=. --remote=origin --push 2>/dev/null || echo "⚠️  GitHub creation failed, continuing with local repo"
      GITHUB_REPO="auto-created"
    else
      echo "⚠️  gh CLI not found, using local git only"
      GITHUB_REPO="local"
    fi
  else
    echo "📦 Using existing GitHub repository: $GITHUB_REPO"
    git remote add origin "$GITHUB_REPO" 2>/dev/null || true
  fi

  # Initial commit
  git add -A
  git commit -m "Initial commit: Start continuous development cycle

Task: $TASK_DESCRIPTION

Cycle configuration:
- Max cycles: $MAX_CYCLES (0 = unlimited)
- Auto-commit: $AUTO_COMMIT
- Auto-expand: $AUTO_EXPAND"

  if git remote get-url origin &>/dev/null; then
    git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null || echo "⚠️  Initial push failed"
  fi
else
  echo "ℹ️  Git repository already initialized"
  # Set GITHUB_REPO from existing remote
  if [[ -z "$GITHUB_REPO" ]]; then
    GITHUB_REPO=$(git remote get-url origin 2>/dev/null || echo "local")
  fi
fi

echo ""

# Create cycle state file
echo "📝 Creating cycle state..."
CYCLE_STATE_FILE=".claude/continuous-dev.local.md"

cat > "$CYCLE_STATE_FILE" << EOF
---
cycle: 1
iteration: 1
max_cycles: $MAX_CYCLES
max_iterations: $MAX_ITERATIONS
task: $TASK_DESCRIPTION
auto_commit: $AUTO_COMMIT
auto_expand: $AUTO_EXPAND
github_repo: $GITHUB_REPO
commit_history: []
expansions_completed: 0
started_at: $(date -Iseconds)
---
$TASK_DESCRIPTION

Work through the phases in task_plan.md systematically. For each phase:
1. Read the phase requirements
2. Implement the tasks
3. Mark tasks as complete with [x]
4. Update phase status to **Status**: complete
5. Move to next phase

When ALL phases are complete, output <promise>COMPLETE</promise>.
EOF

echo ""
echo "✅ Continuous development cycle initialized!"
echo ""
echo "📋 Configuration:"
echo "  - Cycle: 1"
echo "  - Task: $TASK_DESCRIPTION"
echo "  - Max cycles: $MAX_CYCLES (0 = unlimited)"
echo "  - Auto-commit: $AUTO_COMMIT"
echo "  - Auto-expand: $AUTO_EXPAND"
echo "  - GitHub: $GITHUB_REPO"
echo ""
echo "📄 Planning files created:"
echo "  - task_plan.md - Your development plan"
echo "  - findings.md - Research and discoveries"
echo "  - progress.md - Session logs"
echo ""
echo "🚀 Start working on the first phase in task_plan.md."
echo "💡 The cycle will auto-commit when phases complete."
echo "🔄 When all phases are done, it will propose next expansions automatically."
echo ""
echo "🛑 To stop the cycle at any time: /cancel-continuous-dev"

exit 0
