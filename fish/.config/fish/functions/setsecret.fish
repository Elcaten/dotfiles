function setsecret
    set -l name $argv[1]

    if test -z "$name"
        read --prompt-str 'Variable name: ' name
    end

    read --silent --prompt-str 'Variable value: ' value
    set --global --export $name $value
    set --erase value
end
