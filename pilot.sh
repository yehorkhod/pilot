# ----------------------------------------------------------------
# ---------------------------- Paths -----------------------------
# ----------------------------------------------------------------
CONFIG_DIRECTORY="$HOME/.config/.pilot"
DESTINATIONS_FILE="$CONFIG_DIRECTORY/destinations.txt"

mkdir -p "$CONFIG_DIRECTORY"
touch "$DESTINATIONS_FILE"

# ----------------------------------------------------------------
# ---------------------------- Utils -----------------------------
# ----------------------------------------------------------------
check_destinations_file() {
  if [ ! -s "$DESTINATIONS_FILE" ]; then
    echo "No destinations found. Add directories first with 'pilot add <path>'."
    exit 1
  fi
}

fuzzy_find_directory() {
  local message="$1"
  cat "$DESTINATIONS_FILE" | fzf \ --prompt="$message" \
    --height=10 \
    --border \
    --reverse
}

connect_to_session() {
  local session_name="$1"
  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$session_name"
  else tmux attach-session -t "$session_name"
  fi
}

# ----------------------------------------------------------------
# -------------------------- Main Logic --------------------------
# ----------------------------------------------------------------
select_destination() {
  check_destinations_file
  local selected_directory=$(fuzzy_find_directory "Choose a destination: ")
  if [ -n "$selected_directory" ]; then
    local session_name=$(basename "$selected_directory")
    [[ $session_name == .* ]] && session_name="_${session_name:1}"
    if tmux list-sessions | grep -q "^$session_name:"; then
      connect_to_session "$session_name"
    else
      tmux new-session \
        -d \
        -s "$session_name" \
        -c "$selected_directory"
      connect_to_session "$session_name"
    fi
  else
    echo "No directory selected. Exiting."
  fi
}

add_destination() {
  local directory_to_add=$(realpath "$1")
  if grep -Fxq "$directory_to_add" "$DESTINATIONS_FILE"; then
    echo "Already there!"
  else
    echo "$directory_to_add" >> "$DESTINATIONS_FILE"
    echo "Added directory: $directory_to_add"
  fi
}

remove_destination() {
  check_destinations_file
  if [ -n "$1" ]; then
    local directory_to_remove=$(realpath "$1" 2>/dev/null)
    if [ -z "$directory_to_remove" ]; then
      echo "Error: Invalid path '$1'"
      exit 1
    fi
    if grep -Fxq "$directory_to_remove" "$DESTINATIONS_FILE"; then
      sed -i "\|$directory_to_remove|d" "$DESTINATIONS_FILE"
      echo "Removed directory: $directory_to_remove"
    else
      echo "Directory not found in destinations: $directory_to_remove"
      exit 1
    fi
  else
    local directory_to_remove=$(fuzzy_find_directory "Choose a directory to remove: ")
    if [ -n "$directory_to_remove" ]; then
      sed -i "\|$directory_to_remove|d" "$DESTINATIONS_FILE"
      echo "Removed directory: $directory_to_remove"
    else
      echo "No directory selected. Exiting."
    fi
  fi
}

list_destinations() {
  check_destinations_file
  cat "$DESTINATIONS_FILE" | nl -w2 -s': '
}

show_help() {
  echo "Usage:"
  echo "  pilot:             Start a session in a directory"
  echo "  pilot add <path>:  Add a directory to the list of destinations"
  echo "  pilot rm:          Remove a directory from the list of destinations"
  echo "  pilot rm <path>:   Remove a specific directory from the list"
  echo "  pilot list:        List all destinations"
}

invalid_command() {
  echo "Invalid command. See 'pilot --help' for usage."
  exit 1
}

# ----------------------------------------------------------------
# ----------------------------- Main -----------------------------
# ----------------------------------------------------------------
case "$1" in
  "")      select_destination      ;;
  add)     add_destination "$2"    ;;
  rm)      remove_destination "$2" ;;
  list)    list_destinations       ;;
  --help)  show_help               ;;
  *)       invalid_command         ;;
esac
