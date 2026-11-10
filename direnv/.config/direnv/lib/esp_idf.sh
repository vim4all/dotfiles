# direnv helper: `use esp_idf` in a project's .envrc loads the ESP-IDF
# environment (idf.py, toolchains, OpenOCD) on cd, and unloads it on leaving.
#
#   use esp_idf                 # ~/esp/esp-idf (or $IDF_PATH), as run_*.sh use
#   use esp_idf ~/esp/idf-v5.3  # a specific checkout
#
# Sourcing export.sh takes ~2 s, so its result (the PATH entries it prepends
# and the IDF_*/ESP_*/OPENOCD_* variables) is cached per IDF commit in
# ~/.cache/direnv-esp-idf/. After `git pull` / switching IDF versions the
# commit changes and the cache is rebuilt on the next cd.
# Force a rebuild: rm ~/.cache/direnv-esp-idf/*.env
use_esp_idf() {
  local idf="${1:-${IDF_PATH:-$HOME/esp/esp-idf}}"
  idf="${idf/#\~/$HOME}"
  if [ ! -f "$idf/export.sh" ]; then
    log_error "esp_idf: no export.sh in $idf"
    return 1
  fi
  local rev
  rev=$(git -C "$idf" rev-parse --short HEAD 2>/dev/null || echo nogit)
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/direnv-esp-idf/$(basename "$idf")-$rev.env"

  if [ ! -s "$cache" ]; then
    log_status "esp_idf: caching the environment of $idf ($rev) …"
    mkdir -p "$(dirname "$cache")"
    bash -c '
      old="$PATH"
      unset IDF_PYTHON_ENV_PATH
      source "$1/export.sh" >/dev/null 2>&1 || exit 1
      case "$PATH" in *"$old") ;; *) exit 2 ;; esac
      printf "IDF_ADD_PATH=%q\n" "${PATH%"$old"}"
      for v in $(compgen -e | grep -E "^(IDF_|ESP_|OPENOCD_)" |
                 grep -vE "^(IDF_DEACTIVATE_FILE_PATH|IDF_PY_COMP_WORDBREAKS)$"); do
        printf "export %s=%q\n" "$v" "${!v}"
      done
    ' _ "$idf" > "$cache.tmp" && mv "$cache.tmp" "$cache" || {
      rm -f "$cache.tmp"
      log_error "esp_idf: sourcing $idf/export.sh failed"
      return 1
    }
  fi

  local IDF_ADD_PATH
  # shellcheck disable=SC1090
  source "$cache"
  local p
  # PATH_add prepends, so add in reverse to keep export.sh's order
  local IFS=:
  local parts=($IDF_ADD_PATH)
  unset IFS
  for (( i=${#parts[@]}-1; i>=0; i-- )); do
    p="${parts[i]}"
    [ -n "$p" ] && PATH_add "$p"
  done
}
