{ config, lib, ... }: {
  options.hly.shell-aliases = {
    enable = lib.mkEnableOption "Enable my standard shell aliases";
    eshell-compatible = lib.mkOption {
      description = ''
        The aliases which are compatible with sh and eshell.

        Exported here purely as an idiosyncracy for my personal flake, where I
        use these to make eshell aliases.
      '';
      readOnly = true;
      type = with lib.types; attrsOf str;
    };
  };
  config =
    let
      eshellCompatible = {
        # Git. Don’t hard-code path ("${pkgs.git}/bin/git") because these are
        # "soft aliases": if git is installed, great, but if not, no need to
        # install git just for the sake of these aliases.
        g = "git";
        gc = "git commit";
        gs = "git status";
        gd = "git diff";
        gdc = "git diff --cached";
        gdns = "git diff --name-status";
        gsns = "git show --name-status";
        gcva = "git commit -va";
        gl1 = "git tree1";
        gl = "git tree";

        # Light weight aliases
        l = "ls";
        s = "cd ..";
        rgi = "rg -i";
        dfh = "df -h /"; # how much space do I have left
        # Find source code files by filename
        rgf = "rg --files | rgi";
        # Who cares about parallelism; sort the damned output
        rg = "rg --sort path";
        tmp = "mkdir -p ~/tmp; cd ~/tmp";
      };
      rest = {
        y2j = "ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))'";
        i2j = "python3 -c 'cp=__import__(\"configparser\").ConfigParser();cp.read_file(__import__(\"sys\").stdin);print(__import__(\"json\").dumps(cp._sections))'";
        # Turn the envvars from the app.yaml in your current dir to bash var
        # declarations Read AWS credentials from local file into envvars
        awsenv = ''eval "$(<~/.aws/credentials  i2j | jq -r '.default | to_entries[] | "export \(.key | ascii_upcase)=\(.value)"')" '';
        # like tr but more robust; works on strings and newlines etc.
        trs = ''python3 -c '(lambda s: s.stdout.write(s.stdin.read().replace(*s.argv[1:])))(__import__("sys"))' '';
        # Print args. Useful for debugging bash quoting behavior.
        args = ''python3 -c "print(__import__(\"sys\").argv[1:])" '';
        unquote = "python3 -c 'import urllib.parse as u; import sys; print(u.unquote(sys.stdin.read()))' ";
        # Unquote quoted-printable e-mails
        unquopri = ''python3 -c 'print(__import__("quopri").decodestring(__import__("sys").stdin.read()))' '';
        # tHe sPoNgEbOb mEmE
        spongebob = ''python3 -c '(lambda s: s.stdout.write("".join(map( lambda x: x[1].upper() if x[0]%2 else x[1].lower(), enumerate(s.stdin.read())))))(__import__("sys"))' '';

        # yt-dlp goes out of date so fast it makes sense to always fetch from nixpkgs-unstable.
        yt-dlp = "nix --experimental-features 'nix-command flakes' run github:nixos/nixpkgs/nixpkgs-unstable#yt-dlp --";
        # Emacs has built-ins for these and it doesn’t like an alias that
        # automatically sets this flag, for some reason.  Figure it out later.
        cp = "cp -i";
        mv = "mv -i";
        rm = "rm -i";
      };
    in
    lib.mkIf config.hly.shell-aliases.enable {
      hly.shell-aliases.eshell-compatible = eshellCompatible;
      # Don’t hard-code the paths to derivations, but use PATH.  This avoids
      # pulling in an entire python or ruby just for this alias, which wouldn’t
      # be worth it.
      home.shellAliases = eshellCompatible // rest;
    };
}
