#!/usr/bin/env bash
#
# Render pacebar against made-up numbers, so you can see how it looks without
# waiting to actually burn through a limit.
#
#   ./preview.sh              a gallery of typical states
#   ./preview.sh 42 55 30     your own: 5h %, week %, context %

set -u
cd "$(dirname "$0")"

NOW=$(date +%s)

# $1 5h %, $2 week %, $3 context %, $4 hours until the 5h reset, $5 days until the weekly reset
feed() {
  jq -n --argjson h "$1" --argjson w "$2" --argjson c "$3" \
        --argjson r5 "$((NOW + $4 * 3600 + 743))" --argjson r7 "$((NOW + $5 * 86400 + 11700))" \
    '{ model: { display_name: "Opus 5 (1M)" },
       effort: { level: "xhigh" },
       rate_limits: { five_hour: { used_percentage: $h, resets_at: $r5 },
                      seven_day: { used_percentage: $w, resets_at: $r7 } },
       context_window: { used_percentage: $c } }'
}

show() {  # $1 caption, then feed's arguments
  local caption=$1; shift
  printf '\n\033[1m%s\033[0m\n' "$caption"
  printf '  wide    '; feed "$@" | COLUMNS=140 ./pacebar.sh
  printf '  narrow  '; feed "$@" | COLUMNS=80  ./pacebar.sh
}

if [ $# -ge 3 ]; then
  show "5h $1% · week $2% · ctx $3%" "$1" "$2" "$3" 3 5
else
  show "fresh start"                        8 16  4  4 6
  show "an ordinary afternoon"             46 52 33  3 4
  show "running hot"                       88 84 71  1 2
  show "yesterday left a surplus"          12 20 25  4 5
fi
echo
