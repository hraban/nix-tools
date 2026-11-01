{ config, lib, ... }: {
  options.hly.shell-aliases = lib.mkEnableOption "Enable my standard shell aliases";
  config = lib.mkIf config.hly.shell-aliases {
    # Don’t hard-code the paths to derivations, but use PATH.  This avoids
    # pulling in an entire python or ruby just for this alias, which wouldn’t
    # be worth it.
    home.shellAliases = {
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
    };
  };
}
