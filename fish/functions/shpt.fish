function shpt
    if test (count $argv) -eq 0
        echo "Usage: shpt <request>" >&2
        return 2
    end

    set -l request (string join ' ' -- $argv)
    set -l command (llm \
        -m claude-haiku-4.5 \
        --no-stream \
        --no-log \
        --system "Translate the user request into exactly one valid Fish-compatible Linux command. Output one line only, with no Markdown, comments, or explanation. Prefer the simplest non-destructive command." \
        "$request")
    or return $status

    if test (count $command) -ne 1
        echo "The model did not return exactly one command." >&2
        return 1
    end

    output-to-prompt "$command"
end
