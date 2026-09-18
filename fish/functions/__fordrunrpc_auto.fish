function __fordrunrpc_auto --on-variable PWD
    set -l file ".fordrunrpc"
    if test -f "$file"
        set -l key (cat "$file")
        if test -n "$key"
            fordrunrpc use "$key" >/dev/null 2>&1
        end
    end
end

