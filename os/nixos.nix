{ flake-inputs }: {
  imports = [
    flake-inputs.home-manager.nixosModules.home-manager
    ./generic.nix
  ];
}
