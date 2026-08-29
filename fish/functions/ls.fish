function ls
    if type -q eza
        command eza -F $argv
    else
        command ls -F $argv
    end
end

function la
    ls -la $argv
end

function ll
    ls -la $argv
end
