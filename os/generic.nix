# Ad-hoc OS modules compatible with nixos and nix-darwin

{
  imports = [
    ./home-manager.nix
    ./harly-barluy-user.nix
    ./harly-barluy-stream-vps.nix
    ./nixpkgs-packages.nix
  ];
}
