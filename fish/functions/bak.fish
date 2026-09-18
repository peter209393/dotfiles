function bak --description "Backup file with .bak extension"
    if test -z "$argv[1]"
        echo "Usage: bak <file>"
        return 1
    end
    if not test -e "$argv[1]"
        echo "Error: File '$argv[1]' does not exist"
        return 1
    end
    cp "$argv[1]" "$argv[1].bak"
    echo "Backed up '$argv[1]' to '$argv[1].bak'"
end
