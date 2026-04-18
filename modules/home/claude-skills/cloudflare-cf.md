---
name: cloudflare-cf
description: Use the `cf` CLI (Cloudflare's unified CLI, technical preview) to answer questions about or operate on ANY Cloudflare resource — DNS records, zones, Workers, Pages, R2, KV, D1, Durable Objects, Queues, Access, Tunnels, WAF, cache, page rules, analytics, account settings, API tokens, and everything else in Cloudflare's ~3,000-operation API. Use this skill whenever the user mentions Cloudflare, their domain on Cloudflare (this user's is `jensvanzutphen.com`), a tunnel, a zone, a Worker, R2/KV/D1, or asks something that plausibly involves the Cloudflare control plane — even if they don't say "use cf". Prefer the `cf` CLI over hand-rolled `curl`/API calls, over the Cloudflare dashboard, and over Terraform for one-off reads and simple writes.
user-invocable: true
---

# Cloudflare `cf` CLI

Cloudflare now ships a unified CLI that covers the full API surface. Use it instead of guessing API shapes from memory — `cf` has an authoritative, machine-readable schema behind every command, and exposes it to agents directly via `cf agent-context` and `cf schema`.

This skill's job is **not** to teach you all 100+ products; it's to teach you the handful of commands that let `cf` teach itself to you at the moment you need it.

## Environment (this machine)

- `cf` is installed declaratively via `/etc/nixos/pkgs/cf/` (wrapped with nodejs).
- `CLOUDFLARE_API_TOKEN` is sourced automatically from `/run/secrets/cloudflare_api_token` — you do not need to pass it. Every `cf` invocation picks it up, including non-interactive child shells.
- The user's homelab domain on Cloudflare is **jensvanzutphen.com**, reached over a Cloudflare Tunnel. When a request is ambiguous ("update DNS", "what's in the tunnel"), that zone is the sensible default — confirm with the user if you're about to mutate something.

## Core loop — three commands that bootstrap everything

When you get a Cloudflare task, don't improvise. Follow this loop:

1. **`cf agent-context [product]`** — outputs a condensed guide for one product (e.g. `cf agent-context dns`, `cf agent-context zones`, `cf agent-context r2`). Lists every sub-command with a one-line description and which flags it supports. Run this first to locate the command you need. Call with no argument to get the global guide plus every product's overview (long output — prefer passing a product name).
2. **`cf <command> --help`** — human-readable flag list for the specific command you picked.
3. **`cf schema <command>`** — the full request/response JSON schema for a command. Use this before you run any `create`/`update` so you know exactly what fields go in `--body`.

If you're unsure which product a task falls under, run `cf schema --list` or `cf agent-context --list` to see all products.

## Universal flags that matter

- `--fields id,name,status` — restrict response to named fields. Use on every list command to keep output scannable (a raw `cf zones list` is huge).
- `--ndjson` — stream list results as one JSON object per line. Pipe-friendly.
- `--body '{...}'` — JSON payload for creates/updates; shape is whatever `cf schema <cmd>` documents.
- `--dry-run` — supported on every mutating command (`create`, `update`, `delete`). **Always use it first** for destructive or zone-altering ops — it validates the call against the schema and shows what would happen, without making the change.
- `--account-id` / `--zone` — override context. `--zone` accepts a domain name *or* a zone ID.
- `--json` — force JSON output (it's the default; included here because you may see docs mention the old `--format json`).

## Context: stop repeating IDs

`cf context` sets defaults so you don't have to pass `--account-id` / `--zone` every call:

```
cf context set account-id <id>
cf context set zone jensvanzutphen.com --project   # writes .cfrc in CWD
cf context get                                      # inspect current defaults
```

Resolution order (highest wins): CLI flags → env vars (`CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_ZONE_ID`) → `.cfrc` walked up from CWD → `~/.config/cf/config.json`.

For work inside `/home/jens/Documents/source/homelab-iac/`, setting a project-scoped zone to `jensvanzutphen.com` is usually the right move — but do it via `cf context set … --project` (declarative file), not by exporting env vars ad hoc.

## Safety rules

- **Reads are free; writes are not.** Never run a `create`/`update`/`delete` without the user's go-ahead once you understand what it'll change. Show them the `--dry-run` output and the final command you intend to run; wait for confirmation.
- **On 401/403, don't trust whoami alone.** `cf auth whoami` hits `/user/tokens/verify`, which requires the `User Details:Read` permission. A narrowly-scoped account/zone token (the common `cfat_…` kind) legitimately returns `tokenValid: false` there while still working for every account/zone API call. To actually check if a token is dead, retry the failing call, or do a cheap scoped read like `cf zones list --fields id,name`. Only conclude the token is bad if a scoped read also 401s. When it's genuinely stale, rotate with `sops set /etc/nixos/secrets/common.yaml '["cloudflare_api_token"]' '"<NEW>"'` and `sudo nixos-rebuild switch --flake /etc/nixos#<host>`.
- **Respect declarative infra.** The user's homelab lives in `/home/jens/Documents/source/homelab-iac/` — Flux-reconciled k8s. Don't use `cf` to mutate things that have a declarative source of truth somewhere else (e.g. Cloudflared Tunnel config managed in k8s secrets). When in doubt, ask: "do you want this as a one-off via cf, or should I put it in the IaC repo?"

## Output discipline

- Default to `cf <cmd> --fields …` on list operations. A `cf zones list` without field filtering returns ~80 fields per zone and wastes context.
- For one-off inspection, pipe to `jq` (already installed): `cf dns records list --zone jensvanzutphen.com --ndjson | jq 'select(.type == "CNAME")'`.
- When reporting back to the user, summarize — don't dump the full JSON unless they ask.

## When NOT to reach for `cf`

- **Wrangler-native workflows** (local Worker dev, `wrangler deploy`): use `wrangler`. `cf` is being positioned to absorb Wrangler "over coming months" but isn't there yet — if the user is deploying a Worker from source, use Wrangler.
- **Declarative, repo-tracked infra**: if the resource lives in the homelab IaC repo or a Terraform module, change it there and let the reconciler apply. `cf` is right for exploration, diagnosis, and things the IaC doesn't cover.
- **Bulk imports/exports at scale**: `cf` is fine, but for thousands of records Cloudflare also offers zone file import/export — mention it as an option.

## Local Explorer (only relevant during local Worker/Pages dev)

When developing a Worker locally with Wrangler or the Cloudflare Vite plugin, there's a local explorer for inspecting simulated KV, R2, D1, Durable Objects, and Workflows. Open it by pressing `e` in the running dev server, or hit `/cdn-cgi/explorer/api` on the local URL. Skip this section unless the user is actively doing local Worker dev — it's unrelated to the remote-API use case that drives 99% of `cf` usage.

## Quick recipe examples

Only templates — always run `cf schema <command>` first for the real shape.

**List DNS records for the homelab zone, showing just name/type/content:**
```
cf dns records list --zone jensvanzutphen.com --fields name,type,content
```

**Inspect what a new record would look like before creating it:**
```
cf dns records create --zone jensvanzutphen.com \
  --body '{"type":"A","name":"test","content":"1.2.3.4","proxied":false}' \
  --dry-run
```

**Who am I, what can this token do:**
```
cf auth whoami
cf accounts tokens list      # for account-owned tokens
```

**Discover all products and drill into one:**
```
cf schema --list
cf agent-context dns         # commands available under `dns`
cf schema dns records create # JSON schema for that one call
```
