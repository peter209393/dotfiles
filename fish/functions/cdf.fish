function cdf --description "Fuzzy search and change directory"
    if command -q fzf
        find . -type d -not -path '*/\.*' 2>/dev/null | fzf | read -l dir
        if test -n "$dir"
            cd $dir
        end
    else
        echo "fzf is not installed"
        return 1
    end
end
