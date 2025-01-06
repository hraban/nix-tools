# Copyright © Hraban Luyat
#
# Licensed under the AGPLv3-only.  See README for years and terms.

# Don’t use this.

{ pkgs, ... }:

{
  # copied / cargo culted from the digitalocean-init service
  systemd.services.digitalocean-extract-keys = {
    description = "Extract secrets from do-userdata.nix comments";
    wantedBy = [ "network-online.target" "digitalocean-init.service" ];
    unitConfig = {
      ConditionPathExists = "/etc/nixos/do-userdata.nix";
      After = [ "digitalocean-metadata.service" ];
      Requires = [ "digitalocean-metadata.service" ];
      X-StopOnRemoval = false;
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    restartIfChanged = true;
    path = with pkgs; [
      gnused
      coreutils
      findutils # xargs
    ];
    environment = {
      HOME = "/root";
      # ??
      NIX_PATH = pkgs.lib.concatStringsSep ":" [
        "/nix/var/nix/profiles/per-user/root/channels/nixos"
        "nixos-config=/etc/nixos/configuration.nix"
        "/nix/var/nix/profiles/per-user/root/channels"
      ];
    };
    # This doesn’t keep state so old secrets are not cleared up! Doesn’t
    # matter for userdata stuff anyway but good to keep in mind.
    script = ''
      set -e
      if [[ -f /etc/nixos/do-userdata.nix ]]; then
        < /etc/nixos/do-userdata.nix sed -ne 's/^\s*# secret: //p' | while read file secret; do
          (
            umask 077
            dirname "$file" | xargs mkdir -p
            # Or actually printf "$secret" to allow escapes?
            printf "%s" "$secret" > "$file"
          )
        done
      fi
    '';
  };
}
