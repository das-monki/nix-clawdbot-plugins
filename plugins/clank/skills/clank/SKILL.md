---
name: clank
description: Minimal task and project management CLI
metadata: {"clawdbot":{"requires":{"bins":["clank"],"env":["CLANK_API"]}}}
---

Use `clank` to manage tasks and projects via the Clank API.

## Commands

### Projects

```bash
# List all projects
clank project list

# Create a new project
clank project new "My Project"

# Show project details
clank project show <project-id>

# Delete a project
clank project delete <project-id>
```

### Tasks

```bash
# List all tasks
clank list

# List tasks filtered by project
clank list -p <project-id>

# List tasks filtered by status
clank list -s backlog
clank list -s doing
clank list -s done

# Add a new task to a project
clank add "Task title" -p <project-id>

# Add a task with initial status
clank add "Task title" -p <project-id> -s doing

# Add a subtask (with parent)
clank add "Subtask title" -p <project-id> --parent <task-id>

# Show task details
clank show <task-id>

# Edit a task
clank edit <task-id> --title "New title"
clank edit <task-id> --description "New description"
clank edit <task-id> --spec "Detailed specification in markdown"
clank edit <task-id> -s done

# Move a task to a different status
clank move <task-id> -s doing
clank move <task-id> -s done

# Delete a task
clank delete <task-id>
```

### Task Statuses

- `backlog` - Tasks waiting to be started
- `doing` - Tasks currently in progress
- `done` - Completed tasks

## Configuration

Set the API URL via environment variable:
```bash
export CLANK_API=http://localhost:8080
```

Or use the `--api` flag:
```bash
clank --api http://localhost:8080 list
```

## When to Use

- When the user wants to manage project tasks with a kanban-style workflow
- When the user asks about their tasks or projects
- When the user wants to create, update, or move tasks between statuses
- When the user mentions clank or project management
- When tracking work items through backlog, doing, and done states
