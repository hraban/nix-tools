# Copyright © Hraban Luyat
#
# Licensed under the AGPLv3-only.  See README for years and terms.

{
  inputs = {
    cl-nix-lite.url = "github:hraban/cl-nix-lite";
    systems.url = "systems";
    flake-utils = {
      url = "flake-utils";
      inputs.systems.follows = "systems";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = {
    self
  , nixpkgs
  , flake-utils
  , cl-nix-lite
  , systems
  , flake-parts
  , ...
  }@inputs: flake-parts.lib.mkFlake { inherit inputs; } (let
    # Avoid typos
    systemNames = flake-utils.lib.system;
  in { withSystem, flake-parts-lib, ... }: {
    systems = import systems;
    flake = {
      darwinModules = {
        # Module to allow darwin hosts to get the timezone name as a string
        # without a password. Insanity but ok. Separate module because it
        # affects different parts of the system and I want all that code grouped
        # together.
        get-timezone = import ./darwin-get-timezone.nix;
        battery-control = flake-parts-lib.importApply ./darwin-battery-control.nix {
          inherit withSystem;
        };
        nix-collect-old-garbage = flake-parts-lib.importApply ./darwin-gc-old.nix {
          inherit withSystem;
        };
      };
      nixosModules = {
        digitaloceanUserdataSecrets = import ./nixos-do-user-secrets.nix;
        nix-collect-old-garbage = import ./nixos-gc-old.nix;
      };
      lib = {
        # Wrap a binary in a trampoline script that gets envvars by running a
        # command. Use this with a key store like keychain or 1p to
        # transparently get secrets for an interactive command. Compare this to
        # a baked-in aws-vault exec.
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
          # substitution and bubble it up to the script itself for set -e to
          # work as intended.
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
            exec ${lib.getExe pkgs._1password-cli} run -- ${lib.escapeShellArg (lib.getExe drv)} "$@"
          ''));
      };
    };
    perSystem = { system, pkgs, lib, ... }: {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        # For 1password
        config.allowUnfree = true;
      };
      packages = let
        lpl = (pkgs.extend cl-nix-lite.overlays.default).lispPackagesLite;
      in {
        aws-1password = pkgs.callPackage ({
          writeShellApplication
        , _1password-cli
        , awscli
        }: writeShellApplication {
          runtimeInputs = [ _1password-cli awscli ];
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
        nix-in-docker = pkgs.writeShellApplication {
          name = "nix-in-docker";
          text = builtins.readFile ./nix-in-docker.sh;
          meta = {
            homepage = "https://discourse.nixos.org/t/build-x86-64-linux-on-aarch64-darwin/35937/2?u=hraban";
          };
        };
      } // lib.optionalAttrs (builtins.elem system (with systemNames; [ x86_64-darwin aarch64-darwin ])) {
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
      } // lib.optionalAttrs (system == systemNames.x86_64-darwin) {
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
      } // lib.optionalAttrs (system == systemNames.aarch64-darwin) {
        clamp-smc-charging = pkgs.writeShellApplication {
          name = "clamp-smc-charging";
          text = builtins.readFile ./clamp-smc-charging;
          runtimeInputs = [ pkgs.smc-fuzzer ];
          # pmset
          meta.platforms = [ systemNames.aarch64-darwin ];
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
    };
  });
}
