# Copyright © Hraban Luyat
#
# Licensed under the AGPLv3-only.  See README for years and terms.

{ withSystem }:

{
  lib,
  pkgs,
  config,
  ...
}:
let
  wait4nix = exec: pkgs.callPackage ./darwin-wait-4-nix.nix { inherit exec; };
  nixgco = withSystem pkgs.system ({ config, ... }: config.packages.nix-collect-old-garbage);
in
{
  launchd.daemons.nix-collect-old-garbage = {
    serviceConfig = {
      ProgramArguments = wait4nix (lib.getExe nixgco);
      RunAtLoad = true;
      StartCalendarInterval = [
        {
          Hour = 11;
          Minute = 11;
        }
      ];
    };
  };
}
