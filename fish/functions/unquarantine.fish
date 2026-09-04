function unquarantine --description 'Remove macOS quarantine attribute'
    if test (count $argv) -eq 0
        echo "Usage: unquarantine <file-or-app> [...]"
        return 1
    end

    xattr -dr com.apple.quarantine $argv
end
