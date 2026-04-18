---
name: context-handoff
description: Write or update a `TODO.md` that captures the current session's state — goal, what's done, what's in progress, next steps, discoveries, and relevant files — so a fresh Claude session (or the user later) can resume without retelling the story. Trigger ONLY when the user explicitly asks for this — e.g. "write a TODO.md", "do a handoff", "dump context to a file", "save session state", "use the handoff skill", "context is almost full, write me a handoff". Do NOT trigger on incidental mentions of "todo" in code, commit messages, or casual conversation.
user-invocable: true
---

# Context handoff — write TODO.md

The user's context window is filling up (or they just want to stop mid-stream) and they want the current session's state captured on disk so a future session — theirs or another agent's — can pick up without them retelling the whole story. Your job is to write (or update) a single Markdown file — `TODO.md` in the project root by default — that a cold reader can open and immediately understand **what we were doing, what's done, what's left, and what surprised us along the way**.

Write it as if you're handing off to a competent stranger who has the codebase and `git log` but zero memory of this session.

## Default behavior

- **Location:** `TODO.md` at the project root (current working directory). Override only if the user names a different path.
- **Existing file:** if `TODO.md` (or the chosen path) already exists, read it first and *update in place*. Tick off items now complete, merge new discoveries with the old, keep prior content unless it's clearly superseded. Don't silently overwrite history. If the user says "start fresh" or "overwrite", replace it — and say so in your report.
- **Nothing to hand off:** if the session has no concrete progress worth recording, tell the user that rather than writing a near-empty scaffold.

## Template

Use this structure. Omit sections that genuinely have no content for this session (don't leave empty stubs), but keep the order consistent so a reader knows where to look.

```markdown
# TODO — <short title of the effort>

## Goal
<1–3 sentences. What is the user trying to accomplish, and why. Include the success criterion so a future session knows when to stop.>

## Done
- [x] <specific, verifiable thing finished this session, with `file:line` where useful>
- [x] <...>

## In progress
- [ ] <thing started but not finished — note exactly where it was left off>
- [ ] <...>

## Next steps
- [ ] <concrete next action — ordered by priority>
- [ ] <...>

## Discovered / gotchas
- <non-obvious thing learned: a subtle bug, surprising API behavior, config that didn't behave as documented, a dead end that was ruled out>
- <...>

## Relevant files
- `path/to/file.ext` — one line on why it matters
- `path/to/other.ext:L42-L58` — reference the specific region that's load-bearing
```

### Checkbox conventions

- `[x]` — finished. The thing is merged/applied/verified.
- `[ ]` — not done (either in progress or yet to start).

Don't invent new markers (`[~]`, `[?]`, `[-]`, …) — they break some Markdown renderers and search tools. Use the **In progress** vs **Next steps** section split to carry that distinction instead.

## What to capture — and what to leave out

**Capture** the things a future reader genuinely can't recover from `git log` or reading the code:

- *Why* a decision was made when the code alone doesn't say.
- Dead ends that were ruled out (so the next session doesn't re-walk them).
- Surprising behavior found along the way.
- The exact resumption point for in-progress work ("stopped mid-edit on `src/auth/refresh.ts:87` — need to finish the error branch").
- Open questions waiting on the user or on a third party.

**Leave out** things already captured elsewhere:

- Don't paraphrase the diff. `git diff` is authoritative; a one-line "refactored auth module" pointing at the file is enough.
- Don't recap conversation tone or meta-commentary ("we had a great session"). The handoff is for work, not for the relationship.
- Don't list every file you looked at — only the ones the next session will actually need to open.

## Updating an existing TODO.md

When the file exists, do a careful merge rather than a rewrite:

1. Read it fully before touching anything.
2. **Done** items — leave as-is. They're history.
3. **In progress** / **Next steps** items — for each: if this session finished it, move it to **Done** and tick it. If partial progress, rewrite the item to reflect the new state (don't just add a sibling — future readers will be confused by the duplicate).
4. **Discovered / gotchas** — append new findings. Only remove an old one if it turned out to be wrong, in which case replace it with the correction and a brief "previously thought X, but actually Y" note.
5. **Next steps** — re-order if priorities changed based on what you learned.
6. **Relevant files** — update to the current set. It's OK to remove a file that's no longer relevant; it's not OK to remove one that still matters just because it was already there.

The test: after your update, could the user tell what changed in this session by reading the file alongside the previous version? If the delta isn't visible, you've paraphrased instead of merged.

## Quality bar

Before handing the file back, sanity-check:

- **Actionable?** Could someone with zero session memory open this and know *what to do next*? If not, the **Next steps** are too vague. "Fix the bug" is useless; "in `src/auth/refresh.ts:47`, make the expired-token branch throw instead of returning null" is useful.
- **Accurate paths?** Every `path/to/file` you mention must really exist (or be the real target path for something about to be created). Wrong paths are worse than no paths — they waste the next session's time.
- **Specific discoveries?** "Auth is weird" is useless; "JWT refresh in `src/auth/refresh.ts:47` silently returns null when the token is expired instead of throwing, which breaks the retry flow" is useful. If you can't be that specific, the finding isn't ready — either investigate more or cut it.
- **Readable in under two minutes?** If not, you're probably paraphrasing the diff — cut.

## Reporting back

After writing the file, tell the user in one short message:

- The absolute path of the file.
- Whether it was **created** or **updated** (and if updated, a one-line summary of the delta — e.g. "ticked 3 done, added 2 gotchas, reordered next steps").
- A one-line resume hint — e.g. "To continue: open this file and start from the first unticked item under **Next steps**."

Nothing more. The file itself is the deliverable; the message is just the pointer.
