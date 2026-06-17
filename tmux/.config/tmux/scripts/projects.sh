#!/usr/bin/env bash

# Liste tes projets ici (ou parcours automatiquement ~/Projects/*)
projects=(
  "$HOME/Projects/mailgrip"
  "$HOME/Projects/alexplescan.com"
  "$HOME/Projects/wezterm_love_letters"
)

# Sélection du projet via fzf
project=$(printf '%s\n' "${projects[@]}" | fzf --prompt="Select project > ")

# Si rien sélectionné, on quitte
[[ -z "$project" ]] && exit 0

# Nom de session basé sur le dossier
session_name=$(basename "$project")

# Vérifie si la session existe déjà
if ! tmux has-session -t "$session_name" 2>/dev/null; then
  # Crée la session dans le dossier choisi
  tmux new-session -ds "$session_name" -c "$project"

  # Exemple : lancer des splits ou commandes personnalisées
  # tmux send-keys -t "$session_name" 'nvim .' C-m
  # tmux split-window -h -t "$session_name" -c "$project"
fi

# Attache à la session
tmux switch-client -t "$session_name" || tmux attach -t "$session_name"
