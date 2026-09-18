function _crush_query --description "Ask Crush a quick question with -q flag"
    # crush 仅 macOS 经 Homebrew 安装,缺失时给出清晰提示而非 command not found
    if not command -q crush
        echo "crush 未安装(仅 macOS: brew install charmbracelet/tap/crush)" >&2
        return 127
    end
    if test -z "$argv[1]"
        echo "Usage: ? <question>"
        return 1
    end
    crush run "$argv" -q
end
