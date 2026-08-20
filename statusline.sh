#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // empty' | sed -E 's/ *\([^)]*\)$//')
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_R=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
WEEK_R=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
CTX=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

CR='\033[0m'
DIM='\033[90m'

# Ширину терминала Claude Code кладёт в окружение хука; /dev/tty отсюда недоступен.
# Узко (телефон) — старый компактный вид, широко — развёрнутый.
COLS=${COLUMNS:-999}
[ "$COLS" -ge 125 ] && WIDE=1 || WIDE=0
[ $WIDE -eq 1 ] && WIDTH=12 || WIDTH=9

# Плашка: $1 — заливка 0..100 (она же задаёт цвет), $2 — надпись по центру.
# Заливка и надпись разведены намеренно: у дневной плашки надпись уходит за 100%
# (перерасход) и в плюс (запас со вчера), а заливка остаётся в шкале.
bar() {
  local pct=$1 txt=$2 n=$WIDTH filled cf ce
  [ "$pct" -lt 0 ] && pct=0
  [ "$pct" -gt 100 ] && pct=100
  filled=$(( (pct * n + 50) / 100 ))

  ce='\033[37;48;5;236m'  # empty: dark gray
  # Filled color by severity (muted 256-color): <50 green, 50-79 yellow, 80+ red
  if [ "$pct" -ge 80 ]; then
    cf='\033[97;48;5;88m'   # white on dark red
  elif [ "$pct" -ge 50 ]; then
    cf='\033[97;48;5;94m'   # white on dark yellow
  else
    cf='\033[97;48;5;22m'   # white on dark green
  fi

  local tlen=${#txt}
  local start=$(( (n - tlen) / 2 ))
  [ $start -lt 0 ] && start=0
  local out="" ch color
  for ((i=0; i<n; i++)); do
    [ $i -lt $filled ] && color="$cf" || color="$ce"
    if [ $i -ge $start ] && [ $i -lt $(( start + tlen )) ]; then
      ch="${txt:$((i - start)):1}"
    else
      ch=" "
    fi
    out+="${color}${ch}"
  done
  out+="$CR"
  echo -e "$out"
}

# Длительность в секундах → «4д 14ч 24мин» (широко) или «4:14:24» (узко).
dur() {
  local diff=$1 d h m out=""
  [ "$diff" -le 0 ] && echo "" && return
  d=$(( diff / 86400 ))
  h=$(( (diff % 86400) / 3600 ))
  m=$(( (diff % 3600) / 60 ))
  if [ $WIDE -eq 0 ]; then
    if [ $d -gt 0 ]; then echo "${d}:${h}:$(printf '%02d' $m)"
    elif [ $h -gt 0 ]; then echo "${h}:$(printf '%02d' $m)"
    else echo "0:$(printf '%02d' $m)"; fi
    return
  fi
  [ $d -gt 0 ] && out="${d}д"
  [ $h -gt 0 ] && out="${out:+$out }${h}ч"
  [ $m -gt 0 ] && out="${out:+$out }${m}мин"
  echo "${out:-0мин}"
}

left() { dur $(( $1 - $(date +%s) )); }   # сколько осталось до момента $1 (epoch)

# Дневная доля недельного лимита: неделя = 7 суток по 100/7 % каждые.
# Сутки отсчитываются от старта недельного окна (resets_at − 7д), не от полуночи —
# ничего, кроме приходящих данных, для этого не нужно.
# Результат — проценты СЕГОДНЯШНЕЙ нормы: >100 = залез в завтра, <0 = запас со вчера.
day_pct() {
  awk -v w="$1" -v r="$2" -v now="$(date +%s)" 'BEGIN {
    ttl = r - now; if (ttl < 0) ttl = 0
    elapsed = 604800 - ttl; if (elapsed < 0) elapsed = 0
    norm = 100 / 7
    day = int(elapsed / 86400); if (day > 6) day = 6   # окно истекло — 7-х суток не бывает
    spent = w - day * norm
    pct = spent / norm * 100
    printf "%d", (pct >= 0 ? pct + 0.5 : pct - 0.5)
  }'
}

SEP="  "; [ $WIDE -eq 0 ] && SEP=" "
PARTS=""
add() { PARTS="${PARTS:+$PARTS$SEP}$1"; }

# Подпись плашки: широко — «нед:», узко — ничего (различаются порядком, как раньше).
tag() { [ $WIDE -eq 1 ] && printf '%b' "${DIM}$1:${CR}"; }
# Надпись внутри плашки: широко — со знаком процента.
num() { [ $WIDE -eq 1 ] && echo "$1%" || echo "$1"; }

if [ -n "$FIVE_H" ]; then
  P=${FIVE_H%.*}
  T=""; [ -n "$FIVE_R" ] && T=$(left "$FIVE_R")
  add "$(tag 5ч)$(bar "$P" "$(num "$P")")${T:+ $T}"
fi

# «День» стоит перед неделей, хотя считается из неё: сутки — рабочий горизонт,
# неделя — фон. Границы суток идут от старта окна, поэтому остаток текущих
# суток = остаток недели по модулю 24ч. На узком экране дня нет — старый вид.
if [ $WIDE -eq 1 ] && [ -n "$WEEK" ] && [ -n "$WEEK_R" ]; then
  D=$(day_pct "$WEEK" "$WEEK_R")
  T=$(dur $(( ($WEEK_R - $(date +%s)) % 86400 )))
  if [ "$D" -lt 0 ]; then
    add "$(tag день)$(bar 0 "+$(( -D ))%")${T:+ $T}"   # запас со вчера — плашка пустая
  else
    add "$(tag день)$(bar "$D" "${D}%")${T:+ $T}"
  fi
fi

if [ -n "$WEEK" ]; then
  P=${WEEK%.*}
  T=""; [ -n "$WEEK_R" ] && T=$(left "$WEEK_R")
  add "$(tag нед)$(bar "$P" "$(num "$P")")${T:+ $T}"
fi

[ -n "$CTX" ] && { P=${CTX%.*}; add "$(tag ctx)$(bar "$P" "$(num "$P")")"; }

if [ $WIDE -eq 1 ]; then
  HEAD="$MODEL${EFFORT:+ ${DIM}·${CR} $EFFORT}"
else
  HEAD="$(sed -E 's/.*(Opus).*/O/i; s/.*(Sonnet).*/S/i; s/.*(Haiku).*/H/i' <<<"$MODEL"):"
fi
[ -n "$PARTS" ] && echo -e "$HEAD$SEP$PARTS" || echo -e "$HEAD"
