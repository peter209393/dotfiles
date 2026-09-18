function untar --description "Extract tar archive automatically"
    if test -z "$argv[1]"
        echo "Usage: untar <archive.tar.gz> or <archive.tar.bz2>"
        return 1
    end
    if not test -e "$argv[1]"
        echo "Error: File '$argv[1]' does not exist"
        return 1
    end

    switch $argv[1]
        case "*.tar.gz" "*.tgz"
            tar -xzf $argv[1]
        case "*.tar.bz2" "*.tbz2"
            tar -xjf $argv[1]
        case "*.tar.xz" "*.txz"
            tar -xJf $argv[1]
        case "*.tar"
            tar -xf $argv[1]
        case '*'
            echo "Error: Unsupported archive format"
            return 1
    end

    echo "Extracted '$argv[1]'"
end
