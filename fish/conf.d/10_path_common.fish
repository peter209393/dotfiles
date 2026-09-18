# 通用 PATH(两个平台都需要)
if status is-login
    fish_add_path -a -g "$HOME/.local/bin"
    fish_add_path -a -g "$HOME/bin"
    fish_add_path -a -g "$HOME/.cargo/bin"
end
