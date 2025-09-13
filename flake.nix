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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      cl-nix-lite,
      systems,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      let
        # Avoid typos
        systemNames = flake-utils.lib.system;
      in
      { withSystem, flake-parts-lib, ... }:
      {
        systems = import systems;
        imports = [ inputs.treefmt-nix.flakeModule ];
        flake = {
          darwinModules = {
            # Module to allow darwin hosts to get the timezone name as a string
            # without a password. Insanity but ok. Separate module because it
            # affects different parts of the system and I want all that code grouped
            # together.
            get-timezone = import ./darwin-get-timezone.nix;
            battery-control = flake-parts-lib.importApply ./darwin-battery-control.nix { inherit withSystem; };
            linux-builder-bootstrap = import ./darwin-bootstrap-builder.nix;
            nix-collect-old-garbage = flake-parts-lib.importApply ./darwin-gc-old.nix { inherit withSystem; };
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
            env-trampoline =
              {
                drv,
                name ? drv.name,
                env ? { },
                # Convenience wrapper for env which fetches keys from 1password
                _1password ? { },
                pkgs,
              }:
              with pkgs;
              let
                # Special case for 1p: instead of reading every secret with ‘op read’,
                # substitute them all once using ‘op run’. This requires fewer calls.
                exports1p = lib.mapAttrsToList (
                  name: value: ''export ${name}=${lib.escapeShellArg value}''
                ) _1password;
                # Separate line for reading the variable and exporting it as an envvar
                # because that’s required to make bash detect failure of the command
                # substitution and bubble it up to the script itself for set -e to
                # work as intended.
                exportsRest = lib.mapAttrsToList (name: value: ''
                  ${name}="$(${value})"
                  export ${name}
                '') env;
                exports = lib.concatStringsSep "\n" (exports1p ++ exportsRest);
              in
              writeScriptBin name (
                ''
                  #! ${runtimeShell}
                  set -euo pipefail
                  ${exports}
                ''
                + (
                  if _1password == { } then
                    ''
                      exec ${lib.escapeShellArg (lib.getExe drv)} "$@"
                    ''
                  else
                    ''
                      exec ${lib.getExe pkgs._1password-cli} run -- ${lib.escapeShellArg (lib.getExe drv)} "$@"
                    ''
                )
              );
          };
        };
        perSystem =
          {
            system,
            pkgs,
            lib,
            ...
          }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              # For 1password
              config.allowUnfree = true;
              overlays = [ cl-nix-lite.overlays.default ];
            };
            treefmt = {
              projectRootFile = "flake.nix";
              programs.nixfmt = {
                enable = true;
                strict = true;
              };
            };
            packages =
              let
                lpl = pkgs.lispPackagesLite;
                systemMatch = lib.meta.availableOn { inherit system; };
                keep = drv: (lib.isDerivation drv) && (systemMatch drv);
              in
              lib.filterAttrs (_: keep) (
                lib.packagesFromDirectoryRecursive {
                  inherit (pkgs) callPackage newScope;
                  directory = ./packages;
                }
              );
          };
      }
    );
}
