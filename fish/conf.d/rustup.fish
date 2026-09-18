if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end

if test (uname -s) = Darwin -a -d /opt/homebrew/opt/rustup/bin
    fish_add_path /opt/homebrew/opt/rustup/bin
end
