# 平台检测:macOS vs Linux
# 用 uname -s 判断,字符串赋值以便后面复用
set _os_name (uname -s)
set _is_macos (test "$_os_name" = Darwin; echo $status)
set _is_linux (test "$_os_name" = Linux; echo $status)
