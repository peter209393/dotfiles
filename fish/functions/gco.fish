function gco --description "Checkout git branch"
    if test -z "$argv[1]"
        git checkout -
    else
        git checkout $argv[1]
    end
end
