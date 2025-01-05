# Copyright © Hraban Luyat
#
# Licensed under the AGPLv3-only.  See README for years and terms.

{ lib, pkgs, config, ... }: {
  launchd.daemons.nix-collect-old-garbage = {
    serviceConfig = {
      ProgramArguments = darwinWait4Nix (lib.getExe self.packages.${pkgs.system}.nix-collect-old-garbage);
      RunAtLoad = true;
      StartCalendarInterval = [ {
        Hour = 11;
        Minute = 11;
      } ];
    };
  };
}
