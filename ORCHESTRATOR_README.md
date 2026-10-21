# Universal Task Orchestrator

A reusable, project-agnostic task orchestration harness for managing complex multi-agent workflows across any project.

## Features

- **Declarative Workflows**: Define workflows in YAML/JSON
- **Dependency Management**: Automatic topological ordering with `depends_on`
- **Parallel Execution**: Configurable worker pool with priority queue
- **Multiple Executors**: Shell, OpenCode Agent, Git, Custom
- **Retry Logic**: Exponential backoff with configurable retries
- **Priority Queue**: Task priorities (LOW, NORMAL, HIGH, CRITICAL)
- **Artifact Tracking**: Track and verify build artifacts
- **Failure Handling**: Stop, continue, or retry on failure
- **Rich Logging**: Structured logging with progress tracking
- **Cross-Project**: Single binary works across any project

## Quick Start

### 1. Install
```bash
# Copy orchestrator.py to your project or install globally
cp orchestrator.py /usr/local/bin/orchestrator
chmod +x /usr/local/bin/orchestrator
```

### 2. Create a Workflow (YAML)
```yaml
# workflow.yaml
name: "My Pipeline"
version: "1.0.0"
description: "Build and deploy my app"
working_dir: "."
max_parallel: 4
on_failure: "stop"

tasks:
  - id: test
    name: "Run Tests"
    command: "pytest -v"
    priority: "HIGH"

  - id: build
    name: "Build App"
    command: "cargo build --release"
    depends_on: ["test"]
    timeout: 300.0

  - id: deploy
    name: "Deploy"
    command: "./deploy.sh"
    depends_on: ["build"]
    agent: "deploy-agent"
    prompt: "Deploy to production with health checks"
    model: "openrouter/anthropic/claude-3.5-sonnet"
```

### 3. Run
```bash
orchestrator --config workflow.yaml --max-parallel 4
```

## Task Types

### Shell Command
```yaml
- id: build
  command: "make build"
  depends_on: ["test"]
```

### Shell Script (multi-line)
```yaml
- id: deploy
  script: |
    echo "Deploying to production..."
    kubectl apply -f k8s/
    sleep 10
    kubectl rollout status deployment/myapp
```

### OpenCode Agent
```yaml
- id: review
  name: "Code Review"
  agent: "reviewer"
  model: "openrouter/anthropic/claude-3.5-sonnet"
  prompt: "Review the diff for security issues and performance"
  depends_on: ["build"]
```

## Task Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | string | Auto | Unique task ID (auto-generated if omitted) |
| `name` | string | Yes | Human-readable name |
| `description` | string | No | Detailed description |
| `command` | string | No* | Single shell command |
| `script` | string | No* | Multi-line shell script |
| `agent` | string | No* | OpenCode agent name |
| `model` | string | No | Model for agent |
| `prompt` | string | Yes (if agent) | Prompt for agent |
| `depends_on` | list[str] | No | Task IDs this depends on |
| `priority` | enum | No | LOW, NORMAL, HIGH, CRITICAL |
| `max_retries` | int | No | Retry attempts (default: 3) |
| `retry_delay` | float | No | Base delay between retries (default: 5s) |
| `timeout` | float | No | Timeout in seconds (default: 300) |
| `working_dir` | string | No | Working directory |
| `env` | dict | No | Environment variables |
| `artifacts` | list[str] | No | Expected output files |
| `tags` | list[str] | No | Tags for filtering |

*Exactly one of `command`, `script`, or `agent` required.

## Built-in Templates

```bash
# Aves-X release pipeline
orchestrator --template aves

# Custom template
orchestrator --template my-template
```

## Workflow Configuration

```yaml
name: "Pipeline Name"
version: "1.0.0"
description: "Description"
working_dir: "."           # Base directory
max_parallel: 4            # Max concurrent tasks
default_timeout: 300.0     # Default task timeout (seconds)
on_failure: "stop"         # stop | continue | retry
global_env:                # Environment vars for all tasks
  NODE_ENV: "production"
```

## Running

```bash
# From config file
orchestrator --config workflow.yaml

# Dry run (validate only)
orchestrator --config workflow.yaml --dry-run

# With custom parallelism
orchestrator --config workflow.yaml --max-parallel 8

# Verbose logging
orchestrator --config workflow.yaml --log-level DEBUG
```

## Programmatic Usage

```python
from orchestrator import Orchestrator, Workflow, Task, TaskPriority

# Define workflow programmatically
workflow = Workflow(
    name="My Pipeline",
    version="1.0.0",
    tasks=[
        Task(
            id="build",
            name="Build",
            command="make build",
            priority=TaskPriority.HIGH,
        ),
        Task(
            id="test",
            name="Test",
            command="pytest",
            depends_on=["build"],
        ),
    ],
)

orchestrator = Orchestrator(workflow)
success = orchestrator.run()
```

## Custom Executors

```python
from orchestrator import TaskExecutor, TaskResult

class DockerExecutor(TaskExecutor):
    def execute(self, task: Task, workflow: Workflow) -> TaskResult:
        # Custom Docker execution logic
        result = subprocess.run(...)
        return TaskResult(success=True, output="...")

# Register
orchestrator = Orchestrator(workflow)
orchestrator.register_executor("docker", DockerExecutor())

# Use in workflow
# - id: build
#   executor: "docker"
#   image: "my-builder:latest"
```

## Integration with OpenCode

The orchestrator works seamlessly with OpenCode subagents:

```yaml
- id: security_review
  name: "Security Review"
  agent: "reviewer"
  model: "openrouter/anthropic/claude-3.5-sonnet"
  prompt: |
    Review the following files for security vulnerabilities:
    - lib/model/security/
    - lib/widgets/security/
    Focus on: authentication bypass, injection, crypto misuse
```

## Git Integration

```yaml
- id: create_pr
  name: "Create Pull Request"
  command: |
    gh pr create --title "feat: ${{TASK_NAME}}" \
      --body "Automated PR from orchestrator"
  env:
    GH_TOKEN: "${{GH_TOKEN}}"
```

## Monitoring & Artifacts

```yaml
- id: build
  name: "Build"
  command: "make build"
  artifacts:
    - "dist/app.tar.gz"
    - "dist/checksums.txt"
  tags: ["build", "artifact"]

- id: verify
  name: "Verify Artifacts"
  command: |
    for f in dist/*.tar.gz; do
      sha256sum "$f" | grep -f dist/checksums.txt
    done
  depends_on: ["build"]
```

## Status Tracking

The orchestrator tracks:
- Task status (PENDING, RUNNING, COMPLETED, FAILED, RETRYING)
- Start/completion times
- Retry counts
- Output/errors
- Artifacts produced

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tasks completed successfully |
| 1 | One or more tasks failed |
| 130 | Interrupted (Ctrl+C) |

## Best Practices

1. **Keep tasks small and focused** - One logical operation per task
2. **Use dependencies wisely** - Let the orchestrator handle ordering
3. **Set appropriate timeouts** - Prevent stuck tasks
4. **Use tags for filtering** - Easy to run subsets
4. **Keep secrets out of YAML** - Use env vars or secret managers
5. **Test locally first** - Use `--dry-run` to validate

## License

MIT - Use freely in any project.