function fordrunrpc --description "Manage fordrun RPC URLs (global + project-aware)"

    # ---------- paths ----------
    function __rpc_dir;  echo "$HOME/.config/fordrun-rpc"; end
    function __rpc_list; echo (__rpc_dir)/urls; end
    function __rpc_cur;  echo (__rpc_dir)/current; end

    function __project_file
        echo ".fordrunrpc"
    end

    # ---------- init ----------
    function __init
        mkdir -p (__rpc_dir)

        if not test -f (__rpc_list)
            printf "%s\n" \
                "local=http://127.0.0.1:8545" \
                "dev=http://127.0.0.1:9545" \
                > (__rpc_list)
        end

        if not test -f (__rpc_cur)
            echo "" > (__rpc_cur)
        end
    end

    # ---------- helpers ----------
    function __pairs
        cat (__rpc_list) 2>/dev/null | while read -l line
            string match -qr '^[^=]+=.+$' -- "$line"; or continue
            set -l p (string split -m1 "=" -- "$line")
            printf "%s\t%s\n" $p[1] $p[2]
        end
    end

    function __resolve --argument-names key
        # key can be name or url
        if string match -qr '^(https?|wss?)://' -- "$key"
            echo "$key"
            return
        end

        __pairs | while read -l n u
            if test "$n" = "$key"
                echo "$u"
                return
            end
        end
    end

    function __sync_configs --argument-names url
        # .env
        if test -f .env
            if grep -q '^FORDRUN_RPC_URL=' .env
                sed -i '' "s|^FORDRUN_RPC_URL=.*|FORDRUN_RPC_URL=$url|" .env 2>/dev/null \
                or sed -i "s|^FORDRUN_RPC_URL=.*|FORDRUN_RPC_URL=$url|" .env
            else
                echo "FORDRUN_RPC_URL=$url" >> .env
            end
            echo "🔄 synced .env"
        end

        # foundry.toml
        if test -f foundry.toml
            if grep -q '^rpc_url' foundry.toml
                sed -i '' "s|^rpc_url *=.*|rpc_url = \"$url\"|" foundry.toml 2>/dev/null \
                or sed -i "s|^rpc_url *=.*|rpc_url = \"$url\"|" foundry.toml
            end
            echo "🔄 synced foundry.toml"
        end

        # fordrun.toml
        if test -f fordrun.toml
            if grep -q '^rpc_url' fordrun.toml
                sed -i '' "s|^rpc_url *=.*|rpc_url = \"$url\"|" fordrun.toml 2>/dev/null \
                or sed -i "s|^rpc_url *=.*|rpc_url = \"$url\"|" fordrun.toml
            end
            echo "🔄 synced fordrun.toml"
        end
    end

    function __set_current --argument-names url sync
        echo -n "$url" > (__rpc_cur)
        set -Ux FORDRUN_RPC_URL "$url"
        echo "✅ FORDRUN_RPC_URL -> $url"

        if test "$sync" = "yes"
            __sync_configs "$url"
        end
    end

    __init

    set -l cmd $argv[1]

    switch "$cmd"
        case ls
            set -l cur (cat (__rpc_cur))
            __pairs | while read -l n u
                if test "$u" = "$cur"
                    printf "* %-12s %s\n" $n $u
                else
                    printf "  %-12s %s\n" $n $u
                end
            end

        case cur
            cat (__rpc_cur)

        case add
            set -l name $argv[2]
            set -l url  $argv[3]
            test -z "$name"; or test -z "$url"; and return 1

            set -l tmp (mktemp)
            __pairs | while read -l n u
                test "$n" != "$name"; and echo "$n=$u"
            end > "$tmp"
            echo "$name=$url" >> "$tmp"
            mv "$tmp" (__rpc_list)
            echo "✅ added $name"

        case use
            set -l key $argv[2]
            set -l url (__resolve "$key")

            if test -z "$url"
                echo "❌ not found: $key"
                return 1
            end

            __set_current "$url" yes

        case bind
            # bind current project
            set -l key $argv[2]
            test -z "$key"; and echo "usage: fordrunrpc bind <name|url>"; and return 1
            echo "$key" > (__project_file)
            echo "📌 bound project to $key"

        case unbind
            rm -f (__project_file)
            echo "📎 project unbound"

        case '*'
            echo "usage:"
            echo "  fordrunrpc ls"
            echo "  fordrunrpc use <name|url>"
            echo "  fordrunrpc bind <name|url>"
            echo "  fordrunrpc unbind"
    end
end

