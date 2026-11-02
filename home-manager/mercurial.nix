{ config, lib, ... }: {
  options.hly.mercurial = lib.mkEnableOption "Mercurial configuration";
  config = lib.mkIf config.hly.mercurial {
    programs.mercurial.iniContent.ui.ignore = toString (
      builtins.toFile "hgignore" ''
        syntax: glob
        ${builtins.readFile config.hly.git.gitignore}
      ''
    );
  };
}
