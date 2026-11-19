# My home-manager module for Rectangle.app configuration
#
# Doesn’t actually install anything just hard-codes my config.  Also doesn’t
# even restart Rectangle after applying new settings.

{
  pkgs,
  config,
  lib,
  ...
}:
{
  options = {
    hly.rectangle-config.enable = lib.mkEnableOption "Set up Rectangle.app as I like it";
    targets.darwin.defaults."com.knollsoft.Rectangle" = lib.mkOption {
      description = ''
        Raw configuration for Rectangle.app.

        See https://eastmanreference.com/complete-list-of-applescript-key-codes
        for valid keycodes and modifier flags.
      '';
      type = with lib.types; (attrsOf anything);
      default = { };
    };
  };

  config = lib.mkIf config.hly.rectangle-config.enable {
    # Manually copied from defaults read com.knollsoft.Rectangle
    targets.darwin.defaults."com.knollsoft.Rectangle" =
      let
        # Emacs names.  See https://github.com/Hammerspoon/hammerspoon/issues/1021
        #
        # Nix doesn’t have exponent, bitwise shift, or even hexadecimal notation!
        # Wat?!
        S = 131072; # 1 << 17
        C = 262144; # 1 << 18
        M = 524288; # 1 << 19
        s = 1048576; # 1 << 20
        F = 8388608; # 1 << 23
        # Example: mod [ M s ] => 1572864;
        keys = {
          a = 0;
          s = 1;
          d = 2;
          f = 3;
          g = 5;
          h = 4;
          j = 38;
          k = 40;
          l = 37;
          q = 12;
          w = 13;
          e = 14;
          r = 15;
          t = 17;
          y = 16;
          u = 32;
          i = 34;
          o = 31;
          p = 35;
          left = 123;
          right = 124;
          down = 125;
          up = 126;
        };
        defaultShortcuts = {
          Spectacle = 0;
          Rectangle = 1;
        };
        mod = builtins.foldl' builtins.bitOr 0;
      in
      {
        alternateDefaultShortcuts = defaultShortcuts.Spectacle;
        launchOnLogin = true;
        centerHalf = {
          keyCode = keys.e;
          modifierFlags = mod [
            M
            s
          ];
        };
        centerThird = {
          keyCode = keys.r;
          modifierFlags = mod [
            M
            s
          ];
        };
        # Cycle sizes on half
        subsequentExecutionMode = 0;
      };
  };
}
