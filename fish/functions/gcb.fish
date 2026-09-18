function gcb --description "Create and checkout new git branch"
    if test -z "$argv[1]"
        echo "Usage: gcb <branch_name>"
        return 1
    end
    git checkout -b $argv[1]
end
