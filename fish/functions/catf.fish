function catf --description "View file with bat syntax highlighting"
    if test -z "$argv[1]"
        echo "Usage: catf <file>"
        return 1
    end
    if command -q bat
        bat $argv
    else
        cat $argv
        echo "Note: Install 'bat' for syntax highlighting"
    end
end
