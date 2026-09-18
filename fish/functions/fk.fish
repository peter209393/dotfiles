function fk --description "Quick kill process using fzf"
    if command -q fzf
        ps aux | fzf | awk '{print $2}' | read -l pid
        if test -n "$pid"
            kill -9 $pid
            echo "Killed process: $pid"
        end
    else
        echo "fzf is not installed"
        return 1
    end
end
