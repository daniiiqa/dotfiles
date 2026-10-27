# discada

**A Hyprland rice made of looks.** A *discada* is the norteño dish where a bunch
of meats cook together on one disco and come out as one clean, delicious plate.
Here the meats are fourteen looks — each one changes the bar, fonts, icons, colors,
menus, lock screen and login — served on one rice. Colors come from your
wallpaper (video wallpapers too) through wallust.

Hecho en Monterrey, N.L. 🇲🇽 · [Leer en español](README.es.md)

## Install

On a fresh Arch install (internet + your user with sudo):

```bash
curl -fsSL https://raw.githubusercontent.com/daniiiqa/dotfiles/main/install.sh | bash
```

It asks for the language (English / Español), which looks you want and which
one to start with, then offers to reboot. Log into Hyprland from SDDM and the
first start sets a wallpaper, generates the colors and shows the shortcuts.
Your wallpapers (images or videos) go in `~/Pictures/wallpapers`.

What `install.sh` does (also runs from a clone: `./install.sh`; `--dry-run`
shows everything without touching anything; `--help` lists the options):

- clones the repo into `~/dotfiles` when run through curl
- packages: official repos with pacman; swww, mpvpaper, wallust and wlogout
  from the AUR with yay/paru (installs yay if there is none). Only the fonts of
  the looks you picked
- copies the rice folders into `~/.config`, backing up anything it overwrites
  in `~/.config-backup-<date>/`; displays are left on auto-detect
- taco as the default file browser, NetworkManager and bluetooth enabled
- on a laptop, brightnessctl and power-profiles-daemon (unless you use tlp)
- nvim: the LazyVim starter if you have no config; plus discada's colorscheme
  from `hypr/nvim/` (the rest of your config is left alone)
- SDDM with the simple_sddm_2 theme when there is no other display manager
  (`--no-sddm` / `--sddm` to force)
- builds [rola](https://github.com/daniiiqa/rola), [vato](https://github.com/daniiiqa/vato), [arre](https://github.com/daniiiqa/arre) and [taco](https://github.com/daniiiqa/taco) into `~/.local/bin`
- on first login, `hypr/scripts/FirstRun.sh` does the rest (a generated
  wallpaper if there is none, colors, dark GTK theme and icons)

Safe to run more than once.

## The essentials

| keys | |
|---|---|
| `SUPER+H` | cheat sheet (themed, type to filter) |
| `SUPER+Shift+E` | **discada settings**: look, shader, language, font size, visualizer, recorder, battery (laptops), game mode, blur, edit config, tools, update |
| `SUPER+T` | switch look (top entry: the look's shader on/off) |
| `SUPER+W` | wallpaper |
| `SUPER+M` | music (rola) |
| `ALT+Z` | recording menu · `ALT+F9` record · `ALT+F10` save replay |
| `SUPER+Shift+K` | search every shortcut |

## Looks

`brutalist` · `classic` · `glass` · `minimal` · `neon` · `nord` · `outsider` ·
`paper` · `pastel` · `retro`

Hecho en México: `fundidora` (Monterrey steel, blast-furnace orange, the Cerro
de la Silla) · `ofrenda` (Day of the Dead: marigolds, papel picado, candlelight)
· `loteria` (the card game: every module is a card) · `talavera` (Puebla
pottery: cream glaze, cobalt linework)

Each look lives in `hypr/looks/<name>/` as a mirror of `~/.config` with only
the files it changes: Hyprland decorations and animations, hyprlock, waybar
(config, style, app icons, visualizer style, recorder labels), rofi, arre,
wlogout, kitty, fastfetch, rola, SDDM and the wallust palette. `LookSwitch.sh`
saves the live files into the current look (so hand edits are kept) and copies
the new one on top.

## Pieces

- **Language**: English or Spanish for every menu, notification, tooltip and
  the cheat sheet (`hypr/discada.conf`, or the settings menu). rola follows it.
- **Recorder** (`Recorder.sh`): gpu-screen-recorder without its overlay. Screen,
  region or active window; pause; a replay buffer in RAM that starts at login.
  A themed indicator on the bar, a notification with a thumbnail when saved, and
  do-not-disturb while recording so popups stay out of the video. Settings in
  `hypr/recorder.conf` or the settings menu.
- **Audio visualizer** (`Visualizer.py`): only while music plays; it's also the
  player controls (click previous, middle pause, right next, wheel volume).
  Style per look: braille, peaks, blocks, ascii or pencil.
- **Open apps on the bar** (`AppStrip.py`): one icon per app, tinted by the
  look, icon set per look. 6+ apps collapse into a drawer. Click focuses (or
  cycles windows), middle-click closes. Pinned apps (`hypr/conf/pinned.conf`)
  always show; closed ones are dimmed and a click launches them.
- **Wallpaper per look**: the six fixed-palette looks (fundidora, ofrenda,
  lotería, talavera, nord, outsider) bring their own wallpaper
  (`hypr/wallpapers/`). Your wallpapers (videos included) are saved and come
  back when you switch to a look that follows the wallpaper; pick another
  wallpaper while on a fixed look and that one stays.
- **GTK and Qt apps follow the look**: `AppColors.py` takes the look's colors
  (wallust's or the fixed palette) into GTK 3 (adw-gtk3), GTK 4/libadwaita and
  Qt (Fusion + qt5ct/qt6ct palette), light or dark to match.
- **Update discada** from the settings menu: on an installed machine it pulls
  the new version and runs `install.sh --update` (keeps your language, looks,
  current look and settings; only installs what's missing).
- **Login (SDDM)** follows the look (font, shape, palette) and the wallpaper's
  colors, with no sudo (`SDDMWallpaperSync.sh`).
- **Per-monitor wallpapers**: swww for images/gifs, one mpvpaper per monitor
  only where there's a video. Game mode pauses them and revives them on exit.
- **Colors from video wallpapers**: the middle frame goes through wallust, so
  waybar, rofi, kitty, arre, hyprlock and SDDM match.
- **Readable on any wallpaper**: wallust with `check_contrast`, then
  `ContrastFix.py` lifts any text color to 4.5:1 (WCAG AA).
- **Files: [taco](https://github.com/daniiiqa/taco)** — discada's file manager
  in kitty (`SUPER+E`, and for "open folder" from apps), styled by the look like
  vato: three columns, image/video/PDF previews, copy and move in the
  background, trash, USB drives (`M`), zoxide (`z`) and fzf (`f`). `?` lists the
  keys.
- **Editor: nvim with LazyVim** following the look: the `discada` colorscheme
  (`hypr/nvim/`) takes the colors from the look's kitty theme and
  the style from `look.json` (floating window borders, how the selection is
  marked, phosphor or ink, transparency) and reloads itself when the look or
  the wallpaper changes.
- **Laptops**: battery on the bar (click changes the power profile, right click
  toggles the saver), brightness and keyboard light on their keys (the level
  shows in arre's popup), warnings at 20/10/5 %, and a page in the settings menu.
  **Battery saver** (`Battery.py`) sets the power-saver profile, drops blur,
  shadows and shader, and pauses video wallpapers; it turns on by itself at
  `BATTERY_SAVER_AT` (20 %) and off when you plug in. When idle the screen dims
  after 2.5 min and, on battery only, it suspends after 15. None of this shows
  up on a desktop.
- **`FitGuard.py`**: apps with a minimum size (Discord) float centered when
  their tile is too small.
- **System tools: [vato](https://github.com/daniiiqa/vato)** — audio, bluetooth,
  network and system in one terminal app, styled by each look like rola. The bar
  modules open it on the right tab (`Vato.sh`); `vato` from any terminal too.
- **Music: [rola](https://github.com/daniiiqa/rola)** — YouTube Music in the
  terminal. `rola --login` connects your account. Each look brings its own
  `rola/look.json`.

## Layout

```
hypr/
  hyprland.conf          only sources conf/*
  conf/                  defaults, env, startup, settings, decorations,
                         animations, windowrules, keybinds, pinned, livewallpaper
  discada.conf           language, font size (untracked; starts from hypr/seed/)
  recorder.conf          recorder settings (untracked; starts from hypr/seed/)
  wallpapers/            wallpapers of the fixed-palette looks
  looks/<look>/          what each look changes
  scripts/               every script
  shaders/               look screen shaders (outsider: film grain)
waybar/  rofi/  swaync/  wlogout/  kitty/  sddm/  rola/
wallust/wallust.toml + templates/
```

## Notes

- Files that change on their own are not tracked: the live copies of the
  current look (they come from `hypr/looks/<look>/`), the colors wallust
  generates with every wallpaper and rola's settings. `install.sh` puts
  starting copies from `hypr/seed/` in place when they're missing.
- `hypr/wallpaper_effects/` and `hypr/looks/.current` are ignored.

## Credits

Several scripts started from JaKooLit's Hyprland-Dots (GPL-3.0).
