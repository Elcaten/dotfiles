status is-interactive; or return

abbr -a g 'git'

# eza
abbr -a ls    'eza --icons=auto'                      # List entries with icons
abbr -a l     'eza -1 --icons=auto'                   # List one entry per line
abbr -a ll    'eza -lah --icons=auto --git'           # Detailed list with hidden files and Git status
abbr -a la    'eza -a --icons=auto'                   # List all entries, including hidden files
abbr -a lt    'eza --tree --level=2 --icons=auto'     # Display a directory tree two levels deep
abbr -a lta   'eza --tree --level=2 -a --icons=auto'  # Display a tree including hidden files
abbr -a ld    'eza -lD --icons=auto'                  # List directories only
abbr -a lf    'eza -lf --icons=auto'                  # List files only
abbr -a lnew  'eza -lah --sort=modified'              # Sort by modification time, newest first
abbr -a lsize 'eza -lah --sort=size'                  # Sort by size, largest first

# tmux
abbr --add tn  'tmux new-session -s'
abbr --add ta  'tmux attach-session -t'
abbr --add tl  'tmux list-sessions'
abbr --add tk  'tmux kill-session -t'
abbr --add tr  'tmux rename-session'
abbr --add td  'tmux detach-client'
