#!/bin/bash
tmux new-session -d 'Sylius'
tmux new-window 'neovim'
tmux new-window 'php'
tmux new-window 'git'
#tmux -2 attach-session -d
