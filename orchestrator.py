#!/usr/bin/env python3
"""
Universal Task Orchestrator Harness
====================================
A reusable task orchestration system for managing complex multi-agent workflows
across any project. Designed to work with OpenCode subagents, git, CI/CD, and
custom tooling.

Usage:
    python orchestrator.py --project-dir /path/to/project --config workflow.yaml
    python orchestrator.py --interactive
"""

import os
import sys
import json
import yaml
import subprocess
import threading
import time
import signal
import logging
from dataclasses import dataclass, field, asdict
from typing import Dict, List, Optional, Any, Callable
from pathlib import Path
from enum import Enum
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, Future, as_completed
import queue
import uuid


# =============================================================================
# Core Types
# =============================================================================

class TaskStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"
    BLOCKED = "blocked"
    RETRYING = "retrying"


class TaskPriority(Enum):
    LOW = 0
    NORMAL = 50
    HIGH = 100
    CRITICAL = 200


@dataclass
class TaskResult:
    success: bool
    output: Any = None
    error: Optional[str] = None
    artifacts: List[str] = field(default_factory=list)
    metadata: Dict = field(default_factory=dict)


@dataclass
class Task:
    id: str
    name: str
    description: str
    command: Optional[str] = None
    script: Optional[str] = None
    agent: Optional[str] = None
    model: Optional[str] = None
    prompt: Optional[str] = None
    depends_on: List[str] = field(default_factory=list)
    priority: TaskPriority = TaskPriority.NORMAL
    max_retries: int = 3
    retry_delay: float = 5.0
    timeout: float = 300.0
    working_dir: Optional[str] = None
    env: Dict[str, str] = field(default_factory=dict)
    artifacts: List[str] = field(default_factory=list)
    tags: List[str] = field(default_factory=list)
    metadata: Dict = field(default_factory=dict)
    
    # Runtime fields
    status: TaskStatus = TaskStatus.PENDING
    result: Optional[TaskResult] = None
    retry_count: int = 0
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    future: Optional[Future] = None


@dataclass
class Workflow:
    name: str
    version: str
    description: str
    tasks: List[Task] = field(default_factory=list)
    global_env: Dict[str, str] = field(default_factory=dict)
    working_dir: str = "."
    max_parallel: int = 4
    default_timeout: float = 300.0
    on_failure: str = "stop"  # stop, continue, retry
    metadata: Dict = field(default_factory=dict)
    
    # Runtime
    task_map: Dict[str, Task] = field(default_factory=dict, init=False)
    completed_tasks: List[str] = field(default_factory=list, init=False)
    failed_tasks: List[str] = field(default_factory=list, init=False)
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None


# =============================================================================
# Executors
# =============================================================================

class TaskExecutor:
    """Base executor for different task types."""
    
    def execute(self, task: Task, workflow: 'Workflow') -> TaskResult:
        raise NotImplementedError


class ShellExecutor(TaskExecutor):
    """Execute shell commands."""
    
    def execute(self, task: Task, workflow: Workflow) -> TaskResult:
        if not task.command and not task.script:
            return TaskResult(success=False, error="No command or script provided")
        
        cmd = task.command or task.script
        cwd = task.working_dir or workflow.working_dir
        env = {**os.environ, **workflow.global_env, **task.env}
        
        try:
            result = subprocess.run(
                cmd,
                shell=True,
                cwd=cwd,
                env=env,
                capture_output=True,
                text=True,
                timeout=task.timeout
            )
            
            if result.returncode == 0:
                return TaskResult(
                    success=True,
                    output=result.stdout,
                    metadata={"returncode": result.returncode, "stderr": result.stderr}
                )
            else:
                return TaskResult(
                    success=False,
                    error=f"Exit code {result.returncode}: {result.stderr}",
                    metadata={"returncode": result.returncode, "stdout": result.stdout}
                )
        except subprocess.TimeoutExpired:
            return TaskResult(success=False, error=f"Timeout after {task.timeout}s")
        except Exception as e:
            return TaskResult(success=False, error=str(e))


class AgentExecutor(TaskExecutor):
    """Execute via OpenCode subagent (simulated - replace with actual API)."""
    
    def __init__(self, opencode_path: str = "opencode"):
        self.opencode_path = opencode_path
    
    def execute(self, task: Task, workflow: Workflow) -> TaskResult:
        if not task.agent or not task.prompt:
            return TaskResult(success=False, error="Agent and prompt required")
        
        # Build subagent command
        cmd_parts = [
            self.opencode_path,
            "subagent",
            f"--agent={task.agent}",
            f"--prompt={task.prompt}",
        ]
        
        if task.model:
            cmd_parts.append(f"--model={task.model}")
        if task.working_dir:
            cmd_parts.append(f"--workdir={task.working_dir}")
        
        # In real implementation, this would call the actual OpenCode API
        # For now, return a placeholder
        return TaskResult(
            success=True,
            output=f"Agent {task.agent} executed with model {task.model}",
            metadata={"agent": task.agent, "model": task.model}
        )


class GitExecutor(TaskExecutor):
    """Git operations."""
    
    def execute(self, task: Task, workflow: Workflow) -> TaskResult:
        # Delegate to shell executor with git commands
        return ShellExecutor().execute(task, workflow)


# =============================================================================
# Orchestrator Core
# =============================================================================

class Orchestrator:
    """Main orchestration engine."""
    
    def __init__(self, workflow: Workflow, log_level: int = logging.INFO):
        self.workflow = workflow
        self.executors: Dict[str, TaskExecutor] = {
            "shell": ShellExecutor(),
            "agent": AgentExecutor(),
            "git": GitExecutor(),
        }
        self.logger = self._setup_logger(log_level)
        self.task_queue: queue.PriorityQueue = queue.PriorityQueue()
        self.running_tasks: Dict[str, Future] = {}
        self.executor_pool = ThreadPoolExecutor(max_workers=workflow.max_parallel)
        self._shutdown = False
        self._lock = threading.Lock()
        
        # Build task map
        for task in workflow.tasks:
            workflow.task_map[task.id] = task
    
    def _setup_logger(self, level: int) -> logging.Logger:
        logger = logging.getLogger(f"orchestrator.{self.workflow.name}")
        logger.setLevel(level)
        handler = logging.StreamHandler()
        handler.setFormatter(logging.Formatter(
            '%(asctime)s | %(levelname)-8s | %(message)s',
            datefmt='%H:%M:%S'
        ))
        logger.addHandler(handler)
        return logger
    
    def register_executor(self, name: str, executor: TaskExecutor):
        """Register a custom executor."""
        self.executors[name] = executor
    
    def _get_executor(self, task: Task) -> TaskExecutor:
        if task.agent:
            return self.executors.get("agent", ShellExecutor())
        return self.executors.get("shell", ShellExecutor())
    
    def _is_ready(self, task: Task) -> bool:
        """Check if all dependencies are completed."""
        for dep_id in task.depends_on:
            dep_task = self.workflow.task_map.get(dep_id)
            if not dep_task or dep_task.status != TaskStatus.COMPLETED:
                return False
        return True
    
    def _enqueue_ready_tasks(self):
        """Enqueue all tasks that are ready to run."""
        for task in self.workflow.tasks:
            if task.status == TaskStatus.PENDING and self._is_ready(task):
                task.status = TaskStatus.BLOCKED  # Will be RUNNING when picked up
                priority = -task.priority.value  # Negative for min-heap
                self.task_queue.put((priority, task.id))
    
    def _execute_task(self, task: Task) -> TaskResult:
        """Execute a single task with retries."""
        executor = self._get_executor(task)
        task.status = TaskStatus.RUNNING
        task.started_at = datetime.now()
        self.logger.info(f"🚀 Starting: {task.name} ({task.id})")
        
        last_error = None
        for attempt in range(task.max_retries + 1):
            if attempt > 0:
                task.retry_count = attempt
                task.status = TaskStatus.RETRYING
                self.logger.warning(f"🔄 Retry {attempt}/{task.max_retries} for {task.name}")
                time.sleep(task.retry_delay * attempt)
            
            try:
                result = self._get_executor(task).execute(task, self.workflow)
                if result.success:
                    task.status = TaskStatus.COMPLETED
                    task.result = result
                    task.completed_at = datetime.now()
                    self.logger.info(f"✅ Completed: {task.name}")
                    return result
                else:
                    last_error = result.error
                    self.logger.error(f"❌ Failed: {task.name} - {result.error}")
            except Exception as e:
                last_error = str(e)
                self.logger.exception(f"💥 Exception in {task.name}: {e}")
        
        task.status = TaskStatus.FAILED
        task.result = TaskResult(success=False, error=last_error or "Max retries exceeded")
        task.completed_at = datetime.now()
        self.logger.error(f"💀 Failed after retries: {task.name}")
        return task.result
    
    def _worker(self):
        """Worker thread that processes tasks from queue."""
        while not self._shutdown:
            try:
                priority, task_id = self.task_queue.get(timeout=1.0)
                task = self.workflow.task_map.get(task_id)
                if not task or task.status != TaskStatus.BLOCKED:
                    self.task_queue.task_done()
                    continue
                
                future = self.executor_pool.submit(self._execute_task, task)
                task.future = future
                self.running_tasks[task_id] = future
                
                # Wait for completion
                result = future.result()
                del self.running_tasks[task_id]
                self.task_queue.task_done()
                
                if task.status == TaskStatus.COMPLETED:
                    self.workflow.completed_tasks.append(task_id)
                else:
                    self.workflow.failed_tasks.append(task_id)
                    if self.workflow.on_failure == "stop":
                        self._shutdown = True
                
                # Check for newly ready tasks
                self._enqueue_ready_tasks()
                
            except queue.Empty:
                continue
            except Exception as e:
                self.logger.exception(f"Worker error: {e}")
    
    def run(self) -> bool:
        """Run the workflow to completion."""
        self.logger.info(f"🎬 Starting workflow: {self.workflow.name} v{self.workflow.version}")
        self.workflow.start_time = datetime.now()
        self._shutdown = False
        
        # Initial enqueue
        self._enqueue_ready_tasks()
        
        # Start workers
        workers = []
        for _ in range(self.workflow.max_parallel):
            t = threading.Thread(target=self._worker, daemon=True)
            t.start()
            workers.append(t)
        
        # Wait for completion
        try:
            self.task_queue.join()
        except KeyboardInterrupt:
            self.logger.warning("⚠️ Interrupted by user")
            self._shutdown = True
        
        self.workflow.end_time = datetime.now()
        
        # Summary
        success_count = len(self.workflow.completed_tasks)
        fail_count = len(self.workflow.failed_tasks)
        total = len(self.workflow.tasks)
        
        self.logger.info(f"\n{'='*50}")
        self.logger.info(f"📊 Workflow Complete: {self.workflow.name}")
        self.logger.info(f"   ✅ Completed: {success_count}")
        self.logger.info(f"   ❌ Failed: {fail_count}")
        self.logger.info(f"   ⏱️  Duration: {self.workflow.end_time - self.workflow.start_time}")
        self.logger.info(f"{'='*50}")
        
        return fail_count == 0
    
    def shutdown(self):
        """Graceful shutdown."""
        self._shutdown = True
        self.executor_pool.shutdown(wait=True)


# =============================================================================
# Workflow Definition (YAML/JSON)
# =============================================================================

def load_workflow(path: str) -> Workflow:
    """Load workflow from YAML/JSON file."""
    path = Path(path)
    with open(path) as f:
        if path.suffix in ('.yaml', '.yml'):
            data = yaml.safe_load(f)
        elif path.suffix == '.json':
            data = json.load(f)
        else:
            raise ValueError(f"Unsupported format: {path.suffix}")
    
    # Convert task dicts to Task objects
    tasks = []
    for t in data.get('tasks', []):
        task = Task(
            id=t.get('id', str(uuid.uuid4())[:8]),
            name=t['name'],
            description=t.get('description', ''),
            command=t.get('command'),
            script=t.get('script'),
            agent=t.get('agent'),
            model=t.get('model'),
            prompt=t.get('prompt'),
            depends_on=t.get('depends_on', []),
            priority=TaskPriority[t.get('priority', 'NORMAL')],
            max_retries=t.get('max_retries', 3),
            retry_delay=t.get('retry_delay', 5.0),
            timeout=t.get('timeout', 300.0),
            working_dir=t.get('working_dir'),
            env=t.get('env', {}),
            artifacts=t.get('artifacts', []),
            tags=t.get('tags', []),
            metadata=t.get('metadata', {}),
        )
        # Validate dependencies exist
        for dep in task.depends_on:
            if dep not in [t.id for t in []]:  # Will validate after all tasks created
                pass
    
    workflow = Workflow(
        name=data['name'],
        version=data.get('version', '1.0.0'),
        description=data.get('description', ''),
        tasks=tasks,
        global_env=data.get('global_env', {}),
        working_dir=data.get('working_dir', '.'),
        max_parallel=data.get('max_parallel', 4),
        default_timeout=data.get('default_timeout', 300.0),
        on_failure=data.get('on_failure', 'stop'),
        metadata=data.get('metadata', {}),
    )
    return workflow


def save_workflow(workflow: Workflow, path: str):
    """Save workflow to YAML."""
    data = {
        'name': workflow.name,
        'version': workflow.version,
        'description': workflow.description,
        'global_env': workflow.global_env,
        'working_dir': workflow.working_dir,
        'max_parallel': workflow.max_parallel,
        'default_timeout': workflow.default_timeout,
        'on_failure': workflow.on_failure,
        'metadata': workflow.metadata,
        'tasks': [asdict(t) for t in workflow.tasks],
    }
    with open(path, 'w') as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False)


# =============================================================================
# Pre-built Workflow Templates
# =============================================================================

def create_aves_workflow(project_dir: str) -> Workflow:
    """Create the Aves-X standard workflow."""
    tasks = [
        Task(
            id="pre_check",
            name="Pre-flight Checks",
            description="Verify environment and dependencies",
            command="flutter doctor -v && git status",
            priority=TaskPriority.CRITICAL,
        ),
        Task(
            id="gen_l10n",
            name="Generate Localizations",
            description="Generate l10n files",
            command="flutter gen-l10n",
            depends_on=["pre_check"],
        ),
        Task(
            id="analyze",
            name="Static Analysis",
            description="Run flutter analyze",
            command="flutter analyze",
            depends_on=["gen_l10n"],
        ),
        Task(
            id="test",
            name="Run Tests",
            description="Run unit and widget tests",
            command="flutter test",
            depends_on=["analyze"],
        ),
        Task(
            id="build_apk",
            name="Build APK",
            description="Build release APKs",
            command="scripts/ci-build.ps1",
            depends_on=["test"],
            timeout=1800.0,
            max_retries=3,
        ),
        Task(
            id="verify_artifact",
            name="Verify Artifacts",
            description="Verify APK artifacts exist and are valid",
            command="ls -la build/app/outputs/flutter-apk/ && unzip -l build/app/outputs/flutter-apk/*.apk | head -20",
            depends_on=["build_apk"],
        ),
        Task(
            id="tag_release",
            name="Tag Release",
            description="Create git tag for release",
            script="""
                VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}')
                git tag -a v$VERSION -m "Release v$VERSION"
                git push origin v$VERSION
            """,
            depends_on=["verify_artifact"],
        ),
        Task(
            id="github_release",
            name="Create GitHub Release",
            description="Create GitHub release with APKs",
            script="""
                VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}')
                gh release create v$VERSION build/app/outputs/flutter-apk/*.apk \
                    --title "Aves-X v$VERSION" \
                    --notes-file CHANGELOG.md
            """,
            depends_on=["tag_release"],
        ),
    ]
    
    return Workflow(
        name="Aves-X Release Pipeline",
        version="0.5.0",
        description="Complete Aves-X build, test, and release pipeline",
        tasks=tasks,
        working_dir=".",
        max_parallel=2,
        on_failure="stop",
    )


# =============================================================================
# CLI Interface
# =============================================================================

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Universal Task Orchestrator")
    parser.add_argument('--project-dir', '-p', default='.', help='Project directory')
    parser.add_argument('--config', '-c', help='Workflow config file (YAML/JSON)')
    parser.add_argument('--template', choices=['aves'], help='Use built-in template')
    parser.add_argument('--interactive', '-i', action='store_true', help='Interactive mode')
    parser.add_argument('--max-parallel', '-j', type=int, default=4, help='Max parallel tasks')
    parser.add_argument('--log-level', default='INFO', choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'])
    parser.add_argument('--dry-run', action='store_true', help='Validate workflow without running')
    
    args = parser.parse_args()
    
    # Setup logging
    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format='%(asctime)s | %(levelname)-8s | %(message)s',
        datefmt='%H:%M:%S'
    )
    logger = logging.getLogger(__name__)
    
    # Change to project directory
    os.chdir(args.project_dir)
    
    # Load or create workflow
    if args.template == 'aves':
        workflow = create_aves_workflow('.')
    elif args.config:
        workflow = load_workflow(args.config)
    else:
        logger.error("Must specify --config or --template")
        return 1
    
    workflow.max_parallel = args.max_parallel
    
    if args.dry_run:
        print(f"Workflow: {workflow.name} v{workflow.version}")
        print(f"Tasks: {len(workflow.tasks)}")
        for t in workflow.tasks:
            deps = f" (depends: {', '.join(t.depends_on)})" if t.depends_on else ""
            print(f"  - {t.name} [{t.priority.name}]{deps}")
        return 0
    
    # Run orchestrator
    orchestrator = Orchestrator(workflow, log_level=getattr(logging, args.log_level))
    
    try:
        success = orchestrator.run()
        return 0 if success else 1
    except KeyboardInterrupt:
        logger.warning("Interrupted")
        return 130
    except Exception as e:
        logger.exception(f"Fatal error: {e}")
        return 1


if __name__ == '__main__':
    sys.exit(main())