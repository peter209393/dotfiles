if test -z "$XDG_DATA_HOME"
    set -g Z_DATA_DIR "$HOME/.local/share/z"
else
    set -g Z_DATA_DIR "$XDG_DATA_HOME/z"
end
set -g Z_DATA "$Z_DATA_DIR/data"
set -g Z_EXCLUDE "^$HOME\$"

set -eU Z_DATA
set -eU Z_DATA_DIR
set -eU Z_EXCLUDE

if test ! -e "$Z_DATA"
    mkdir -p -m 700 "$Z_DATA_DIR"
    touch "$Z_DATA"
end

if test -z "$Z_CMD"
    set -U Z_CMD z
end

set -U ZO_CMD "$Z_CMD"o

if test ! -z $Z_CMD
    function $Z_CMD -d "jump around"
        __z $argv
    end
end

if test ! -z $ZO_CMD
    function $ZO_CMD -d "open target dir"
        __z -d $argv
    end
end

# Setup completions once first
__z_complete

function __z_on_variable_pwd --on-variable PWD
    __z_add
end

function __z_uninstall --on-event z_uninstall
    functions -e __z_on_variable_pwd
    functions -e $Z_CMD
    functions -e $ZO_CMD

    if test ! -z "$Z_DATA"
        printf "To completely erase z's data, remove:\n" >/dev/stderr
        printf "%s\n" "$Z_DATA" >/dev/stderr
    end

    set -e Z_CMD
    set -e ZO_CMD
    set -e Z_DATA
    set -e Z_EXCLUDE
end
