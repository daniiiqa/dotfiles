#!/usr/bin/env bash
# Custom (dany): el motd de la entrada (Entrada.sh), juguetón: frases que
# salen de lo que traes ahorita. El juego de Steam que jugaste hace poco ("¿hoy
# le darás a Deadlock?"), el que más horas lleva, el que tienes abandonado o el
# que instalaste y ni abriste; tu artista de la semana en rola; el proyecto
# que estás picando; el día, la hora y el disco. 3 de cada 4 veces sale una de
# esas (si hay); si no, una de hypr/motd/<idioma>.txt.
#
#   Motd.sh           una frase
#   Motd.sh --todas   todas las que salen hoy (para verlas)
#   Motd.sh --guardar una frase, y se queda en $XDG_RUNTIME_DIR/discada-motd
#                     (la leen el candado y la ficha de cacha)
#   Motd.sh --foto    solo la foto de hoy de Steam (para `cacha semana`)
#   Motd.sh --leer    la guardada, y ya (la etiqueta del candado)
#   Motd.sh --alberca solo deja las dinámicas en $XDG_RUNTIME_DIR/discada-motd-alberca
#                     (de ahí escoge cacha una nueva cada vez que se invoca)

hypr="$HOME/.config/hypr"
# --leer: solo la guardada (el candado la pide seguido: nada de Steam aquí)
if [ "${1:-}" = --leer ]; then
  cat "${XDG_RUNTIME_DIR:-/tmp}/discada-motd" 2>/dev/null
  exit 0
fi
. "$hypr/scripts/lang.sh"
now=$(date +%s)
frases=()
# un tema = un renglón; sus versiones (si trae varias) van separadas por tabulador,
# para que un juego con tres frases no salga tres veces más que los demás
di() { frases+=("$(L "$1" "$2")"); }
otra() { frases[-1]+=$'\t'"$(L "$1" "$2")"; }

# ── Steam ─────────────────────────────────────────────────────────────────────
steam="$HOME/.local/share/Steam"
if [ -d "$steam/userdata" ]; then
  # el localconfig de la cuenta que se usó al último
  conf=$(ls -t "$steam"/userdata/*/config/localconfig.vdf 2>/dev/null | head -n1)
  # appid → nombre, de los manifiestos de todas las bibliotecas montadas
  # (sin Proton, runtimes ni herramientas: eso no se "juega")
  declare -A nombre instalado
  while read -r lib; do
    for m in "$lib"/steamapps/appmanifest_*.acf; do
      [ -f "$m" ] || continue
      id=${m##*_}; id=${id%.acf}
      n=$(sed -nE 's/^\s*"name"\s+"(.*)"$/\1/p' "$m" | head -n1)
      [[ $n =~ Proton|Steam\ Linux\ Runtime|Redistributable|Blender|Godot|Aseprite|editor|SDK|Soundtrack|Dedicated\ Server|Wallpaper\ Engine ]] && continue
      nombre[$id]=$n
      instalado[$id]=$(stat -c %Y "$m")
    done
  done < <(sed -nE 's/^\s*"path"\s+"(.*)"$/\1/p' "$steam/steamapps/libraryfolders.vdf" 2>/dev/null)

  # LastPlayed y Playtime (minutos) de cada juego
  declare -A jugado horas minutos
  if [ -f "$conf" ]; then
    while read -r id lp pt; do
      [ -n "${nombre[$id]:-}" ] || continue
      jugado[$id]=$lp; horas[$id]=$((pt / 60)); minutos[$id]=$pt
    done < <(awk '
      /^\t\t\t\t\t"[0-9]+"$/ { id = $0; gsub(/[\t"]/, "", id) }
      /^\t\t\t\t\t\t"LastPlayed"/ { v = $2; gsub(/"/, "", v); lp[id] = v }
      /^\t\t\t\t\t\t"Playtime"\t/ { v = $2; gsub(/"/, "", v); pt[id] = v }
      END { for (i in lp) print i, lp[i], (pt[i] == "" ? 0 : pt[i]) }' "$conf")
  fi

  # el de hace poco (4 días), el de más horas, los abandonados
  reciente="" r_lp=0 top="" t_h=0 olvidados=()
  for id in "${!jugado[@]}"; do
    lp=${jugado[$id]} h=${horas[$id]}
    ((lp > r_lp && now - lp < 4 * 86400)) && { reciente=$id; r_lp=$lp; }
    ((h > t_h)) && { top=$id; t_h=$h; }
    dias=$(((now - lp) / 86400))
    ((h >= 5 && dias >= 30 && dias <= 400)) && olvidados+=("$id:$dias")
  done
  if [ -n "$reciente" ]; then
    g=${nombre[$reciente]}
    di "¿hoy le darás a $g?" "playing $g today?"
    otra "¿otra partidita de $g?" "one more round of $g?"
    case $(date +%u) in
      5) otra "ya es viernes: ¿unas de $g?" "it's Friday: some $g?" ;;
      6|7) otra "fin de semana y $g, ¿o qué?" "weekend and $g, right?" ;;
    esac
  fi
  ((t_h >= 20)) && di "llevas ${t_h} horas en ${nombre[$top]}. respeto." "${t_h} hours in ${nombre[$top]}. respect."
  if ((${#olvidados[@]})); then
    o=${olvidados[RANDOM % ${#olvidados[@]}]}
    di "${nombre[${o%%:*}]} te extraña: ${o#*:} días sin jugarlo" "${nombre[${o%%:*}]} misses you: ${o#*:} days without playing"
  fi
  # instalado en el último mes y nunca abierto
  for id in "${!instalado[@]}"; do
    if [ -z "${jugado[$id]:-}" ] && ((now - ${instalado[$id]} < 30 * 86400)); then
      di "instalaste ${nombre[$id]} y ni lo has abierto" "you installed ${nombre[$id]} and never opened it"
      break
    fi
  done

  # la foto del día para `cacha semana` (cuánto llevas en cada juego): appid,
  # minutos, nombre y cuándo lo jugaste al último. Se guardan 60 días
  fotos="${XDG_STATE_HOME:-$HOME/.local/state}/discada/steam"
  if mkdir -p "$fotos"; then
    for id in "${!minutos[@]}"; do printf '%s\t%s\t%s\t%s\n' "$id" "${minutos[$id]}" "${nombre[$id]}" "${jugado[$id]}"; done > "$fotos/$(date +%F).tsv"
    find "$fotos" -name '*.tsv' -mtime +60 -delete 2>/dev/null
  fi
fi

# ── la música (rola): tu artista de la semana ────────────────────────────────
hist="$HOME/.local/share/rola/history.jsonl"
if [ -f "$hist" ] && command -v jq >/dev/null; then
  artista=$(tail -n 2000 "$hist" | jq -r --argjson desde $((now - 7 * 86400)) 'select(.t > $desde) | .artist | split(", ")[0]' 2>/dev/null |
    sort | uniq -c | sort -rn | awk 'NR == 1 && $1 >= 5 { $1 = ""; sub(/^ /, ""); print }')
  [ -n "$artista" ] && di "¿más $artista hoy?" "more $artista today?" && otra "esta semana fue de $artista" "this week was all $artista"
fi

# ── lo que estás picando: el repo con el commit más nuevo (2 días) ───────────
repo=$(for r in "$HOME"/*/; do [ -d "$r/.git" ] && echo "$(git -C "$r" log -1 --format=%ct 2>/dev/null || echo 0) $(basename "$r")"; done | sort -rn | head -n1)
if [ -n "$repo" ] && ((now - ${repo%% *} < 2 * 86400)); then
  di "¿le seguimos a ${repo#* }?" "back to ${repo#* }?"
fi

# ── el día, la hora y el disco ───────────────────────────────────────────────
hora=$((10#$(date +%H)))
case $(date +%u) in
  1) di "lunes... échale ganas" "Monday... you got this" ;;
  5) di "ya es viernes, compa" "it's Friday, compa" ;;
esac
((hora >= 1 && hora < 5)) && di "otra desvelada, ¿verdad?" "another all-nighter, huh?"
disco=$(df --output=pcent / 2>/dev/null | tail -n1 | tr -dc 0-9)
((${disco:-0} >= 90)) && di "tu disco anda al ${disco}%: ¿hacemos limpieza?" "your disk is at ${disco}%: cleanup time?"

# ── escoger ──────────────────────────────────────────────────────────────────
# la frase de ahorita se guarda para que el candado y la ficha de cacha digan
# lo mismo que el telón (se escoge otra en cada entrada y en cada bloqueo)
guardada="${XDG_RUNTIME_DIR:-/tmp}/discada-motd"
fijas() { grep -v -e '^#' -e '^[[:space:]]*$' "$hypr/motd/$DISCADA_LANG.txt" 2>/dev/null; }
# la alberca: las dinámicas de ahorita, para que cacha escoja una distinta en
# cada invocación sin esperar a Steam (la refresca en segundo plano con --alberca)
alberca="${XDG_RUNTIME_DIR:-/tmp}/discada-motd-alberca"
llenar() { printf '%s\n' "${frases[@]}" > "$alberca.$$" && mv -f "$alberca.$$" "$alberca"; }
case "${1:-}" in
  --todas) printf '%s\n' "${frases[@]}" | tr '\t' '\n'; exit 0 ;;
  --foto) exit 0 ;;
  --alberca) llenar; exit 0 ;;
  --guardar) llenar ;;
esac
if ((${#frases[@]})) && ((RANDOM % 4 != 0)); then
  # primero el tema, luego una de sus versiones
  IFS=$'\t' read -ra versiones <<<"${frases[RANDOM % ${#frases[@]}]}"
  frase=${versiones[RANDOM % ${#versiones[@]}]}
else
  frase=$(fijas | shuf -n1)
fi
[ "${1:-}" = --guardar ] && printf '%s\n' "$frase" > "$guardada"
printf '%s\n' "$frase"
