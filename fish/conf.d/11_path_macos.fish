# ===== macOS 专用 =====
# 触发条件:uname -s = Darwin
# 内容:Homebrew(arm64)、Java(用户目录解压版)、Android SDK、Flutter
if status is-login
    and test (uname -s) = Darwin

    set arch (uname -m)
    if test $arch = arm64
        # Apple Silicon Homebrew
        fish_add_path -a -g "/opt/homebrew/bin/"
    else
        # Intel Mac
        fish_add_path -a -g "/usr/local/bin/"
    end

    # Flutter
    if test -d "$HOME/works/flutter/flutter-bin/bin"
        fish_add_path -a -g "$HOME/works/flutter/flutter-bin/bin/"
    end

    # ===== Java (Temurin 17,用户目录解压) =====
    set _java_home "$HOME/Library/Java/jdk-17.0.13+11/Contents/Home"
    if test -d "$_java_home"
        set -gx JAVA_HOME "$_java_home"
        fish_add_path -a -g "$JAVA_HOME/bin"
    end
    set --erase _java_home

    # ===== Android SDK =====
    set _android_home "$HOME/Library/Android/sdk"
    if test -d "$_android_home"
        set -gx ANDROID_HOME "$_android_home"
        set -gx ANDROID_SDK_ROOT "$_android_home"
        fish_add_path -a -g "$ANDROID_HOME/platform-tools"
        fish_add_path -a -g "$ANDROID_HOME/cmdline-tools/latest/bin"
        fish_add_path -a -g "$ANDROID_HOME/emulator"
        if test -d "$ANDROID_HOME/build-tools"
            # 把最新的 build-tools 加到 PATH
            for d in $ANDROID_HOME/build-tools/*
                fish_add_path -a -g "$d"
            end
        end
    end
    set --erase _android_home
end
