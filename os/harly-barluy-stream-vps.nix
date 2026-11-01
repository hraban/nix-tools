# VPS for a Harly Barluy stream
{
  config,
  lib,
  options,
  pkgs,
  ...
}:
{
  options.hly.harly-barluy.vps = lib.mkEnableOption "It's a Harly Barluy stream VPS";

  config = lib.optionalAttrs (options ? nixosModule) (
    lib.mkIf config.hly.harly-barluy.vps {
      nixpkgs.config.allowUnfree = true;
      hly.harly-barluy.user = true;
      hly.packages.fromNixpkgs = true;
      home-manager.users.hly.hly.harly-barluy-streamer = true;
      virtualisation.docker.enable = true;
      programs.mosh.enable = true;
      environment.systemPackages = with pkgs; [
        binutils
        claude-code
        emacs
        file
        net-tools
        tmux
        unixtools.xxd
      ];
      # I know I want to make things public when I bind to 3003.
      networking.firewall.allowedTCPPorts = [ 3003 ];
    }
  );
}
