{ config, lib, ... }: {
  options.hly.hraban-vcs-author = lib.mkEnableOption "Author Git and Mercurial commits as Hraban";
  config = lib.mkIf config.hly.hraban-vcs-author {
    programs =
      let
        userName = "Hraban";
        userEmail = "hraban@0brg.net";
      in
      {
        git.settings.user = {
          name = userName;
          email = userEmail;
        };
        mercurial = { inherit userName userEmail; };
      };
  };
}
