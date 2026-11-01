# User account for Harly Barluy streamer
#
# Not actually generic; technically I should move some of this to a nixos only
# dir.  Which would mean having a nixos dir in the first place...
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.hly.harly-barluy.user = lib.mkEnableOption "hly (Harly Barluy) user admin account on a VM";

  config = lib.mkIf config.hly.harly-barluy.user {
    nix.settings.trusted-users = [ "hly" ];
    # Home-manager wants _some_ value for this, might as well set it to
    # whatever
    home-manager.users.hly.home.stateVersion = "26.05";
    # Completely bespoke, assuming hly on a nixos VM
    users.users.hly = {
      isNormalUser = true;
      home = "/home/hly";
      description = "Harly Barluy";
      extraGroups = [
        "wheel"
        "docker"
        "networkmanager"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINIsIkaz3P7goG8/aky/dCn1G+ehMzPYXPsHOuB9fSN0"
      ];
    };
  };
}
