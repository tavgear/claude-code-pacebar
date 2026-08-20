#!/usr/bin/env bash
#
# pacebar — a status line for Claude Code.
#
# Shows how much of each rate-limit window you have burned, how long until it
# resets, and — the part you cannot get from the raw numbers — whether today's
# spending is ahead of or behind an even pace through the weekly window.
#
# Reads Claude Code's status-line JSON on stdin and prints a single line.
# Every label, width, colour and format below is configurable; see the
# "Defaults" block and pacebar.conf.example.
#
# https://github.com/tavgear/claude-code-pacebar

set -u

PB_VERSION=1.1.0

case ${1-} in
  -v|--version) printf 'pacebar %s\n' "$PB_VERSION"; exit 0 ;;
  -h|--help)    printf 'pacebar %s — a status line for Claude Code.\nUsage: pacebar.sh < status.json\nConfig: %s\nDocs:   https://github.com/tavgear/claude-code-pacebar\n' \
                  "$PB_VERSION" "${PB_CONF:-~/.claude/pacebar.conf}"; exit 0 ;;
esac

# ─── Defaults ────────────────────────────────────────────────────────────────
#
# Override any of these in $PB_CONF (default ~/.claude/pacebar.conf), which is
# sourced as plain bash. Every name also has a PB_M_* twin that replaces it on
# terminals narrower than PB_WIDE_MIN — that is the whole mobile mechanism.

# Layout
PB_WIDE_MIN=125                    # columns; below this the mobile preset applies
PB_ORDER="model 5h 24h 7d ctx"     # sections to print, in order
PB_SEP=' │ '                       # printed between sections; '  ' for plain spaces

# Sections on/off
PB_MODEL=on
PB_5H=on
PB_24H=on
PB_7D=on
PB_CTX=on

# Model
PB_MODEL_FMT='%n %e'     # %n — model name, %e — effort level
PB_MODEL_SHORT=off       # on → a single letter: O, S, H
PB_MODEL_STRIP=on        # drop a trailing parenthetical: "Opus 5 (1M)" → "Opus 5"

# Gauges: label, cells, percentage style (pct|num|off), time remaining (on|off),
# and the two colour thresholds.
PB_5H_LABEL='5h:'   PB_5H_WIDTH=12  PB_5H_PCT=pct  PB_5H_LEFT=on   PB_5H_WARN=50  PB_5H_CRIT=80
PB_24H_LABEL='24h:' PB_24H_WIDTH=12 PB_24H_PCT=pct PB_24H_LEFT=on  PB_24H_WARN=50 PB_24H_CRIT=80
PB_7D_LABEL='7d:'   PB_7D_WIDTH=12  PB_7D_PCT=pct  PB_7D_LEFT=on   PB_7D_WARN=50  PB_7D_CRIT=80
PB_CTX_LABEL='ctx:' PB_CTX_WIDTH=12 PB_CTX_PCT=pct PB_CTX_LEFT=off PB_CTX_WARN=50 PB_CTX_CRIT=80

# Colours, as 256-colour palette indices
PB_COLOR_OK=22           # fill below WARN
PB_COLOR_WARN=94         # fill between WARN and CRIT
PB_COLOR_CRIT=88         # fill at or above CRIT
PB_COLOR_EMPTY=236       # unfilled cells
PB_COLOR_TEXT=97         # caption over filled cells
PB_COLOR_TEXT_EMPTY=37   # caption over unfilled cells
PB_COLOR_DIM=90          # labels

# Time remaining. One template per magnitude, so the leading zero unit drops
# out by itself. Specifiers: %d days, %h/%H hours within the day, %m/%M minutes
# within the hour, %s/%S seconds within the minute (capitals are zero-padded),
# %tH/%tM/%tS totals, %% a literal percent sign.
PB_TIME_PRESET=compact   # compact | clock | long — fills the three templates
PB_TIME_D=''             # ≥ 1 day    — set to override the preset
PB_TIME_H=''             # < 1 day
PB_TIME_M=''             # < 1 hour

# Mobile preset. Any PB_M_<NAME> replaces PB_<NAME> on a narrow terminal; add
# your own the same way.
PB_M_MODEL_FMT='%n:'
PB_M_MODEL_SHORT=on
PB_M_24H=off
PB_M_5H_LABEL=''  PB_M_7D_LABEL=''  PB_M_CTX_LABEL=''
PB_M_5H_WIDTH=9   PB_M_7D_WIDTH=9   PB_M_CTX_WIDTH=9
PB_M_5H_PCT=num   PB_M_7D_PCT=num   PB_M_CTX_PCT=num

# ─── Configuration ───────────────────────────────────────────────────────────

PB_CONF=${PB_CONF:-$HOME/.claude/pacebar.conf}
# shellcheck source=/dev/null
[ -r "$PB_CONF" ] && . "$PB_CONF"

# Claude Code passes the terminal width in the environment; /dev/tty is not
# reachable from here.
COLS=${COLUMNS:-999}
if [ "$COLS" -lt "$PB_WIDE_MIN" ]; then
  for _v in $(compgen -v PB_M_); do
    printf -v "PB_${_v#PB_M_}" '%s' "${!_v}"
  done
fi

# Presets fill only the templates left empty, so an explicit one always wins.
case $PB_TIME_PRESET in
  clock) : "${PB_TIME_D:=%d-%H:%M}" "${PB_TIME_H:=%H:%M}"  "${PB_TIME_M:=00:%M}" ;;
  long)  : "${PB_TIME_D:=%dd %hh}"  "${PB_TIME_H:=%hh %mm}" "${PB_TIME_M:=%mm}"  ;;
  *)     : "${PB_TIME_D:=%dd%hh}"   "${PB_TIME_H:=%hh%mm}"  "${PB_TIME_M:=%mm}"  ;;
esac

CR=$'\033[0m'
printf -v C_DIM   '\033[%sm'          "$PB_COLOR_DIM"
printf -v C_OK    '\033[%s;48;5;%sm'  "$PB_COLOR_TEXT"       "$PB_COLOR_OK"
printf -v C_WARN  '\033[%s;48;5;%sm'  "$PB_COLOR_TEXT"       "$PB_COLOR_WARN"
printf -v C_CRIT  '\033[%s;48;5;%sm'  "$PB_COLOR_TEXT"       "$PB_COLOR_CRIT"
printf -v C_EMPTY '\033[%s;48;5;%sm'  "$PB_COLOR_TEXT_EMPTY" "$PB_COLOR_EMPTY"

# A bar cell carries a block glyph painted in its own background colour: a
# colour terminal renders it as solid fill, one without colour still shows the
# bar. Only the caption is set apart, so it stays readable either way.
printf -v B_OK    '\033[38;5;%s;48;5;%sm' "$PB_COLOR_OK"    "$PB_COLOR_OK"
printf -v B_WARN  '\033[38;5;%s;48;5;%sm' "$PB_COLOR_WARN"  "$PB_COLOR_WARN"
printf -v B_CRIT  '\033[38;5;%s;48;5;%sm' "$PB_COLOR_CRIT"  "$PB_COLOR_CRIT"
printf -v B_EMPTY '\033[38;5;%s;48;5;%sm' "$PB_COLOR_EMPTY" "$PB_COLOR_EMPTY"

# NO_COLOR (no-color.org): drop every escape, leaving the bars as block glyphs.
if [ -n "${NO_COLOR-}" ]; then
  CR='' C_DIM='' C_OK='' C_WARN='' C_CRIT='' C_EMPTY=''
  B_OK='' B_WARN='' B_CRIT='' B_EMPTY=''
fi

# ─── Input ───────────────────────────────────────────────────────────────────

input=$(cat)
now=${EPOCHSECONDS:-$(date +%s)}

MODEL='' EFFORT='' H5='' H5_LEFT='' W7='' W7_LEFT='' D24='' D24_LEFT='' CTX=''

# The JSON is read here in plain bash, so that a status line needs nothing but
# the shell. That is only reasonable because the input is not arbitrary: Claude
# Code writes it, and every field below is a plain number or string sitting in a
# named object. Anything that does not match leaves its variable empty, and the
# section drops out of the line — the same way a missing field behaves.

# $1 object name → $2 gets its body; one level of nesting inside it is allowed.
json_obj() {
  local re="\"$1\"[[:space:]]*:[[:space:]]*\{(([^{}]|\{[^{}]*\})*)\}"
  [[ $input =~ $re ]] && printf -v "$2" '%s' "${BASH_REMATCH[1]}" || printf -v "$2" '%s' ''
}

# $2 key in body $1 → $3 gets its number, integer part only.
json_int() {
  local re="\"$2\"[[:space:]]*:[[:space:]]*(-?[0-9]+)"
  [[ $1 =~ $re ]] && printf -v "$3" '%s' "${BASH_REMATCH[1]}" || printf -v "$3" '%s' ''
}

# $2 key in body $1 → $3 gets its number in hundredths: 46.87 → 4687. Bash has
# no fractions, and the 24h figure multiplies the weekly percentage by seven,
# so the two decimals are worth keeping until the last step.
json_centi() {
  local re="\"$2\"[[:space:]]*:[[:space:]]*([0-9]+)(\.([0-9]+))?" frac
  if [[ $1 =~ $re ]]; then
    frac="${BASH_REMATCH[3]}00"
    printf -v "$3" '%s' "$(( ${BASH_REMATCH[1]} * 100 + 10#${frac:0:2} ))"
  else
    printf -v "$3" '%s' ''
  fi
}

# $2 key in body $1 → $3 gets its string. A backslash escape does not end the
# string; the two escapes that can plausibly reach a model name are unwrapped,
# while \uXXXX is left as written rather than decoded.
json_str() {
  local re="\"$2\"[[:space:]]*:[[:space:]]*\"((\\\\.|[^\"\\\\])*)\"" v
  if [[ $1 =~ $re ]]; then
    v=${BASH_REMATCH[1]}
    v=${v//\\\"/\"}
    printf -v "$3" '%s' "${v//\\\\/\\}"
  else
    printf -v "$3" '%s' ''
  fi
}

json_obj model          _o ; json_str "$_o" display_name    MODEL
json_obj effort         _o ; json_str "$_o" level           EFFORT
json_obj context_window _o ; json_int "$_o" used_percentage CTX

json_obj five_hour _o
json_int "$_o" used_percentage H5
json_int "$_o" resets_at       _at
[ -n "$_at" ] && H5_LEFT=$(( _at > now ? _at - now : 0 ))

# The 24h gauge assumes the weekly allowance is meant to be spent evenly: the
# week is seven equal days worth 100/7 % each, counted from the start of the
# weekly window (resets_at − 7d) rather than from local midnight. Subtract the
# quota of the days already gone and you are left with today's spending, which
# scales to a percentage of today's share as 7·week − 100·days. Above 100 means
# borrowing from tomorrow; below zero means yesterday left a surplus. No state
# on disk, nothing but the numbers Claude Code already sends.
json_obj seven_day _o
json_int   "$_o" used_percentage W7
json_centi "$_o" used_percentage _w100
json_int   "$_o" resets_at       _at
if [ -n "$_at" ]; then
  W7_LEFT=$(( _at > now ? _at - now : 0 ))
  D24_LEFT=$(( W7_LEFT % 86400 ))
  _gone=$(( W7_LEFT < 604800 ? (604800 - W7_LEFT) / 86400 : 0 ))
  [ "$_gone" -gt 6 ] && _gone=6
  if [ -n "$_w100" ]; then
    _t=$(( 7 * _w100 - 10000 * _gone ))
    D24=$(( _t >= 0 ? (_t + 50) / 100 : -((-_t + 50) / 100) ))
  fi
fi

# ─── Rendering ───────────────────────────────────────────────────────────────

cfg() { local _n="PB_$1"; printf '%s' "${!_n}"; }

# Seconds → text, per the template matching the magnitude.
fmt_time() {
  local secs=$1 d h m s tpl mark=$'\001'
  [ "$secs" -le 0 ] && return
  d=$(( secs / 86400 ))
  h=$(( secs % 86400 / 3600 ))
  m=$(( secs % 3600 / 60 ))
  s=$(( secs % 60 ))

  if   [ "$d" -gt 0 ]; then tpl=$PB_TIME_D
  elif [ "$h" -gt 0 ]; then tpl=$PB_TIME_H
  else                      tpl=$PB_TIME_M
  fi

  tpl=${tpl//%%/$mark}                              # park literal % signs
  tpl=${tpl//%tH/$(( secs / 3600 ))}                # totals before parts, so
  tpl=${tpl//%tM/$(( secs / 60 ))}                  # %tH is not read as %t + H
  tpl=${tpl//%tS/$secs}
  tpl=${tpl//%d/$d}
  tpl=${tpl//%H/$(printf '%02d' "$h")}
  tpl=${tpl//%h/$h}
  tpl=${tpl//%M/$(printf '%02d' "$m")}
  tpl=${tpl//%m/$m}
  tpl=${tpl//%S/$(printf '%02d' "$s")}
  tpl=${tpl//%s/$s}
  printf '%s' "${tpl//$mark/%}"
}

# A bar of $3 cells, filled to $1 percent, with $2 centred across it.
# Fill level and caption are deliberately separate: the 24h caption runs past
# 100% and into negative numbers, while the fill stays inside the scale.
gauge() {
  local pct=$1 caption=$2 width=$3 warn=$4 crit=$5
  local filled fill solid start len i ch colour cell out=''

  [ "$pct" -lt 0 ]   && pct=0
  [ "$pct" -gt 100 ] && pct=100
  filled=$(( (pct * width + 50) / 100 ))

  if   [ "$pct" -ge "$crit" ]; then fill=$C_CRIT; solid=$B_CRIT
  elif [ "$pct" -ge "$warn" ]; then fill=$C_WARN; solid=$B_WARN
  else                              fill=$C_OK;   solid=$B_OK
  fi

  len=${#caption}
  start=$(( (width - len) / 2 ))
  [ "$start" -lt 0 ] && start=0

  for (( i = 0; i < width; i++ )); do
    if [ "$i" -lt "$filled" ]; then colour=$fill;    cell=$solid;   ch='▓'
    else                            colour=$C_EMPTY; cell=$B_EMPTY; ch='░'
    fi
    if [ "$i" -ge "$start" ] && [ "$i" -lt $(( start + len )) ]; then
      out+="${colour}${caption:$(( i - start )):1}"
    else
      out+="${cell}${ch}"
    fi
  done
  printf '%s%s' "$out" "$CR"
}

# $1 config key (5H|24H|7D|CTX), $2 fill 0..100, $3 caption value, $4 seconds left
section_gauge() {
  local key=$1 fill=$2 value=$3 secs=$4 caption='' time=''

  case $(cfg "${key}_PCT") in
    pct) caption="${value}%" ;;
    num) caption="$value" ;;
  esac

  [ "$(cfg "${key}_LEFT")" = on ] && [ -n "$secs" ] && time=$(fmt_time "$secs")

  local label
  label=$(cfg "${key}_LABEL")
  [ -n "$label" ] && label="$C_DIM$label$CR"

  printf '%s%s' "$label" \
    "$(gauge "$fill" "$caption" "$(cfg "${key}_WIDTH")" \
             "$(cfg "${key}_WARN")" "$(cfg "${key}_CRIT")")${time:+ $time}"
}

section_model() {
  local name=$MODEL out=$PB_MODEL_FMT
  [ "$PB_MODEL_STRIP" = on ] && name=${name%% (*}
  if [ "$PB_MODEL_SHORT" = on ]; then
    shopt -s nocasematch
    case $name in
      *opus*)   name=O ;;
      *sonnet*) name=S ;;
      *haiku*)  name=H ;;
    esac
    shopt -u nocasematch
  fi
  out=${out//%n/$name}
  if [ -n "$EFFORT" ]; then
    out=${out//%e/$EFFORT}
  else
    out=${out//(%e)/}                                        # no effort → drop
    out=${out//%e/}                                          # its slot, then
    while [[ $out == *"  "* ]]; do out=${out//  / }; done     # the gap it left
    while [[ $out == *" " ]];  do out=${out% }; done
  fi
  printf '%s' "$out"
}

# Today's gauge is the one that can go negative: a surplus carried over from
# yesterday shows as an empty bar captioned +N%.
section_24h() {
  local fill=$D24 value=$D24
  if [ "$D24" -lt 0 ]; then
    fill=0
    value="+$(( -D24 ))"
  fi
  section_gauge 24H "$fill" "$value" "$D24_LEFT"
}

parts=()
for name in $PB_ORDER; do
  case $name in
    model) [ "$PB_MODEL" = on ] && [ -n "$MODEL" ] && parts+=("$(section_model)") ;;
    5h)    [ "$PB_5H"  = on ] && [ -n "$H5"  ] && parts+=("$(section_gauge 5H  "$H5"  "$H5"  "$H5_LEFT")") ;;
    24h)   [ "$PB_24H" = on ] && [ -n "$D24" ] && parts+=("$(section_24h)") ;;
    7d)    [ "$PB_7D"  = on ] && [ -n "$W7"  ] && parts+=("$(section_gauge 7D  "$W7"  "$W7"  "$W7_LEFT")") ;;
    ctx)   [ "$PB_CTX" = on ] && [ -n "$CTX" ] && parts+=("$(section_gauge CTX "$CTX" "$CTX" '')") ;;
  esac
done

[ ${#parts[@]} -eq 0 ] && exit 0
sep="${PB_SEP:+$C_DIM$PB_SEP$CR}"
line=${parts[0]}
for (( i = 1; i < ${#parts[@]}; i++ )); do line+="$sep${parts[$i]}"; done
printf '%s\n' "$line"
