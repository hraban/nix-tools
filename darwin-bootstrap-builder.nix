{ config, lib, ... }:
{
  options = {
    hly.darwin-linux-builder = {
      enable = lib.mkEnableOption "Enable the linux builder";
      applyCustomizations = lib.mkOption {
        type = lib.types.bool;
        description = "Whether to apply the customizations";
        default = true;
      };
      opts = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };
    };
    nobuilder = lib.mkOption {
      type = lib.types.any;
      default = null;
    };
  };
  config =
    let
      cfg = config.hly.darwin-linux-builder;
    in
    lib.mkMerge [
      { nix.linux-builder.enable = cfg.enable; }
      (lib.mkIf cfg.applyCustomizations { nix.linux-builder = cfg.opts; })
    ];
}
