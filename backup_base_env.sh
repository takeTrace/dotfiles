#!/usr/bin/env bash

source ~/.zshrc
# backup base env
# 备份基础环境. 有些低配电脑不配运行太多程序.
# 但是需要最基础的环境来符合自己的使用习惯,
# 这时候也不适合使用 mackup 恢复,
# 因为mackup 备份的东西太多.
basedir="./BaseEnvFiles/"

# iina key bindings: iina 的快捷键
cp '~/.dotfiles/mackup/Library/Application\ Support/com.colliderli.iina/input_conf/IINA\ cp1.conf' "$basedir"
# iterm2 profile
cp  '~/.dotfiles/mackup/Backup/Preferences/iTerm2/cusTakeTrace.json' "$basedir"





