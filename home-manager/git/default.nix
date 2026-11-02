{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.hly.git = {
    enable = lib.mkEnableOption "My Git configuration";
    gitignore = lib.mkOption {
      readOnly = true;
      type = lib.types.pathInStore;
    };
  };
  config = {
    # Always export
    hly.git.gitignore = ./gitignore-global;
    programs.git = lib.mkIf config.hly.git.enable {
      enable = true;
      hooks = {
        pre-commit = ./pre-commit;
      };
      settings = {
        alias = {
          pfl = "push --force-with-lease";
          aa = "add -A";
          r = "rebase";
          b = "branch";
          co = "checkout";
          cb = "checkout -b";
          c = "commit";
          cv = "commit -v";
          cva = "commit -va";
          cvam = "commit -va --amend";
          staging-empty = "!git diff --cached --exit-code >/dev/null";
          empty = "!git staging-empty && git commit --allow-empty -m empty || >&2 echo Staging area not empty";
          # Tree for a single branch / ref;
          tree1 = "log --color --graph --format='format:%C(normal bold)%h%Creset %s%C(red)%d%Creset (%C(yellow)%aN%Creset, %C(green)%ar%Creset)'";
          # Tree for everything;
          tree = "tree1 --exclude='refs/notes/*' --all --branches=* --remotes=*";
        };
        core = {
          excludesfile = toString config.hly.git.gitignore;
        };
        init = {
          defaultBranch = "master";
        };
        transfer = {
          fsckObjects = true;
        };
        push = {
          default = "simple";
        };
        pull = {
          ff = "only";
        };
        fetch = {
          prune = true;
        };
        rebase = {
          autoSquash = true;
        };
        merge = {
          conflictStyle = "diff3";
        };
        color = {
          diff = {
            whitespace = "red reverse";
          };
        };
        diff = {
          wsErrorHighlight = "all";
          renameLimit = 10000;
          mnemonicPrefix = true;
          gpg = {
            textconv = "${pkgs.gnupg}/bin/gpg --batch -q --decrypt";
          };
        };
        include = {
          path = "~/.config/git/config.local";
        };
        rerere.enabled = true;
      };
    };
  };
}
