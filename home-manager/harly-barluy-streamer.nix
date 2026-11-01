{ config, lib, ... }: {
  options.hly.harly-barluy-streamer = lib.mkEnableOption "User account for a Harly Barluy stream";
  config = lib.mkIf config.hly.harly-barluy-streamer {
    programs.bash.enable = true;
    hly.shell-aliases.enable = true;
    hly.hraban-vcs-author = true;
  };
}
