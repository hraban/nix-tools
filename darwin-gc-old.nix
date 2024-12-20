# Copyright © 2023–2024 Hraban Luyat
#
# Licensed under the AGPL, v3 only.  See the LICENSE file.

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
