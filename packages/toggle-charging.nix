{ smc-fuzzer, writeShellApplication }:
writeShellApplication {
  name = "toggle-charging";
  meta.description = "Toggle charging on (my) macbook";
  runtimeInputs = [ smc-fuzzer ];
  text = ''
    register="CHIE"
    if [[ $# -eq 0 ]]; then
      status="$(smc -k "$register" -r)"
      if [[ "$status" == *"(bytes 08)"* ]]; then
        echo off
      elif [[ "$status" == *"(bytes 00)"* ]]; then
        echo on
      else
        >&2 echo "Failed to parse CHIE: $status"
        exit 1
      fi
      exit 0
    fi
    cmd="$1"
    case "$cmd" in
      on)
        smc -k "$register" -w 00
        exit 0
        ;;
      off)
        smc -k "$register" -w 01
        exit 0
        ;;
    esac
    >&2 echo "Usage: toggle-charging [on | off]"
    exit 1
  '';
  meta.platforms = [ "aarch64-darwin" ];
}
