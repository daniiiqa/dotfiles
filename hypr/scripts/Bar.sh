#!/usr/bin/env bash
# Arranca la barra (empalme) y la relanza si se cae por un crash (pánico,
# SIGSEGV/SIGABRT). Si la matas a propósito (pkill → SIGTERM) no se relanza.
# Esconder o mostrar: pkill -USR1 -x empalme (SUPER+CTRL+ALT+B).

bin="$HOME/.local/bin/empalme"
[ -x "$bin" ] || bin=empalme
pidof empalme >/dev/null && exit 0

for _ in 1 2 3 4 5; do
  "$bin" "$@"
  case $? in
    101|134|139) sleep 1 ;;   # pánico / abort / segfault → reintentar
    *) exit ;;
  esac
done
