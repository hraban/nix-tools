# Ad-hoc OS modules compatible with nixos and nix-darwin

{
  imports = [
    ./home-manager.nix
    ./hly-user.nix
    ./nixpkgs-packages.nix
  ];
}
