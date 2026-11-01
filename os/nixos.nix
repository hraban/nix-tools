{ flake-inputs }: {
  imports = [
    flake-inputs.home-manager.nixosModules.home-manager
    ./generic.nix
    ({ lib, ... }: { options.nixosModule = lib.mkOption { }; })
  ];
}
