# Custom (dany): el fetch de discada al abrir una terminal (cacha, o fastfetch
# si cacha no está). Se carga con `.` desde el .zshrc / .bashrc.
#
# En zsh, mientras no corras nada, cacha se queda en vivo (la info, el pixel
# art y el visualizador) y la terminal se anota: si cambias de look, de
# wallpaper o de estilo, `Fetch.sh refresh` le manda SIGUSR2 y ella limpia y
# vuelve a dibujar con lo nuevo (lo que ibas escribiendo se queda). En cuanto
# corres un comando, cacha se calla y la terminal sale de la lista.
#
# En otro escritorio (KDE, GNOME… en la misma compu) va fastfetch a secas: lo
# de discada es nomás para Hyprland. En una tty o por ssh sí sale cacha.

_discada_otro_escritorio() {
  [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ -n "${XDG_CURRENT_DESKTOP:-}" ] &&
    case ":$XDG_CURRENT_DESKTOP:" in *:Hyprland:*) false ;; *) true ;; esac
}

if _discada_otro_escritorio; then
  command -v fastfetch >/dev/null && fastfetch
elif [ -n "${ZSH_VERSION:-}" ] && [ -x "$HOME/.local/bin/cacha" ]; then
  _discada_dir="${XDG_RUNTIME_DIR:-/tmp}/discada-fetch"
  _discada_fetch="$_discada_dir/$$"
  _discada_cacha="$_discada_dir/.cacha-$$"
  zmodload zsh/zselect 2>/dev/null

  # cacha en vivo de esta terminal: que se vaya (y esperarla tantito, para
  # que no dibuje encima de lo que sigue)
  _discada_cacha_stop() {
    local p i
    [ -r "$_discada_cacha" ] && p=$(<"$_discada_cacha") || return 0
    rm -f "$_discada_cacha"
    kill "$p" 2>/dev/null || return 0
    for i in {1..20}; do kill -0 "$p" 2>/dev/null || break; zselect -t 1 2>/dev/null || sleep 0.01; done
  }

  "$HOME/.local/bin/cacha" --live --shell $$

  # adentro: cuándo arrancó esta zsh (/proc/<pid>/stat, campo 22), para que un
  # pid reusado por otra zsh nunca reciba la señal
  mkdir -p "$_discada_dir" && awk '{print $22}' /proc/$$/stat > "$_discada_fetch"

  _discada_fetch_off() {
    _discada_cacha_stop
    rm -f "$_discada_fetch"
    add-zsh-hook -d preexec _discada_fetch_off
    # TRAPUSR2 se queda: sin ella un SIGUSR2 tardío cerraría la terminal
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook preexec _discada_fetch_off
  add-zsh-hook zshexit _discada_fetch_off

  TRAPUSR2() {
    [ -e "$_discada_fetch" ] || return 0
    _discada_cacha_stop
    zle && zle -I                      # el prompt se vuelve a pintar abajo
    print -n '\e_Ga=d\e\\\e[H\e[2J\e[3J'   # sin imágenes de kitty ni texto
    "$HOME/.local/bin/cacha" --live --shell $$
    return 0
  }
else
  "$HOME/.config/hypr/scripts/Fetch.sh"
fi
