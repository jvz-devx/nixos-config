---
name: delegate-plan
description: Turn a multi-task request into a phased execution plan where each phase ("wave") is a group of file-disjoint tasks safe to run in parallel by isolated subagents (via git worktrees), with a verify gate (dry-build / typecheck / test) between waves. Default concurrency: 4 agents per wave. Use this skill whenever the user asks for a plan, a refactor, a "batch of changes", a "fan-out", a "rollout" — anything multi-file that could plausibly benefit from parallel execution. Also trigger on explicit phrases like "delegate", "break into phases", "run in parallel", "spawn N agents", "wave plan", "parallelize this". Lean toward this skill any time the work is bigger than two or three files — don't wait for the user to say "parallel" out loud.
user-invocable: true
---

# delegate-plan — phased parallel plans

When the user asks for a plan that will be carried out by multiple subagents in parallel, you are the planner. Your job is to break the work into **waves** — ordered groups of tasks that can safely run at the same time — so the user gets real parallel speedup without babysitting merge conflicts.

Each wave is defined by three things:

1. **Tasks inside the wave are safe to run concurrently** — their file sets are disjoint, or the shared file(s) can tolerate parallel edits merged afterward.
2. **The wave respects a concurrency cap** — default **4 agents at a time** (the user's house style); honour any user-specified override.
3. **A verify gate runs after the wave** — exactly one round of `dry-build` / `typecheck` / `test`, run against the *merged* state, before the next wave starts.

Between waves, work is serialized. Within a wave, work is parallel. That is the whole mental model.

## Worktree isolation

Every parallel agent inside a wave runs in its own **git worktree**. Launch them with Claude Code's `Agent` tool using `isolation: "worktree"` — the harness creates a fresh worktree on a fresh branch, the agent works there, and on completion the path and branch are returned so they can be merged back.

Two reasons this matters, both worth stating in the plan:

1. **Process safety.** Without worktrees, N agents sharing one working tree race on file writes, `git` state, and transient build artifacts. Worktrees give every agent its own physical checkout on its own branch — no mid-write clobbering, no half-seen state, no `git add` picking up a sibling's in-progress edit.
2. **Merge honesty.** Each agent's work lands on its own branch. Merging back is an *explicit* step — if two agents in the same wave touched the same file, that produces a real merge conflict in the right place, not silently on the filesystem. Your wave design should prevent that, but the merge is the backstop.

Even a one-task wave benefits: the verify gate runs against a clean merged tree rather than whatever cruft the single agent left behind.

## File-conflict analysis

Before you emit the plan, for every task list the files it will **create**, **edit**, or **delete**. Write this down in the plan as a small matrix — it makes the wave grouping auditable, and if the user later adds or removes a task the matrix is the thing they re-check.

Rules for grouping into waves:

- Two tasks may share a wave if and only if **their file sets are disjoint**.
- "Disjoint" includes index-ish files that several tasks all want to append lines to: `modules/nixos/default.nix`, `flake.nix`, a shared `mod.rs`, a shared `routes.ts`, etc. If multiple tasks need to edit the same index file, the index edit goes in its own follow-up wave.
- Tasks with a **logical dependency** (task B needs task A's output to exist) always go in a later wave even if their file sets are disjoint.
- Pure additions (new file creation) are almost always safe to parallelize with each other.
- Pure deletions that affect imports are almost always *not* safe to parallelize with anything else.

If you can't figure out a task's file list, the task isn't well-specified yet — say so in the plan rather than guessing.

## Verify gate

Between waves you (the coordinator) merge each wave's branches back into the integration branch and run **one** verify step. Pick it for the stack:

- **NixOS / Home Manager** → `nix fmt` followed by `nixos-rebuild dry-build --flake .#<host>`. For this machine the host is usually **pc-02** unless the user says otherwise.
- **TypeScript monorepo** → `pnpm -r typecheck && pnpm -r test` (or the repo's `package.json` "check" script).
- **Rust workspace** → `cargo check --workspace && cargo test --workspace`.
- **Python** → `uv run pytest` or the project's configured test command.

Don't pick the command from memory alone — glance at the repo's `CLAUDE.md` / `AGENTS.md` / `README` or `justfile` / `Makefile` first; most projects document the canonical verify command, and using the project's own command is how you catch regressions the way the project expects them to be caught.

If verify fails: **stop**. Investigate, fix, re-verify. Never start the next wave on a broken tree — a failing verify means one of the wave's branches is bad and the next wave would build on a broken foundation.

## Plan output template

Emit the plan with this structure. Keep tasks terse — one-line descriptions are usually enough; the file matrix carries the conflict story.

```markdown
# Delegate plan — <short title>

**Goal:** <1–2 sentences. What's being accomplished, and the success criterion.>
**Concurrency cap:** <N> agents per wave (default 4)
**Verify gate:** `<command(s)>` — chosen for this stack / host

## Files-touched matrix

| Task | Creates | Edits | Deletes |
|------|---------|-------|---------|
| 1A   | `path/new.nix` | — | — |
| 1B   | — | `path/existing.nix` | — |
| 2A   | — | `path/shared/index.nix` | — |

## Wave 1 — <N parallel>

Spawn each task as a separate `Agent` call with `isolation: "worktree"`.

### 1A. <title>
- Files: <list>
- Definition of done: <specific, self-checkable>

### 1B. <title>
- Files: <list>
- Definition of done: <specific, self-checkable>

## Verify after Wave 1
- Merge all Wave 1 branches into the integration branch.
- Run: `<verify command>`
- On failure: stop; fix the offending task before starting Wave 2.

## Wave 2 — <M parallel>
...
```

## Quality bar

Before handing the plan back, re-read it with these four questions in mind:

- **Complete file lists?** If a task silently edits a file not listed in the matrix, the conflict analysis is a lie. Any edit a subagent would plausibly make — including formatter-induced edits to sibling files — has to be in the list.
- **No hidden races?** Read each wave with one question: could any two tasks in this wave race? A shared file in two rows of the same wave is an immediate fail.
- **Concurrency cap respected?** If a wave has 6 tasks but the cap is 4, split it into two sub-waves. Two verify gates are cheaper than one broken merge.
- **Right verify command?** Picked from the project's own config, not from memory.

If any of those answers are shaky, fix the plan before showing it.

## When the work is inherently serial

Some tasks are inherently serial — `nix flake update`, a database migration, a release cut, a dep bump that affects every file. Don't fight that; put them in single-task waves. The plan still earns its keep: the verify gate between waves catches regressions early, and the worktree makes rollback trivial.

## Reporting back

After emitting the plan, finish with one short message:

- `<K>` waves, `<T>` total tasks, concurrency cap `<N>`.
- One-line resume hint — e.g. "Say 'go' and I'll spawn Wave 1 in isolated worktrees."

If the user says go, launch Wave 1 in a single message (one `Agent` call per task, each with `isolation: "worktree"`), wait for all to complete, merge their branches back, run the verify gate, report results, **then** start Wave 2. Never interleave waves.
