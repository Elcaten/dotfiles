status is-interactive; or return

if type -q fzf
    fzf --fish | source
end

if type -q zoxide
    zoxide init fish | source
end
