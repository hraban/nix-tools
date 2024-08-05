# Copyright © 2023–2024 Hraban Luyat
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

{
  inputs = {
    cl-nix-lite.url = "github:hraban/cl-nix-lite";
    systems.url = "systems";
    flake-utils = {
      url = "flake-utils";
      inputs.systems.follows = "systems";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    self
  , nixpkgs
  , flake-utils
  , cl-nix-lite
  , systems
  , ...
  }: let
    darwinWait4Nix = exec: [
      "/bin/sh" "-c"
      "/bin/wait4path /nix/store &amp;&amp; ${exec}"
    ];
    recursiveMergeAttrs = builtins.foldl' nixpkgs.lib.recursiveUpdate {};
  in {
    # Module to allow darwin hosts to get the timezone name as a string without
    # a password. Insanity but ok. Separate module because it affects different
    # parts of the system and I want all that code grouped together.
    darwinModules = {
      get-timezone = { pkgs, ... }:
        let
          get-timezone-su = pkgs.writeShellScriptBin "get-timezone-su" ''
            /usr/sbin/systemsetup -gettimezone | sed -e 's/[^:]*: //'
          '';
          get-timezone = pkgs.writeShellScriptBin "get-timezone" ''
            sudo ${get-timezone-su}/bin/get-timezone-su
          '';
        in
          {
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
          };
      battery-control = let
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
      };
      # This is my repo I’ll configure it however I want to.
      nix-collect-old-garbage = { lib, pkgs, config, ... }: {
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
      };
    };
    nixosModules = {
      # Don’t use this.
      digitaloceanUserdataSecrets = { pkgs, ... }: {
        # copied / cargo culted from the digitalocean-init service
        systemd.services.digitalocean-extract-keys = {
          description = "Extract secrets from do-userdata.nix comments";
          wantedBy = [ "network-online.target" "digitalocean-init.service" ];
          unitConfig = {
            ConditionPathExists = "/etc/nixos/do-userdata.nix";
            After = [ "digitalocean-metadata.service" ];
            Requires = [ "digitalocean-metadata.service" ];
            X-StopOnRemoval = false;
          };
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          restartIfChanged = true;
          path = with pkgs; [
            gnused
            coreutils
            findutils # xargs
          ];
          environment = {
            HOME = "/root";
            # ??
            NIX_PATH = pkgs.lib.concatStringsSep ":" [
              "/nix/var/nix/profiles/per-user/root/channels/nixos"
              "nixos-config=/etc/nixos/configuration.nix"
              "/nix/var/nix/profiles/per-user/root/channels"
            ];
          };
          # This doesn’t keep state so old secrets are not cleared up! Doesn’t
          # matter for userdata stuff anyway but good to keep in mind.
          script = ''
            set -e
            if [[ -f /etc/nixos/do-userdata.nix ]]; then
              < /etc/nixos/do-userdata.nix sed -ne 's/^\s*# secret: //p' | while read file secret; do
                (
                  umask 077
                  dirname "$file" | xargs mkdir -p
                  # Or actually printf "$secret" to allow escapes?
                  printf "%s" "$secret" > "$file"
                )
              done
            fi
          '';
        };
      };
      # If you use this you’re crazy
      nix-collect-old-garbage = { lib, pkgs, config, ... }: {
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
      };
    };
    # Jesus what a mess.
    packages = recursiveMergeAttrs [
      (nixpkgs.lib.genAttrs (with flake-utils.lib.system; [ x86_64-darwin aarch64-darwin ]) (system:
        let
          pkgs = nixpkgs.legacyPackages.${system}.extend cl-nix-lite.overlays.default;
          lpl = pkgs.lispPackagesLite;
        in {
          # Darwin-only because of ‘say’
          alarm = with lpl; lispScript {
            name = "alarm";
            src = ./alarm.lisp;
            dependencies = [
              arrow-macros
              f-underscore
              inferior-shell
              local-time
              trivia
              lpl."trivia.ppcre"
            ];
            installCheckPhase = ''
              $out/bin/alarm --help
            '';
            doInstallCheck = true;
          };
        }
      ))
      {
        x86_64-darwin =
          let
            pkgs = nixpkgs.legacyPackages.x86_64-darwin.extend cl-nix-lite.overlays.default;
            lpl = pkgs.lispPackagesLite;
          in {
            bclm = pkgs.stdenv.mkDerivation {
              name = "bclm";
              # There’s a copy of this binary included locally en cas de coup dur
              src = pkgs.fetchzip {
                url = "https://github.com/zackelia/bclm/releases/download/v0.0.4/bclm.zip";
                hash = "sha256-3sQhszO+MRLGF5/dm1mFXQZu/MxK3nw68HTpc3cEBOA=";
              };
              installPhase = ''
                mkdir -p $out/bin/
                cp bclm $out/bin/
              '';
              dontFixup = true;
              meta = {
                platforms = [ "x86_64-darwin" ];
                license = pkgs.lib.licenses.mit;
                sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
                downloadPage = "https://github.com/zackelia/bclm/releases";
                mainProgram = "bclm";
              };
            };
            xbar-battery-plugin = let
              bclm = pkgs.lib.getExe self.packages.x86_64-darwin.bclm;
            in with lpl; lispScript {
              name = "battery.30s.lisp";
              src = ./battery.30s.lisp;
              dependencies = [
                arrow-macros
                cl-interpol
                inferior-shell
                trivia
              ];
              inherit bclm;
              passthru.sudo-binaries = [ bclm ];
              postInstall = ''
                export self="$out/bin/$name"
                substituteAllInPlace "$self"
              '';
            };
          };
        aarch64-darwin =
          let
            pkgs = nixpkgs.legacyPackages.aarch64-darwin.extend cl-nix-lite.overlays.default;
            lpl = pkgs.lispPackagesLite;
          in {
            clamp-smc-charging = pkgs.writeShellApplication {
              name = "clamp-smc-charging";
              text = builtins.readFile ./clamp-smc-charging;
              runtimeInputs = [ pkgs.smc-fuzzer ];
              # pmset
              meta.platforms = [ "aarch64-darwin" ];
            };
            xbar-battery-plugin = let
              smc = pkgs.lib.getExe pkgs.smc-fuzzer;
              smc_on = pkgs.writeShellScript "smc_on" ''
                exec ${smc} -k CH0C -w 00
              '';
              smc_off = pkgs.writeShellScript "smc_off" ''
                exec ${smc} -k CH0C -w 01
              '';
            in with lpl; lispScript {
              name = "control-smc.1m.lisp";
              src = ./control-smc.1m.lisp;
              dependencies = [
                cl-interpol
                cl-ppcre
                inferior-shell
                trivia
              ];
              inherit smc smc_on smc_off;
              passthru.sudo-binaries = [ smc_on smc_off ];
              postInstall = ''
                export self="$out/bin/$name"
                substituteAllInPlace "$self"
              '';
            };
          };
      }
      (nixpkgs.lib.genAttrs (import systems) (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        # This relies on an unfree package. If you import this in a flake for
        # nixos or nix-darwin you can do this:
        #
        #     environment.systemPackages = [
        #       (nix-tools.packages.${pkgs.system}.aws-1password.override {
        #         inherit (pkgs) _1password;
        #       })
        #     ];
        #     nixpkgs.config.allowUnfree = true;
        #
        aws-1password = pkgs.callPackage ({
          writeShellApplication
        , _1password
        , awscli
        }: writeShellApplication {
          runtimeInputs = [ _1password awscli ];
          text = builtins.readFile ./aws-1password.sh;
          name = "aws-1p";
          derivationArgs = {
            meta.license = pkgs.lib.licenses.agpl3Only;
          };
        }) {};
        # Like nix-collect-garbage --delete-older-than 30d, but doesn’t delete
        # anything that was _added_ to the store in the last 30 days. Creates a
        # fresh GC root for those paths in /nix/var/nix/gcroots/rotating, from
        # where stale entries are only cleared out the next time you run this
        # again.
        nix-collect-old-garbage = pkgs.writeShellApplication {
          name = "nix-collect-old-garbage";
          runtimeInputs = with pkgs; [ sqlite findutils nix ];
          text = builtins.readFile ./nix-collect-old-garbage.sh;
          derivationArgs = {
            meta.license = pkgs.lib.licenses.agpl3Only;
          };
        };
      }))
    ];
    lib = {
      # Wrap a binary in a trampoline script that gets envvars by running a
      # command. Use this with a key store like keychain or 1p to transparently get
      # secrets for an interactive command. Compare this to a baked-in aws-vault
      # exec.
      env-trampoline = {
        drv
      , name ? drv.name
      , env ? {}
      # Convenience wrapper for env which fetches keys from 1password
      , _1password ? {}
      , pkgs
      }: with pkgs; let
        # Special case for 1p: instead of reading every secret with ‘op read’,
        # substitute them all once using ‘op run’. This requires fewer calls.
        exports1p = lib.mapAttrsToList (name: value: ''export ${name}=${lib.escapeShellArg value}'') _1password;
        # Separate line for reading the variable and exporting it as an envvar
        # because that’s required to make bash detect failure of the command
        # substitution and bubble it up to the script itself for set -e to work as
        # intended.
        exportsRest = lib.mapAttrsToList (name: value: ''
          ${name}="$(${value})"
          export ${name}
        '') env;
        exports = lib.concatStringsSep "\n" (exports1p ++ exportsRest);
      in writeScriptBin name (''
        #! ${runtimeShell}
        set -euo pipefail
        ${exports}
      '' + (
        if _1password == {}
        then ''
          exec ${lib.escapeShellArg (lib.getExe drv)} "$@"
        '' else ''
          exec ${lib.getExe pkgs._1password} run -- ${lib.escapeShellArg (lib.getExe drv)} "$@"
        ''));
    };
  };
}
