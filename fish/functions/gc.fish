function gc --description "Quick git commit"
    if test -z "$argv[1]"
        echo "Usage: gc \"commit message\""
        return 1
    end
    git commit -m "$argv"
end
