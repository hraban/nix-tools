{ flake-inputs }: {
  imports = [
    flake-inputs.home-manager.darwinModules.home-manager
    ./generic.nix
    # Insane trick to allow os-specific module options without infinite
    # recursion.  lib.mkIf evaluates the entire thing regardless of whether the
    # flag is true or false and this causes an eval failure when e.g. you eval a
    # nixos module on nix-darwin.  You can’t use lib.optionalAttrs on config
    # because of infinite recursion (you’d need the module output to construct
    # the module).  But by using just ‘options ? ..’, you can greedy eval the
    # conditional, to make hybrid modules that work in both environments.
    # Thanks gemini for this idea ngl.
    ({ lib, ... }: { options.macosModule = lib.mkOption { }; })
  ];
}
