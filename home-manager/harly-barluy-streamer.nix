{ config, lib, ... }: {
  options.hly.harly-barluy-streamer = lib.mkEnableOption "User account for a Harly Barluy stream";
  config = lib.mkIf config.hly.harly-barluy-streamer {
    hly.agents = {
      enable = true;
      context = ''
        ## Environment
        The agent is running in a dedicated VM for this project.  Use the system to its full advantage.
      '';
    };
    hly.bash = true;
    hly.emacs.base = true;
    hly.git.enable = true;
    hly.hraban-vcs-author = true;
    hly.mercurial = true;
  };
}
