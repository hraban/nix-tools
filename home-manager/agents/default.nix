{ config, lib, ... }:
let
  cfg = config.hly.agents;
in
{
  options.hly.agents = {
    enable = lib.mkEnableOption "My base claude / codex config";
    context = lib.mkOption {
      type = lib.types.lines;
      description = "Any extra context to add";
    };
  };
  config = lib.mkMerge [
    { hly.agents.context = lib.mkBefore (builtins.readFile ./AGENTS.md); }
    (lib.mkIf cfg.enable {
      programs.claude-code = {
        enable = true;
        # Don’t install claude via home-manager; a custom nix alias always fetches
        # from nixpkgs-unstable because it goes out of date so quickl.
        package = null;
        context = cfg.context;
      };
      programs.codex = {
        enable = true;
        package = null;
        context = cfg.context;
      };
    })
  ];
}
