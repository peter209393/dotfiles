# Fish Shell 配置文件 - Vim 风格键绑定
# ============================================
# 光标移动（类似 Neovim）
# ============================================

# Ctrl+F: 向前移动一个字符（forward char）
bind \cf forward-char

# Ctrl+B: 向后移动一个字符（backward char）
bind \cb backward-char

# Ctrl+A: 移动到行首（与默认一致）
bind \ca beginning-of-line

# Ctrl+E: 移动到行尾（与默认一致）
bind \ce end-of-line

# Alt+F: 向前移动一个单词
bind \ef forward-word

# Alt+B: 向后移动一个单词
bind \eb backward-word

# Ctrl+P: 上一条命令（previous）
bind \cp up-or-search

# Ctrl+N: 下一条命令（next）
bind \cn down-or-search

# ============================================
# 删除操作
# ============================================

# Alt+D: 删除光标后的一个单词
bind \ed kill-word

# Alt+Backspace: 删除光标前的一个单词
bind \e\x7f backward-kill-word

# Ctrl+H: 删除光标前的一个字符（等同于 Backspace）
bind \ch backward-delete-char

# Ctrl+W: 删除光标前的一个单词
bind \cw backward-kill-word

# Ctrl+K: 删除光标到行尾
bind \ck kill-line

# Ctrl+U: 删除光标到行首
bind \cu backward-kill-line

# Alt+K: 删除光标到行尾（备用）
bind \ek kill-whole-line

# ============================================
# 其他有用的快捷键
# ============================================

# Ctrl+L: 清屏
bind \cl clear

# Ctrl+R: 搜索历史（默认已有，这里明确定义）
bind \cr history-pager

# Alt+.: 插入上一个命令的最后一个参数
bind \e. history-token-search-backward

# Ctrl+T: 交换光标前的两个字符
bind \ct transpose-chars

# Alt+T: 交换光标前的两个单词
bind \et transpose-words

# Ctrl+/: 撤销（undo）
bind \c_ undo

# Alt+R: 重做（redo）
bind \er redo

# ============================================
# 禁用 Ctrl+D 直接退出（需要空行时才退出）
# ============================================

# 创建自定义函数来处理 Ctrl+D
function delete-or-exit-safe
    # 如果命令行不为空，删除一个字符
    # 如果命令行为空，什么都不做（或者可以退出）
    if test -n (commandline)
        commandline -f delete-char
    else
        # 如果想要在空行时退出，取消下面的注释
        # exit
        # 如果不想退出，什么都不做
        echo ""
    end
end

# 绑定 Ctrl+D 到自定义函数
bind \cd delete-or-exit-safe

