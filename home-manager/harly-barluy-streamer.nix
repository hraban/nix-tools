{ config, lib, ... }: {
  options.hly.harly-barluy-streamer = lib.mkEnableOption "User account for a Harly Barluy stream";
  config = lib.mkIf config.hly.harly-barluy-streamer {
    hly.bash = true;
    hly.git.enable = true;
    hly.hraban-vcs-author = true;
    hly.mercurial = true;
  };
}
