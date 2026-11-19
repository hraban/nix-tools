# Selection of my favorite packages from nixpkgs, nothing special, can import
# this everywhere.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.hly.flake-inputs) nix-index-database;
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  options.hly.packages.extra = lib.mkEnableOption "Packages I like which aren't in nixpkgs";
  config = lib.mkIf config.hly.packages.extra {
    environment.systemPackages = with nix-index-database.packages.${system}; [
      nix-index-with-db
      comma-with-db
    ];
  };
}
