#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

args=("$@")
mode=false
for arg in "${args[@]}"; do
  case "$arg" in
    --debug|--profile|--release) mode=true ;;
  esac
done
if [[ "$mode" == false ]]; then
  args=(--debug "${args[@]}")
fi

nix develop --command bash -c '
  set -euo pipefail
  flutter pub get
  flutter build apk "$@"
  printf "\nAPKs: %s/build/app/outputs/flutter-apk/\n" "$PWD"
' bash "${args[@]}"
