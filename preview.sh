#!/usr/bin/env bash
#
# Render pacebar against made-up numbers, so you can see how it looks without
# waiting to actually burn through a limit.
#
#   ./preview.sh              a gallery of typical states
#   ./preview.sh 42 55 30     your own: 5h %, week %, context %
#   ./preview.sh --configs    the same numbers under different settings

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

# One line per setting, to show what the knobs actually do.
configs() {
  local pairs=(
    "default"           ""
    "clock times"       "PB_TIME_PRESET=clock"
    "long times"        "PB_TIME_PRESET=long"
    "seconds, my way"   "PB_TIME_D='%dd %H:%M:%S'"
    "no 24h gauge"      "PB_24H=off"
    "reordered"         "PB_ORDER='ctx 7d 5h'"
    "6 cells"           "PB_5H_WIDTH=6 PB_24H_WIDTH=6 PB_7D_WIDTH=6 PB_CTX_WIDTH=6"
    "bars only"         "PB_5H_PCT=off PB_24H_PCT=off PB_7D_PCT=off PB_CTX_PCT=off"
    "stricter colours"  "PB_5H_WARN=30 PB_5H_CRIT=60 PB_7D_WARN=30 PB_7D_CRIT=60"
    "translated"        "PB_5H_LABEL='5ч:' PB_24H_LABEL='сут:' PB_7D_LABEL='нед:' PB_TIME_D='%dд %hч'"
  )
  local conf; conf=$(mktemp)
  local i
  for (( i = 0; i < ${#pairs[@]}; i += 2 )); do
    printf '%s\n' "${pairs[$((i+1))]}" > "$conf"
    printf '  \033[1m%-18s\033[0m' "${pairs[$i]}"
    feed 63 58 37 3 3 | PB_CONF=$conf COLUMNS=140 ./pacebar.sh
  done
  rm -f "$conf"
}

if [ "${1-}" = --configs ]; then
  printf '\n'; configs; printf '\n'
elif [ $# -ge 3 ]; then
  show "5h $1% · week $2% · ctx $3%" "$1" "$2" "$3" 3 5
else
  show "fresh start"                        8  2  4  4 6
  show "an ordinary afternoon"             46 38 33  3 4
  show "running hot"                       88 84 71  1 1
  show "yesterday left a surplus"          12  6 25  4 5
fi
echo
