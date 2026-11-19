{
  imports = [
    ./generic.nix
    ({ lib, ... }: { options.nixosModule = lib.mkOption { }; })
  ];
}
