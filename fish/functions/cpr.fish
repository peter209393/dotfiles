function cpr --description "Copy current path to clipboard"
    if command -q wl-copy
        pwd | wl-copy
        echo "Path copied to clipboard (wl-copy)"
    else if command -q xclip
        pwd | xclip -selection clipboard
        echo "Path copied to clipboard (xclip)"
    else if command -q pbcopy
        pwd | pbcopy
        echo "Path copied to clipboard (pbcopy)"
    else
        echo "No clipboard tool found (wl-copy, xclip, or pbcopy)"
        echo "Current path: "(pwd)
        return 1
    end
end
