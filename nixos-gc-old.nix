# Copyright © Hraban Luyat
#
# Licensed under the AGPLv3-only.  See README for years and terms.

# If you use this you’re crazy

{ lib, pkgs, config, ... }:

{
  systemd.nix-collect-old-garbage = {
    serviceConfig = {
      ProgramArguments = [
        (lib.getExe self.packages.${pkgs.system}.nix-collect-old-garbage)
      ];
      RunAtLoad = true;
      StartCalendarInterval = [ {
        Hour = 11;
        Minute = 11;
      } ];
    };
  };
}
