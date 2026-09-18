# 由 install.sh 生成,可自由编辑
# 代理(取消注释启用)
# set -gx http_proxy http://127.0.0.1:7897
# set -gx https_proxy http://127.0.0.1:7897
# set -gx all_proxy socks5://127.0.0.1:7897

# 中文输入法(Linux)
if test (uname -s) = Linux
    set -gx QT_IM_MODULE fcitx
    set -gx XMODIFIERS @im=fcitx
    set -gx SDL_IM_MODULE fcitx
    set -gx GLFW_IM_MODULE ibus
end
