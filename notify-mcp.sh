#!/usr/bin/env bash

set -euo pipefail

# Устанавливаем DBUS_SESSION_BUS_ADDRESS если его нет
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

# --- JSON helpers ----------------------------------------------------------

send_result() {
  local id="$1"
  local result="$2"
  printf '{"jsonrpc":"2.0","id":"%s","result":%s}\n' "$id" "$result"
}

send_empty_result() {
  local id="$1"
  printf '{"jsonrpc":"2.0","id":"%s","result":null}\n' "$id"
}

send_error() {
  local id="$1"
  local msg="$2"
  printf '{"jsonrpc":"2.0","id":"%s","error":{"code":-32602,"message":"%s"}}\n' "$id" "$msg"
}

# Примитивный извлекатель значений из строки JSON
extract_value() {
  local key="$1"
  local src="$2"
  # Ищет "key":"value"
  echo "$src" |
    sed -n "s/.*\"$key\"[ ]*:[ ]*\"\\([^\"]*\\)\".*/\1/p"
}

# --- Основной цикл ----------------------------------------------------------

while IFS= read -r line; do

  id=$(extract_value "id" "$line")
  method=$(extract_value "method" "$line")

  [ -z "$id" ] && continue
  [ -z "$method" ] && continue

  case "$method" in
    "listTools")
      send_result "$id" '{"tools":[{"name":"show","description":"Show a desktop notification"}]}'
      ;;

    "show")
      title=$(extract_value "title" "$line")
      message=$(extract_value "message" "$line")

      # Defaults
      [ -z "$title" ] && title="Notification"
      [ -z "$message" ] && message=""

      notify-send "$title" "$message"

      send_empty_result "$id"
      ;;

    *)
      send_error "$id" "Unknown method $method"
      ;;
  esac

done
