if status is-interactive
    abbr --add tn  'tmux new-session -s'
    abbr --add ta  'tmux attach-session -t'
    abbr --add tl  'tmux list-sessions'
    abbr --add tk  'tmux kill-session -t'
    abbr --add tr  'tmux rename-session'
    abbr --add td  'tmux detach-client'
end
