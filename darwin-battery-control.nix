# Copyright © Hraban Luyat
#
# Licensed under the AGPLv3-only.  See README for years and terms.

{ withSystem }:

{ lib, pkgs, config, ... }: let
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
      package = mkOption {
        type = package;
        default = withSystem pkgs.system ({ config, ... }: config.packages.clamp-smc-charging);
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
      package = mkOption {
        type = package;
        default = withSystem pkgs.system ({ config, ... }: config.packages.xbar-battery-plugin);
      };
    };
  };
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
      launchd.daemons = let
        wait4nix = exec: pkgs.callPackage ./darwin-wait-4-nix.nix { inherit exec; };
      in {
        poll-smc-charging = {
          serviceConfig = {
            RunAtLoad = true;
            StartInterval = 60;
            ProgramArguments = wait4nix (lib.escapeShellArgs [
              (lib.getExe cfg.clamp-service.package)
              cfg.clamp-service.min
              cfg.clamp-service.max
            ]);
          };
        };
      };
    })
    (lib.mkIf cfg.xbar-plugin.enable {
      environment = {
        etc."sudoers.d/nix-tools-battery-control".text = pkgs.lib.concatMapStringsSep "\n" (bin: ''
          ALL ALL = NOPASSWD: ${bin}
        '') cfg.xbar-plugin.package.sudo-binaries;
      };
      # Assume home-manager is used.
      home-manager.sharedModules = [ ({ ... }: {
        home.file.xbar-battery-plugin = {
          # The easiest way to copy a binary whose name I don’t know, is to
          # just copy the entire directory recursively, because I know it’s
          # the only binary in there, anyway :)
          source = "${cfg.xbar-plugin.package}/bin/";
          target = "Library/Application Support/xbar/plugins/";
          recursive = true;
          executable = true;
        };
      }) ];
    })
  ];
}
