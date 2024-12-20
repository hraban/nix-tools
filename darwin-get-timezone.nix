# Copyright © 2023–2024 Hraban Luyat
#
# Licensed under the AGPL, v3 only.  See the LICENSE file.

{ pkgs, ... }:

let
  get-timezone-su = pkgs.writeShellScriptBin "get-timezone-su" ''
    /usr/sbin/systemsetup -gettimezone | sed -e 's/[^:]*: //'
  '';
  get-timezone = pkgs.writeShellScriptBin "get-timezone" ''
    sudo ${get-timezone-su}/bin/get-timezone-su
  '';
in {
  assertions = [ {
    assertion = pkgs.stdenv.isDarwin;
    message = "Only available on Darwin";
  } ];
  # This is harmless and honestly it’s a darwin bug that you need admin
  # rights to run this.
  environment = {
    etc."sudoers.d/get-timezone".text = ''
      ALL ALL = NOPASSWD: ${get-timezone-su}/bin/get-timezone-su
    '';
    systemPackages = [ get-timezone ];
  };
}
