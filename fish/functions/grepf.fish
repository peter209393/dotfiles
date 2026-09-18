function grepf --description "Fuzzy search file content"
    if test -z "$argv[1]"
        echo "Usage: grepf <search_term>"
        return 1
    end

    if command -q fzf
        grep -r -n "$argv[1]" . 2>/dev/null | fzf | read -l match
        if test -n "$match"
            set -l file (echo $match | cut -d: -f1)
            set -l line (echo $match | cut -d: -f2)
            if test -n "$file"
                nvim "+$line" "$file"
            end
        end
    else
        echo "fzf is not installed"
        return 1
    end
end
