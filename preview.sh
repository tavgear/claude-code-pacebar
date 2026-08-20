#!/bin/bash
# Прогон statusline.sh на выдуманных данных — увидеть вид, не дожидаясь реальных лимитов.
#   ./preview.sh              — галерея типовых состояний
#   ./preview.sh 42 55 30     — своё: 5ч%, неделя%, контекст%
set -u
cd "$(dirname "$0")"

NOW=$(date +%s)

# $1 5ч%, $2 неделя%, $3 контекст%, $4 часов до сброса 5ч, $5 суток до сброса недели
feed() {
  jq -n --argjson h "$1" --argjson w "$2" --argjson c "$3" \
        --argjson r5 "$((NOW + $4 * 3600))" --argjson r7 "$((NOW + $5 * 86400))" \
    '{ model: { display_name: "Opus 5 (1M)" },
       effort: { level: "xhigh" },
       rate_limits: { five_hour: { used_percentage: $h, resets_at: $r5 },
                      seven_day: { used_percentage: $w, resets_at: $r7 } },
       context_window: { used_percentage: $c } }'
}

show() {  # $1 — подпись, дальше аргументы feed
  local label=$1; shift
  printf '\n\033[1m%s\033[0m\n' "$label"
  printf '  широко  '; feed "$@" | COLUMNS=140 ./statusline.sh
  printf '  узко    '; feed "$@" | COLUMNS=80  ./statusline.sh
}

if [ $# -ge 3 ]; then
  show "5ч $1% · нед $2% · ctx $3%" "$1" "$2" "$3" 3 5
else
  show "начало дня, всё свободно"           8 16  4  4 6
  show "рабочая середина"                  46 52 33  3 4
  show "поджимает"                         88 84 71  1 2
  show "запас со вчера — плашка дня в плюс" 12 20 25  4 5
fi
echo
