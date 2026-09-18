function ga --description "Quick git add"
    if test -z "$argv[1]"
        git add .
    else
        git add $argv
    end
end
