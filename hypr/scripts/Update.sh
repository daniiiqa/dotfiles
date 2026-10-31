#!/usr/bin/env bash
# Actualizar discada (menú de ajustes → "actualizar discada"). Corre en una
# terminal para que se vea lo que pasa y se pueda escribir la contraseña.
#
# - Si ~/.config es el repo (la máquina donde se desarrolla): guarda lo vivo
#   en el look actual, git pull --rebase --autostash y vuelve a aplicar el look.
# - Si discada se instaló con install.sh (repo en ~/dotfiles): git pull y
#   install.sh --update (conserva idioma, looks, look actual y tus ajustes;
#   solo instala paquetes que falten). Antes de copiar dice qué archivos
#   cambiaste: los que discada no cambió se quedan como los tienes, y si va a
#   reemplazar alguno pregunta (tu versión va al respaldo; UpdateCheck.py).

cfg="$HOME/.config"
scripts="$cfg/hypr/scripts"
looks="$cfg/hypr/looks"
. "$scripts/lang.sh"

say() { printf '\033[1;35m::\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m!!\033[0m %s\n' "$*"; notify-send -u critical "discada" "$*"; exit 1; }

reload_all() {
  "$scripts/FontSize.py" apply --no-reload
  "$scripts/AppColors.py" >/dev/null 2>&1
  hyprctl reload >/dev/null
  # la barra es empalme (antes waybar): relanzarla con el binario nuevo
  pkill -x waybar
  pkill -x empalme
  sleep 0.3
  setsid "$scripts/Bar.sh" >/dev/null 2>&1 &
  pkill -USR1 -x kitty
}

apply_look() {  # el look actual sobre lo vivo, desde su look.toml (como LookSwitch.sh)
  "$scripts/LookBuild.py" apply "$1"
}

if git -C "$cfg" rev-parse --is-inside-work-tree >/dev/null 2>&1 && [ -d "$cfg/hypr/looks" ]; then
  cur=$(cat "$looks/.current" 2>/dev/null)
  say "$(L "discada vive en ~/.config: actualizando el repo" "discada lives in ~/.config: updating the repo")"
  # lo vivo al look (como antes de cambiar de look), sin el tamaño de letra
  "$scripts/FontSize.py" unapply
  if [ -n "$cur" ] && [ -d "$looks/$cur" ]; then
    "$scripts/LookBuild.py" save "$cur"
  fi
  before=$(git -C "$cfg" rev-parse HEAD)
  if ! git -C "$cfg" pull --rebase --autostash; then
    "$scripts/FontSize.py" apply --no-reload
    fail "$(L "git pull falló: revisa el repo en ~/.config" "git pull failed: check the repo in ~/.config")"
  fi
  [ -n "$cur" ] && [ -d "$looks/$cur" ] && apply_look "$cur"
  reload_all
  if [ "$before" = "$(git -C "$cfg" rev-parse HEAD)" ]; then
    say "$(L "Ya estabas al día." "Already up to date.")"
  else
    git -C "$cfg" log --oneline "$before..HEAD"
    say "$(L "discada actualizada." "discada updated.")"
  fi
elif [ -d "$HOME/dotfiles/.git" ]; then
  say "$(L "Bajando la versión nueva de discada" "Downloading the new discada")"
  git -C "$HOME/dotfiles" pull --ff-only || fail "$(L "git pull falló en ~/dotfiles" "git pull failed in ~/dotfiles")"
  bash "$HOME/dotfiles/install.sh" --update || fail "$(L "install.sh --update falló" "install.sh --update failed")"
  reload_all
  "$scripts/Refresh.sh" >/dev/null 2>&1
else
  fail "$(L "No encontré el repo de discada (~/.config ni ~/dotfiles)" "Couldn't find the discada repo (~/.config or ~/dotfiles)")"
fi

notify-send -e -u low "discada" "$(L "Actualizada" "Updated")"
