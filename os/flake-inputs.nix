# Glue between this flake and these modules for inputs
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.hly.flake-inputs = lib.mkOption {
    description = "The flake's inputs";
    type = lib.types.anything;
  };
}
