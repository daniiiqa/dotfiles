#!/usr/bin/env bash
# Arranca waybar y lo relanza si se cae por un crash (SIGSEGV/SIGABRT).
# El módulo mpris de waybar puede segfaultear al inicio si un reproductor
# aparece en D-Bus mientras la barra arranca. Si lo matas a propósito
# (pkill/killall → SIGTERM) no se relanza.

for _ in 1 2 3 4 5; do
  waybar "$@"
  case $? in
    134|139) sleep 1 ;;   # abort / segfault → reintentar
    *) exit ;;
  esac
done
