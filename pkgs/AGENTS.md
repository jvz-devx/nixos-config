# Custom package subtree guidance

This directory contains repo-local package definitions used by the flake.

## Preferred style

- Prefer modern hashes: `hash = "sha256-..."`
- Prefer `finalAttrs:` derivations where the builder supports them cleanly
- Prefer explicit `lib.` references in `meta`
- Prefer `lib.getExe` / `lib.getExe'` when referencing package executables
- Set `meta.mainProgram` when appropriate

## Repo-specific pragmatism

- Do not force `finalAttrs:` if the builder or package shape becomes awkward or breaks validation
- Keep package expressions readable; pragmatic, validated code is better than mechanically “modern” code
- This repo is not nixpkgs; local maintainability matters more than matching every upstream convention perfectly

## Validation

- Run `nix fmt`
- Run `nix build /etc/nixos#<package-name>` for each changed package
- If the package is used by Jens' Home Manager or workstation flow, also run `nixos-rebuild dry-build --flake /etc/nixos#rog-strix`
