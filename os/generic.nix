# Ad-hoc OS modules compatible with nixos and nix-darwin

{
  imports = [
    ./flake-inputs.nix
    ./home-manager.nix
    ./harly-barluy-user.nix
    ./harly-barluy-stream-vps.nix
    ./packages-extra.nix
    ./packages-nixpkgs.nix
  ];
}
