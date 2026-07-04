# Limit Rust compilation resource usage globally.
# Prevents parallel cargo builds (e.g. from multiple Claude Code sessions)
# from eating all RAM/CPU and crashing the machine.
{
  config,
  lib,
  ...
}: let
  cfg = config.myConfig.system.buildResources;
in {
  options.myConfig.system.buildResources = {
    enable = lib.mkEnableOption "Rust build resource limits";

    cargoBuildJobs = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Max parallel rustc/linker invocations per cargo build.";
    };

    codegenUnits = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "Codegen units per rustc invocation. Lower = less RAM per compile, slower single builds.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Limit cargo parallelism so each cargo build spawns fewer rustc processes
    # With 9 parallel sessions at 2 jobs each = 18 rustc processes (fits in 20 threads)
    environment.variables = {
      CARGO_BUILD_JOBS = toString cfg.cargoBuildJobs;
    };

    # Limit codegen units to reduce per-rustc memory usage
    # Default is 256 for dev builds which eats RAM fast across parallel sessions
    environment.sessionVariables = {
      CARGO_PROFILE_DEV_CODEGEN_UNITS = toString cfg.codegenUnits;
      CARGO_PROFILE_RELEASE_CODEGEN_UNITS = toString cfg.codegenUnits;
    };

    # systemd-oomd as safety net: kills runaway builds on memory pressure
    # before the kernel OOM killer takes down the desktop session
    systemd.oomd = {
      enable = true;
      enableSystemSlice = true;
      enableUserSlices = true;
    };
  };
}
