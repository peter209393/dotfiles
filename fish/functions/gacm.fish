function gacm --description "Git add, commit and push in one command"
    if test -z "$argv[1]"
        echo "Usage: gacm \"commit message\""
        return 1
    end
    git add .
    git commit -m "$argv"
    git push
end
