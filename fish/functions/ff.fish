function ff --description "Quick file finder using fzf"
    if command -q fzf
        fzf --preview 'bat --color=always {} 2>/dev/null || head -100 {}' | read -l file
        if test -n "$file"
            nvim "$file"
        end
    else
        echo "fzf is not installed"
        return 1
    end
end
