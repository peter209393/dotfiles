function mkcd --description "Create directory and enter it"
    if test -z "$argv[1]"
        echo "Usage: mkcd <directory_name>"
        return 1
    end
    mkdir -p $argv[1] && cd $argv[1]
end
