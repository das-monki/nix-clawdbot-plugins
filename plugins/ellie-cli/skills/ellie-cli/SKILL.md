---
name: ellie-cli
description: CLI for ELLI Daily Planner API
metadata: {"clawdbot":{"requires":{"bins":["ellie"],"env":["ELLIE_API_KEY_FILE"]}}}
---

Use `ellie` to interact with the ELLI Daily Planner API for task management.

## Commands

### Tasks

```bash
# List tasks for a specific date
ellie tasks list --date 2025-01-28

# List tasks with timezone
ellie tasks list --date 2025-01-28 --timezone America/New_York

# Get unscheduled tasks (braindump)
ellie tasks braindump

# Get a specific task
ellie tasks get <task-id>

# Search tasks
ellie tasks search "meeting"

# Create a task
ellie tasks create --desc "Review pull request"

# Create a scheduled task
ellie tasks create --desc "Team standup" --date 2025-01-28 --start "09:00"

# Create with estimated time (in seconds)
ellie tasks create --desc "Code review" --estimated-time 1800

# Create with priority (1=Low, 2=Medium, 3=High, 4=Urgent)
ellie tasks create --desc "Fix critical bug" --priority 4

# Update a task
ellie tasks update <task-id> --desc "Updated description"

# Mark task complete
ellie tasks complete <task-id>

# Delete a task
ellie tasks delete <task-id>
```

### Lists

```bash
# List all lists
ellie lists list

# Get tasks by list
ellie tasks by-list --list-id <list-id>
```

### Labels

```bash
# List all labels
ellie labels list

# Get a specific label
ellie labels get <label-id>
```

### Users

```bash
# Get current user info
ellie users me
```

### Configuration

```bash
# Set API key (stored in ~/.config/ellie/config.yaml)
ellie config set-api-key <your-api-key>

# Show current configuration
ellie config show
```

## JSON Output

Add `--json` flag to any command for machine-readable output:

```bash
ellie --json tasks list --date 2025-01-28
ellie --json tasks braindump
```

## Configuration

The API key can be configured via:
1. `ELLIE_API_KEY` environment variable (direct key)
2. `ELLIE_API_KEY_FILE` environment variable (path to file containing key)
3. Config file via `ellie config set-api-key`

## When to Use

- When the user wants to manage their daily tasks or schedule
- When the user asks about their tasks for today or a specific date
- When the user wants to create, update, or complete tasks
- When the user wants to see unscheduled tasks (braindump)
- When the user mentions ELLI or daily planner
