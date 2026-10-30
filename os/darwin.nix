{ flake-inputs }: {
  imports = [
    flake-inputs.home-manager.darwinModules.home-manager
    ./generic.nix
  ];
}
