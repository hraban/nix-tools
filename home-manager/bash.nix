{ config, lib, ... }: {
  options.hly.bash = lib.mkEnableOption "My bash configuration";
  config = lib.mkIf config.hly.bash {
    hly.shell-aliases.enable = true;
    programs.bash = {
      enable = true;
      shellOptions = [
        "globstar"
        "histreedit"
        "extglob"
      ];
      historyControl = [
        "ignorespace"
        "ignoredups"
      ];
      # Don't call this bash_history because that's the default, and bash
      # --norc --noprofile will clobber it.
      historyFile = "${config.home.homeDirectory}/.sh_history";
      # This is just too useful
      historySize = 1000000;
      historyFileSize = 1000000;
    };
  };
}
