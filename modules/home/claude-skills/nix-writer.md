---
name: nix-writer
description: Write correct, modern, idiomatic Nix — NixOS modules, Home Manager, flakes, and package derivations. Use this skill whenever editing or creating any `.nix` file, authoring a module, writing a flake, packaging software, or answering Nix questions. Favor current (2025–2026) idioms over legacy patterns the model saw in older training data.
user-invocable: true
---

# Nix Writer

Write Nix that evaluates, builds, and reflects the current ecosystem — not the one from 2020. Today's baseline: **Nix 2.32**, **NixOS 25.11**, **nixfmt (RFC 166)** as the official nixpkgs formatter, **`pkgs/by-name`** for new packages, **SRI hashes** everywhere, **`finalAttrs:` derivations**. Models trained on older code will reach for deprecated forms by reflex — actively prefer the modern form.

## Before writing anything

1. **Read the surrounding project.** Look at `flake.nix`, existing modules, and any `CLAUDE.md` / `README` for local conventions (option namespaces, formatter choice, profile layout). Match them rather than imposing generic style.
2. **Check the formatter.** Run `nix fmt` after edits. Projects may use `nixfmt-rfc-style` (nixpkgs default) *or* `alejandra`; respect whichever is wired into `formatter.${system}` / `treefmt`.
3. **Validate every change.** For NixOS/Home-Manager edits: `nixos-rebuild dry-build --flake .#<host>` for each affected host. For flake packages: `nix build .#<pkg>` or `nix flake check`. A change is not done until it evaluates cleanly.

## Repo overlay: `/etc/nixos` conventions

When working in this repository, prefer these local conventions over generic style advice:

- **Formatter**: this repo uses `nix fmt` wired to **alejandra**. Do not rewrite style toward `nixfmt-rfc-style` conventions just because they are common elsewhere.
- **Option namespace**: reusable NixOS modules belong under `myConfig.*`.
- **Home Manager philosophy**: a mixed style is acceptable here:
  - reusable/optional features can use custom options and `mkIf`
  - plain imported Home Manager fragments are fine for shared defaults
- **Home Manager organization**: optimize for **discoverability**, especially for KDE/Plasma. Large UI configs should be split by topic rather than kept in one huge file.
- **Current Home Manager layout**: prefer domain-oriented organization such as `base/`, `desktop/`, `features/`, and `packages/`. For Plasma, prefer a subtree like `desktop/plasma/{appearance,fonts,panels,shortcuts,workspace,kwin,packages}.nix`.
- **Validation target**: when a Home Manager change affects Jens' workstation flow, `rog-strix` is the primary validation host. Validate other hosts when their HM entry points or shared modules are affected.
- **Flake source gotcha**: newly created files may need to be `git add`ed before `nixos-rebuild dry-build` sees them, because the flake source is taken from the git tree.
- **Pragmatism over purity**: prefer making the repo easier to navigate and maintain over forcing every file into the most abstract or “ideal” generic Nix pattern.

## Golden rules (follow without exception unless the project says otherwise)

- Use **SRI hashes** (`hash = "sha256-…"`), never `sha256 = "<hex>"` or `cargoSha256`/`npmSha256`.
- Use **`stdenv.mkDerivation (finalAttrs: { … })`**, not `rec { … }`. `rec` breaks `overrideAttrs`.
- Use **`lib.mkIf`** for conditional config, not `if … then … else { }`.
- Use **`lib.mkEnableOption`** and **`lib.mkPackageOption`** instead of hand-rolled `mkOption { type = types.bool; default = false; }`.
- Use **`lib.getExe pkg`** + **`meta.mainProgram`** instead of `"${pkg}/bin/name"` interpolation.
- Use **`lib.fileset.toSource`** for package sources, not `./.` path interpolation or `builtins.filterSource`.
- Use **`inherit (lib) …`** at the top of a `let`, never `with lib;` at module scope.
- Pin inputs via flake `inputs` with `.follows` deduping — never `<nixpkgs>`, channels, or unpinned `fetchTarball`.
- Never do **IFD** (import-from-derivation) inside nixpkgs or shared code.

## Modern vs deprecated — pairs to internalize

### Fetchers and hashes

```nix
# ❌ Old
src = fetchurl {
  url = "https://github.com/acme/foo/archive/v${version}.tar.gz";
  sha256 = "0abc...";          # hex
};

# ✅ Modern
src = fetchFromGitHub {
  owner = "acme";
  repo  = "foo";
  tag   = "v${finalAttrs.version}";   # `tag` preferred over `rev` for version bumps
  hash  = "sha256-AAAA...=";          # SRI (base64)
};
```

Prefer specific fetchers over `fetchurl` when they exist: `fetchFromGitHub`, `fetchFromGitLab`, `fetchFromSourcehut`, `fetchgit`, `fetchCrate`, `fetchPypi`.

### Derivations

```nix
# ❌ Old — rec breaks overrideAttrs, name = instead of pname/version
stdenv.mkDerivation rec {
  name = "foo-${version}";
  version = "1.0";
  src = fetchurl { ... sha256 = "..."; };
}

# ✅ Modern
stdenv.mkDerivation (finalAttrs: {
  pname = "foo";
  version = "1.0";
  src = fetchFromGitHub {
    owner = "acme"; repo = "foo";
    tag  = "v${finalAttrs.version}";
    hash = "sha256-...";
  };
  passthru = {
    updateScript = nix-update-script { };
    tests.version = testers.testVersion { package = finalAttrs.finalPackage; };
  };
  meta = {
    description = "Short one-liner, no trailing period, no leading 'A '";
    homepage    = "https://github.com/acme/foo";
    changelog   = "https://github.com/acme/foo/releases/tag/v${finalAttrs.version}";
    license     = lib.licenses.mit;
    maintainers = with lib.maintainers; [ yourhandle ];
    platforms   = lib.platforms.linux;
    mainProgram = "foo";                # required for lib.getExe
  };
})
```

For new nixpkgs packages: put the file at `pkgs/by-name/<first-two-chars>/<pname>/package.nix`. CI enforces this for new packages.

### Builder-specific hashes

- Rust: `buildRustPackage { ... cargoHash = "sha256-..."; }` — not `cargoSha256`.
- Go: `buildGoModule { ... vendorHash = "sha256-..."; }` (or `null` for vendored deps).
- Node: `buildNpmPackage { ... npmDepsHash = "sha256-..."; }`.
- Python: `buildPythonPackage { pyproject = true; build-system = [ ... ]; ... }` — no hash; `pyproject = true` is the modern form.

### `substituteInPlace`

```nix
# ❌ Bare --replace silently succeeds if the string isn't found
postPatch = ''
  substituteInPlace foo.py --replace "/usr/bin/python" "${python}/bin/python"
'';

# ✅ --replace-fail (Nix 2.24+) errors when the pattern is missing,
# catching upstream drift before it ships broken
postPatch = ''
  substituteInPlace foo.py \
    --replace-fail "/usr/bin/python" "${python}/bin/python"
'';
```

Variants: `--replace-warn`, `--replace-quiet`. Bare `--replace` is on the deprecation path.

### Source filtering

```nix
# ❌ Copies the whole tree, cache-busts on .git changes, may leak secrets
src = ./.;

# ✅ lib.fileset — explicit, stable, avoids cache churn
src = lib.fileset.toSource {
  root = ./.;
  fileset = lib.fileset.unions [
    ./Cargo.toml ./Cargo.lock
    (lib.fileset.fileFilter (f: f.hasExt "rs") ./src)
  ];
};
```

### `with` and scope hygiene

```nix
# ❌ Defeats LSPs and shadow-analysis; tracked for removal in nixpkgs
{ lib, pkgs, config, ... }:
with lib;
{ options.foo = mkOption { type = types.bool; default = false; }; }

# ✅ Inherit only what you need
{ lib, pkgs, config, ... }:
let
  inherit (lib) mkOption mkIf mkEnableOption types;
in
{ options.foo = mkOption { type = types.bool; default = false; }; }
```

`with pkgs; [ foo bar ]` in `buildInputs` is widely tolerated, but prefer `[ pkgs.foo pkgs.bar ]` or `builtins.attrValues { inherit (pkgs) foo bar; }` for larger sets.

## NixOS module system

Structure every module as `options` + `config`. Gate with `lib.mkIf`, assert invariants, and avoid inlining `pkgs` lookups.

```nix
{ lib, pkgs, config, ... }:
let
  cfg = config.services.foo;
  inherit (lib) mkIf mkEnableOption mkPackageOption mkOption types;
in
{
  options.services.foo = {
    enable  = mkEnableOption "the foo daemon";     # "Enable " is auto-prefixed; don't repeat
    package = mkPackageOption pkgs "foo" { };
    settings = mkOption {
      type = types.submodule {
        freeformType = (pkgs.formats.toml { }).type;
      };
      default = { };
      description = "Contents of foo.toml.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.services.foo = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.ExecStart = lib.getExe cfg.package;
    };

    assertions = [{
      assertion = cfg.settings ? port;
      message   = "services.foo.settings.port must be set";
    }];
  };
}
```

- **Priority helpers**: `lib.mkDefault` (low), plain value (normal), `lib.mkForce` (high). Use sparingly and comment why.
- **Composition**: `config = lib.mkMerge [ (mkIf a { … }) (mkIf b { … }) ];`.
- **Replace upstream module**: `disabledModules = [ "services/misc/foo.nix" ];` then reimplement.
- **`_module.args`** / `specialArgs` to thread extra args into modules — never `import <nixpkgs>` inside a module.
- **Types**: prefer `types.submodule` for nested structure over `types.attrs` / `types.attrsOf types.anything`. `pkgs.formats.{json,yaml,toml,ini}` give you a `generate` function + matching `type`.

## Flakes

Flakes are still technically experimental (RFC open) but de-facto standard. Use them for hosts; `npins` + classic Nix is a legitimate alternative for libraries.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";     # dedupe nested nixpkgs
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      perSystem = { pkgs, system, ... }: {
        packages.default = pkgs.callPackage ./package.nix { };
        devShells.default = pkgs.mkShell { packages = [ pkgs.cargo ]; };
        formatter = pkgs.nixfmt-rfc-style;
      };
      flake.nixosConfigurations.host = /* ... */;
    };
}
```

- Use **flake-parts** for any non-trivial flake — it gives you `perSystem`, module composition, and stops the `forAllSystems` boilerplate.
- Use **`nix-systems`** instead of hand-rolling system lists or pulling `flake-utils`.
- Use **`.follows`** to collapse multiple copies of nixpkgs.
- Use **`treefmt-nix`** when integrating multiple formatters.
- `nix flake check` before committing.

## Home Manager

- Pin HM to the same release as NixOS (`release-25.11` ↔ `nixos-25.11`, or both unstable). Mismatch → noisy warnings and option drift.
- Prefer `programs.<foo>.enable = true;` + `programs.<foo>.settings = { … };` (typed, merge-aware) over raw `home.file."…".text = ''…''`.
- Static config files: `xdg.configFile."app/config.toml".source = ./config.toml;`.
- Generated structured config: `xdg.configFile."app/config.toml".source = (pkgs.formats.toml { }).generate "app-config" { … };`.
- Activation scripts only as a last resort: `home.activation.name = lib.hm.dag.entryAfter [ "writeBoundary" ] "…";`.
- Home modules activate on import (unlike NixOS modules which are option-gated). If you want opt-in, declare your own `myConfig.<foo>.enable` and wrap the module body in `mkIf`.

### Home Manager guidance for this repo

- Keep Home Manager entry points (`home/jens.nix`, etc.) mostly readable composition files: imports, user identity, and host/user-specific overrides.
- For large Plasma config, split by topic so the code also acts as a lookup surface for the right plasma-manager options.
- Good examples of topical splits in this repo are:
  - `desktop/plasma/appearance.nix`
  - `desktop/plasma/fonts.nix`
  - `desktop/plasma/panels.nix`
  - `desktop/plasma/shortcuts.nix`
  - `desktop/plasma/workspace.nix`
  - `desktop/plasma/kwin.nix`
- Do **not** add option-gating to every Home Manager fragment by default. Only do it when a feature is genuinely optional per user or host.
- When moving files in `modules/home/`, check relative paths carefully for:
  - `../claude-skills/...`
  - `../../assets/...`
  - `../../secrets/...`
  - any `xdg.configFile.source` / `home.file.source` path references

## Correctness pitfalls

- **`rec { a = a; }`** → infinite recursion. More subtly, `config = { ... config.foo ... }` without `mkIf` can cycle; always do `let cfg = config.services.foo; in { config = mkIf cfg.enable { … }; }`.
- **IFD (import-from-derivation)** — `import (runCommand …)` or `builtins.readFile <a derivation output>`. Banned in nixpkgs (breaks Hydra). Avoid in shared code.
- **Path interpolation** — `"${./foo}"` copies the entire parent directory under its on-disk name. Use `builtins.path { path = ./foo; name = "foo"; }` or `lib.fileset.toSource`.
- **`<nixpkgs>` / `NIX_PATH`** — impure, environment-dependent. Flake inputs or `npins`, always.
- **Cross-compilation** — branch on `stdenv.hostPlatform.*`, not on literal `"x86_64-linux"`. Use `pkgsCross.*` when building for another platform.
- **`builtins.currentSystem` / `currentTime`** — impure; never in shared derivations.
- **`fetchTarball` / `fetchGit` without a pinned hash** — non-reproducible.

## Tooling

- **Formatter**: nixpkgs uses `nixfmt-rfc-style`. Standalone repos often still use `alejandra` — follow whatever the project has wired. Run `nix fmt` before declaring done.
- **Linters**: `statix` (anti-pattern autofix), `deadnix` (unused bindings). Both pair well with `pre-commit` or `treefmt-nix`.
- **LSP**: `nixd` (semantic, evaluates modules for completions) or `nil` (lighter). Either is fine.
- **Validation**: `nix flake check`, `nixos-rebuild dry-build --flake .#<host>`, `nix build .#<pkg>`, `nixpkgs-review pr <N>` for reviewing upstream PRs.

## Do not use

- `nix-env -i` for imperative package install — `home.packages` / `environment.systemPackages` / `nix profile`.
- `nix-shell shell.nix` for new work — `nix develop` with a flake `devShell`.
- `stdenv.lib` — removed; it's `lib` everywhere now.
- `with lib;` at module top — contested, but the direction is clear; `inherit (lib) …` is safer.
- `rec` in new derivations — `finalAttrs:` form.
- Hex `sha256 = "…"` in new code — SRI `hash = "sha256-…"`.
- `cargoSha256` / `npmSha256` — builder-specific SRI `cargoHash` / `npmDepsHash`.
- Channels (`nix-channel --add …`) — pin via flake inputs.
- `builtins.filterSource` for new code — `lib.fileset`.

## Recent language / CLI notes

- **Pipe operator `|>`** — still experimental (`experimental-features = pipe-operators`) as of Nix 2.32. Do not use in shared code yet.
- **Lazy trees** — default in Determinate Nix, opt-in in upstream CppNix 2.32.
- **`nix fmt`** — can be configured to call any formatter via `formatter.${system}`; `treefmt-nix` covers multi-language repos.
- **Nix 2.32** — cached flake input fetching, ~20% lower memory in nixpkgs eval, JSON derivation format now uses basename-only store paths. Protocol compatibility dropped pre-v18 daemons.

## Authoritative references

When in doubt, consult (not training memory):

- nix.dev — https://nix.dev/guides/best-practices.html
- nix.dev working-with-local-files — https://nix.dev/tutorials/working-with-local-files.html
- Nix 2.32 release notes — https://nix.dev/manual/nix/2.33/release-notes/rl-2.32
- Nixpkgs manual — https://nixos.org/manual/nixpkgs/unstable/
- Nixpkgs `meta` attrs — https://nixos.org/manual/nixpkgs/unstable/#sec-standard-meta-attributes
- NixOS writing modules — https://nixos.org/manual/nixos/unstable/#sec-writing-modules
- NixOS options index — https://nixos.org/manual/nixos/unstable/options
- Nixpkgs CONTRIBUTING — https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md
- `pkgs/by-name` — https://github.com/NixOS/nixpkgs/blob/master/pkgs/README.md
- stdenv chapter — https://github.com/NixOS/nixpkgs/blob/master/doc/stdenv/stdenv.chapter.md
- RFC 166 (nixfmt) — https://github.com/NixOS/rfcs/blob/master/rfcs/0166-nix-formatting.md
- RFC 35 (`finalAttrs`, pname/version) — https://github.com/NixOS/rfcs/blob/master/rfcs/0035-rec-pname-version.md
- flake-parts — https://flake.parts/
- Home Manager manual — https://nix-community.github.io/home-manager/
- noogle (lib search) — https://noogle.dev/

## Workflow checklist (every `.nix` edit)

1. Read surrounding modules / flake for conventions (option namespaces, formatter, profile structure).
2. Write using modern forms — `finalAttrs:`, SRI, `mkIf`, `mkEnableOption`, `lib.fileset`, `lib.getExe`.
3. `nix fmt` to normalize style.
4. `nixos-rebuild dry-build --flake .#<host>` for each affected host (or `nix build .#<pkg>` / `nix flake check`).
5. Fix errors until clean. Only then report the task complete.
