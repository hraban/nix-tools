# Copyright © 2023–2024 Hraban Luyat
#
# Licensed under the AGPL, v3 only.  See the LICENSE file.

let
  clamp-service = { lib, ... }: {
    options = with lib; with types; {
      enable = mkOption {
        type = bool;
        default = false;
        description = "Whether to enable a launch daemon to control the battery charge";
      };
      min = mkOption {
        type = ints.between 0 100;
        default = 50;
        description = "Lowest permissible charge: under this, charging is enabled";
      };
      max = mkOption {
        type = ints.between 0 100;
        default = 80;
        description = "Highest permissible charge: above this, charging is disabled";
      };
    };
  };
  xbar-plugin = { lib, ... }: {
    options = with lib; with types; {
      enable = mkOption {
        type = bool;
        default = false;
        description = "Install a charging toggle in xbar for all users";
      };
    };
  };
in { lib, pkgs, config, ... }: let
  cfg = config.battery-control;
in {
  options = with lib; with types; {
    battery-control = {
      clamp-service = mkOption {
        description = "A polling service that toggles charging on/off depending on battery level";
        type = submodule clamp-service;
        default = {};
      };
      xbar-plugin = mkOption {
        description = "A battery charge toggle in xbar";
        type = submodule xbar-plugin;
        default = {};
      };
    };
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.clamp-service.enable {
      assertions = [ {
        assertion = pkgs.stdenv.system == "aarch64-darwin";
        message = "The SMC can only be controlled on aarch64-darwin";
      } ];
      launchd.daemons = {
        poll-smc-charging = {
          serviceConfig = {
            RunAtLoad = true;
            StartInterval = 60;
            ProgramArguments = darwinWait4Nix (lib.escapeShellArgs [
              (lib.getExe self.packages.${pkgs.system}.clamp-smc-charging)
              cfg.clamp-service.min
              cfg.clamp-service.max
            ]);
          };
        };
      };
    })
    (lib.mkIf cfg.xbar-plugin.enable (let
      inherit (self.packages.${pkgs.system}) xbar-battery-plugin;
    in {
      environment = {
        etc."sudoers.d/nix-tools-battery-control".text = pkgs.lib.concatMapStringsSep "\n" (bin: ''
          ALL ALL = NOPASSWD: ${bin}
        '') xbar-battery-plugin.sudo-binaries;
      };
      # Assume home-manager is used.
      home-manager.sharedModules = [ ({ ... }: {
        home.file.xbar-battery-plugin = {
          # The easiest way to copy a binary whose name I don’t know, is to
          # just copy the entire directory recursively, because I know it’s
          # the only binary in there, anyway :)
          source = "${xbar-battery-plugin}/bin/";
          target = "Library/Application Support/xbar/plugins/";
          recursive = true;
          executable = true;
        };
      }) ];
    }))
  ];
}
