#!/usr/bin/env bash
# Un look nuevo a partir de otro: copia hypr/looks/<base>/ a hypr/looks/<nombre>/
# y le pone su nombre. Luego se edita su look.toml (colores, fuente, estilo) y,
# si se quiere, los archivos de cada app de esa carpeta. Ver hypr/looks/README.md.
#
#   LookNew.sh NOMBRE [BASE]      BASE: el look de donde sale (minimal si no se dice)
#
# Ejemplo: LookNew.sh cobre fundidora   y luego   LookSwitch.sh cobre

looks="$HOME/.config/hypr/looks"
. "$HOME/.config/hypr/scripts/lang.sh"

name=$1
base=${2:-minimal}
if [[ ! $name =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
  echo "$(L "Uso" "Usage"): LookNew.sh $(L "nombre" "name") [$(L "base" "base")]   ($(L "minúsculas, números, - o _" "lowercase, digits, - or _"))"
  exit 2
fi
[ -f "$looks/$base/look.toml" ] || { echo "$(L "No existe el look" "No such look"): $base"; exit 1; }
[ -e "$looks/$name" ] && { echo "$(L "Ya existe" "Already exists"): $looks/$name"; exit 1; }

cp -r "$looks/$base" "$looks/$name"
# el nombre en el encabezado y una descripción para el menú y el instalador
sed -i -E "s/^# discada — look «[^»]*»/# discada — look «$name»/" "$looks/$name/look.toml"
sed -i -E "0,/^es = .*/s//es = \"$name (basado en $base)\"/; 0,/^en = .*/s//en = \"$name (based on $base)\"/" "$looks/$name/look.toml"
# el wallpaper fijo de la base (looks de paleta), si tiene
for ext in jpg png; do
  [ -f "$HOME/.config/hypr/wallpapers/$base.$ext" ] && cp "$HOME/.config/hypr/wallpapers/$base.$ext" "$HOME/.config/hypr/wallpapers/$name.$ext"
done

echo "$(L "Listo" "Done"): $looks/$name"
echo "  $(L "edita" "edit")   $looks/$name/look.toml"
echo "  $(L "pruébalo" "try it")  LookSwitch.sh $name"
