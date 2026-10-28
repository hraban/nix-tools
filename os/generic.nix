# Ad-hoc OS modules compatible with nixos and nix-darwin

let
  # Selection of my favorite packages from nixpkgs, nothing special, can import
  # this everywhere.
  nixpkgsPackages =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.hly.packages.fromNixpkgs = lib.mkEnableOption "Selection of my favorite packages from nixpkgs";
      options.hly.packages.desktop = lib.mkEnableOption "Packages for desktop computers (not just server with CLI)";
      config = lib.mkIf config.hly.packages.fromNixpkgs {
        environment.systemPackages =
          with pkgs;
          [
            # Core utilities for managing any system
            coreutils
            curl
            findutils # GNU find and xargs everywhere, for consistency (xargs -r!)
            gnused
            gnugrep
            gnutar
            htop
            moreutils
            mtr # useful for network debugging
            pstree
            pv
            rename
            rsync
            tree
            wget

            # Core utilities for any desktop / workstation
            awscli2
            aws-vault
            bat
            bc
            cachix
            direnv
            fasd
            fzf
            gnupg1
            git
            git-absorb
            gron
            ispell # nice for Emacs
            jq
            mercurial # for Nix
            mosh
            pandoc # for Emacs’ org-web-tools
            ripgrep
            sbcl # too useful to pass up on
            vim
            # Don’t bake yt-dlp. Always use nix run
            # github:nixos/nixpkgs/nixpkgs-unstable#yt-dlp because it changes so
            # often that you always want the bleeding edge.

            # Rest
            restic
          ]
          ++ lib.optionals config.hly.packages.desktop (
            lib.optionals pkgs.stdenv.hostPlatform.isLinux (with pkgs; [ vlc ])
            ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
              with pkgs;
              [
                lima
                colima
                docker
                utm
                vlc-bin
              ]
            )
          );
      };
    };
in
{
  imports = [ nixpkgsPackages ];
}
