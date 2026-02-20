---
name: rust-tester
description: Write Rust tests that verify real behavior, catch real regressions, and don't waste time asserting obvious things. Use when writing tests for new or existing code.
user-invocable: true
---

# Rust Tester

Write tests that would actually catch a bug if one were introduced. Every assertion should answer: "what real breakage would this catch?"

## Before Writing Any Test

1. **Read the code under test.** Understand what it does, what can go wrong, what its callers depend on. Don't test a function you haven't read.
2. **Identify the contract.** What does this code promise? What inputs does it accept? What invariants does it maintain? What errors does it return and when? Test the contract, not the implementation.
3. **Find the edges.** Empty inputs, boundary values, concurrent access, cancellation, error paths, the second call after the first one fails. The interesting bugs live at the edges.

## What Makes a Test Worth Writing

A test is worth writing if it would **fail when a real bug is introduced**. Apply this filter to every test:

- **Test observable behavior, not implementation details.** If you refactor internals and the test breaks, the test was wrong.
- **Test outcomes and side effects.** What was returned? What was written to the DB? What event was emitted? What file was created? What error was produced?
- **Test the sad path harder than the happy path.** The happy path usually works. Bugs cluster in error handling, edge cases, and state transitions.
- **One behavior per test.** If a test fails, you should immediately know what broke. A test that checks 5 things tells you nothing when it fails.
- **Name tests after the behavior, not the function.** `test_expired_token_returns_unauthorized` not `test_validate_token`. The name should tell you what broke without reading the test body.

## Assertion Quality Rules

### Assert the actual value, not just its shape

```rust
// BAD: proves nothing about correctness
assert!(result.is_ok());

// GOOD: proves the right thing happened
let download = result.unwrap();
assert_eq!(download.status, Status::Queued);
assert_eq!(download.name, "test-file.nzb");
assert_eq!(download.category, Some("movies".to_string()));
```

### Assert error specifics, not just "it errored"

```rust
// BAD: any error passes this
assert!(result.is_err());

// GOOD: proves the right error for the right reason
match result {
    Err(Error::NotSupported(msg)) => {
        assert!(msg.contains("par2 binary"), "error should mention the missing binary");
    }
    other => panic!("expected NotSupported, got: {other:?}"),
}
```

### Assert side effects, not just return values

```rust
// If a function modifies state, verify the state
downloader.pause(id).await.unwrap();
let status = downloader.db.get_download(id).await.unwrap().status;
assert_eq!(status, Status::Paused, "download should be paused in DB");

// If a function emits events, verify the events
let event = events.recv().await.unwrap();
assert!(matches!(event, Event::Paused { id: event_id, .. } if event_id == id));
```

### Assert counts and ordering when they matter

```rust
// Verify retry count, not just success
assert_eq!(counter.load(Ordering::SeqCst), 3, "should retry exactly twice before success");

// Verify ordering in priority queues
let names: Vec<&str> = downloads.iter().map(|d| d.name.as_str()).collect();
assert_eq!(names, vec!["high-priority", "medium-priority", "low-priority"]);
```

## Bad Test Smells (reject these)

### Tautologies — tests that can't fail

```rust
// Testing that Default::default() returns defaults
let config = Config::default();
assert!(config.servers.is_empty()); // When would this ever break?

// Testing that a constructor sets the fields you just passed in
let rule = Rule::new("test", 42);
assert_eq!(rule.name, "test"); // You literally just set it
```

### Mirroring the implementation

```rust
// If the test logic is identical to the production logic, it catches nothing
fn is_retryable(e: &Error) -> bool { matches!(e, Error::Network(_)) }

#[test]
fn test_is_retryable() {
    // This just re-implements the match — if the logic is wrong, the test is wrong too
    assert!(Error::Network("timeout".into()).is_retryable());
}

// BETTER: test retry behavior end-to-end
// Does a network error actually trigger a retry? Does the retry succeed?
```

### `.is_ok()` / `.is_err()` as the only assertion

A function could return `Ok(completely_wrong_value)` and these tests pass. Always unwrap and check what you got.

### Testing getters and field access

Don't test that `struct.field` returns `field`. Test code that *transforms, decides, or has side effects*.

### Snapshot tests on unstable output

Don't assert on exact debug strings, log messages, or display formatting unless the format is part of the public contract.

### Tests that require intimate knowledge of internals

If a test breaks when you rename a private field or change an internal data structure, it's testing implementation, not behavior.

## Project Conventions

### Test doubles: use traits, not mock libraries

This project uses trait-based test doubles. Follow the existing pattern:

```rust
// Production trait
pub trait ParityHandler: Send + Sync {
    async fn verify(&self, par2_file: &Path) -> Result<VerifyResult>;
}

// Test double — explicit, readable, no mock framework
pub struct NoOpParityHandler;
impl ParityHandler for NoOpParityHandler {
    async fn verify(&self, _: &Path) -> Result<VerifyResult> {
        Err(Error::NotSupported("PAR2 requires binary".into()))
    }
}
```

Don't introduce `mockall`, `mockito`, or similar. Write explicit fakes.

### Use real infrastructure where available

- **Database:** Real SQLite via tempfile, not mocked queries
- **File system:** Real tempdir with real files, not mocked fs
- **NNTP:** Docker-based server for integration tests (`#[cfg(feature = "docker-tests")]`)
- **HTTP:** Real Axum router with `oneshot()`, not mocked HTTP

### Use existing assertion helpers

The project has custom helpers in `tests/common/assertions.rs`. Use them:

- `assert_download_completed(downloader, id, timeout)` — async wait + verify
- `assert_download_failed(downloader, id, timeout)` — async wait + error check
- `assert_files_exist(dir, patterns)` — file system verification
- `assert_download_status(downloader, id, expected)` — status enum check

Create new helpers when a pattern repeats across 3+ tests.

### Test module structure

```rust
#[allow(clippy::unwrap_used, clippy::expect_used)]
#[cfg(test)]
mod tests {
    use super::*;

    // Helper functions first, then tests
    // async fn create_test_downloader() -> ... { }

    #[tokio::test]  // or #[test] for sync
    async fn test_behavior_being_tested() {
        // Arrange — set up state
        // Act — call the thing
        // Assert — verify the outcome
    }
}
```

### Feature-gated tests for external deps

```rust
#[cfg(feature = "docker-tests")]
#[tokio::test]
#[serial]
async fn test_real_nntp_download() { ... }
```

### Async tests

Use `#[tokio::test]` for anything touching the downloader, DB, or API. Use timeouts for anything that waits on events or completion:

```rust
let result = tokio::time::timeout(Duration::from_secs(5), async {
    // thing that could hang
}).await.expect("timed out waiting for completion");
```

## Test Prioritization

When asked to write tests for a module, prioritize in this order:

1. **Error paths and failure modes** — these are where bugs actually hide
2. **State transitions** — paused→resumed, queued→downloading→completed
3. **Boundary conditions** — empty input, max values, zero, negative
4. **Concurrent behavior** — parallel access, cancellation during operation
5. **Integration points** — DB round-trips, API request→response, event emission
6. **Happy path** — last, because it usually already works

## Completeness Check

Before presenting tests, verify:

- [ ] Every assertion would fail if the code under test had a realistic bug
- [ ] Error paths are tested with specific error variants and messages
- [ ] No assertion is just `.is_ok()` or `.is_err()` alone
- [ ] No test mirrors the implementation logic
- [ ] Tests use real infrastructure (tempfile, real DB) not mocks
- [ ] Test names describe the behavior, not the function name
- [ ] Async tests have timeouts where they could hang
