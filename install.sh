#!/usr/bin/env bash

###########################
# This script  runs all other system configuration scripts
# @author takeTrace
# @Email takeTrace00@gmail.com
# originalRepo: see README.md
# description: configure my mac & learn shell(at least boot up install new mac & backup) from this repo, thx a lot. think to @Adam Eivy's dotFiles: https://github.com/atomantic/dotfiles
###########################

# 引进 helper 便捷函数
source ./lib_sh/echos.sh
source ./lib_sh/requirers.sh

bot " 即将安装工具, 配置系统设置..."

# 请求 sudo 权限
grep -q 'NOPASSWD:     ALL' /etc/sudoers.d/$LOGNAME > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "no suder file  没有 suder 文件"
  sudo -v

  # Keep-alive: update existing sudo time stamp until the script has finished
  # 保持权限知道脚本结束
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

bot "--------------------------------- 重写 hosts ---------------------------------"
# /etc/hosts
# ###########################################################
# /etc/hosts -- spyware/ad blocking
# ###########################################################
action "cp /etc/hosts /etc/hosts.backup"
sudo cp /etc/hosts /etc/hosts.backup
ok
action "cp ./configs/hosts /etc/hosts"
sudo cp ./configs/hosts /etc/hosts
ok
# bot "Your /etc/hosts file has been updated. Last version is saved in /etc/hosts.backup"
bot "你的 /etc/hosts 文件已经跟新, 原文件已经备份到/etc/hosts.backup"


bot "--------------------------------- Git Config ---------------------------------"


# ###########################################################
# Git Config
# ###########################################################
bot "OK, 现在根据你的信息更新 .gitconfig 文件: "
grep 'user = takeTrace' ~/.gitconfig > /dev/null 2>&1
if [[ $? = 0 ]]; then
    read -r -p "What is your git username? " githubuser

  fullname=`osascript -e "long user name of (system info)"`

  if [[ -n "$fullname" ]];then
    lastname=$(echo $fullname | awk '{print $2}');
    firstname=$(echo $fullname | awk '{print $1}');
  fi

  if [[ -z $lastname ]]; then
    lastname=`dscl . -read /Users/$(whoami) | grep LastName | sed "s/LastName: //"`
  fi
  if [[ -z $firstname ]]; then
    firstname=`dscl . -read /Users/$(whoami) | grep FirstName | sed "s/FirstName: //"`
  fi
  email=`dscl . -read /Users/$(whoami)  | grep EMailAddress | sed "s/EMailAddress: //"`

  if [[ ! "$firstname" ]]; then
    response='n'
  else
    echo -e "I see that your full name is $COL_YELLOW$firstname $lastname$COL_RESET"
    read -r -p "Is this correct? [Y|n] " response
  fi

  if [[ $response =~ ^(no|n|N) ]]; then
    read -r -p "What is your first name? " firstname
    read -r -p "What is your last name? " lastname
  fi
  fullname="$firstname $lastname"

  bot "Great $fullname, "

  if [[ ! $email ]]; then
    response='n'
  else
    echo -e "The best I can make out, your email address is $COL_YELLOW$email$COL_RESET"
    read -r -p "Is this correct? [Y|n] " response
  fi

  if [[ $response =~ ^(no|n|N) ]]; then
    read -r -p "What is your email? " email
    if [[ ! $email ]];then
      error "you must provide an email to configure .gitconfig"
      exit 1
    fi
  fi


  running "replacing items in .gitconfig with your info ($COL_YELLOW$fullname, $email, $githubuser$COL_RESET)"

  # test if gnu-sed or MacOS sed

  sed -i "s/GITHUBFULLNAME/$firstname $lastname/" ./homedir/.gitconfig > /dev/null 2>&1 | true
  if [[ ${PIPESTATUS[0]} != 0 ]]; then
    echo
    running "looks like you are using MacOS sed rather than gnu-sed, accommodating"
    sed -i '' "s/GITHUBFULLNAME/$firstname $lastname/" ./homedir/.gitconfig
    sed -i '' 's/GITHUBEMAIL/'$email'/' ./homedir/.gitconfig
    sed -i '' 's/GITHUBUSER/'$githubuser'/' ./homedir/.gitconfig
    ok
  else
    echo
    bot "looks like you are already using gnu-sed. woot!"
    sed -i 's/GITHUBEMAIL/'$email'/' ./homedir/.gitconfig
    sed -i 's/GITHUBUSER/'$githubuser'/' ./homedir/.gitconfig
  fi
fi

# -------------------------- 配置 SSR 翻墙 -------------------------------
bot "现在来配置翻墙先..."
if [ ! -d "/Applications/ShadowsocksX-NG-R.app" ]; then
bot "复制 ShadowsocksX-NG-R -> Applications"
  unzip ./AppsForInitialMacOS/ShadowsocksX-NG-R.zip
  mv ShadowsocksX-NG-R.app /AppsForInitialMac
  sudo mv ShadowsocksX-NG-R.app /Applications/ShadowsocksX-NG-R.app;
  ok
  bot "打开 SSR 进行配置, 请手动打开App 配置"
  open /Applications
else
  running "打开 ss 配置翻墙? 请手动打开App 配置"
  open /Applications
fi
bot "打开订阅地址, 复制下面的地址到 SSR 中更新服务器并打开代理, 或者自行导入能用的 json 配置";
cat ./AppsForInitialMacOS/ssrSubscribe.private
read -r -p "完成了就直接回车" response

# -------------------------- 配置请求转发到代理端口 --------------------------
# 经由 ssr:1086 转发请求来翻墙, 可以加快 brew 的安装和下载. (brew 会使用ALL_PROXY走代理)
echo "export ALL_PROXY=socks5://127.0.0.1:1086"
export ALL_PROXY=socks5://127.0.0.1:1086
echo "ALL_PROXY=: $ALL_PROXY"
read -r -p "是否配置了? " response


# ###########################################################
# Install non-brew various tools (PRE-BREW Installs)
# 安装 Xcode CLT 工具
# ###########################################################

bot "ensuring build/install tools are available"
if ! xcode-select --print-path &> /dev/null; then

    # Prompt user to install the XCode Command Line Tools
    xcode-select --install &> /dev/null

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Wait until the XCode Command Line Tools are installed
    until xcode-select --print-path &> /dev/null; do
        sleep 5
    done

    print_result $? ' XCode Command Line Tools Installed'

    # Prompt user to agree to the terms of the Xcode license
    # https://github.com/alrra/dotfiles/issues/10

    sudo xcodebuild -license
    print_result $? 'Agree with the XCode Command Line Tools licence'
    ok;
fi

#####
# ------------------------------ install homebrew (CLI Packages) ------------------------------
#####

running "checking homebrew..."
brew_bin=$(which brew) 2>&1 > /dev/null
if [[ $? != 0 ]]; then
  action "installing homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    if [[ $? != 0 ]]; then
      error "unable to install homebrew, script $0 abort!"
      exit 2
    fi
    brew analytics off
  ok
else
  bot "Homebrew"
  read -r -p "run brew update && upgrade? [y|N] " response
  if [[ $response =~ (y|yes|Y) ]]; then
    action "updating homebrew..."
    brew update
    ok "homebrew updated"
    action "upgrading brew packages..."
    brew upgrade
    ok "brews upgraded"
  else
    ok "skipped brew package upgrades."
  fi
fi

bot "export PATH=/usr/local/sbin:$PATH";
export PATH="/usr/local/sbin:$PATH";
if [ $? != 0 ]; then
  exit $?
fi

HOMEBREW_NO_AUTO_UPDATE=1
echo "HOMEBREW_NO_AUTO_UPDATE = $HOMEBREW_NO_AUTO_UPDATE"
read -r -p "以上配置是否正确? " response


# Just to avoid a potential bug
mkdir -p ~/Library/Caches/Homebrew/Formula
brew doctor


# -------------------------------- 终端翻墙 --------------------------------
privoxy_bin=$(which privoxy) 2>&1 > /dev/null
if [[ $? != 0 ]]; then
  action "安装 privoxy 代理"
  require_brew privoxy
  if [ $? != 0 ]; then
    exit $?
  fi
  ok
  bot "写入配置"
  echo "listen-address 0.0.0.0:8118" >> /usr/local/etc/privoxy/config
  if [ $? != 0 ]; then
    exit $?
  fi
  echo "forward-socks5 / localhost:1086 ." >> /usr/local/etc/privoxy/config
  if [ $? != 0 ]; then
    exit $?
  fi
else
  bot "已经安装过 privoxy 代理,  复制配置"
  sudo cp ./privoxy_config /usr/local/etc/privoxy/config
  if [ $? != 0 ]; then
    exit $?
  fi
  ok
  bot "privoxy/config.js tail -10: "
  sudo tail -5 /usr/local/etc/privoxy/config
fi
read -r -p "配置是否写入? " response

running "config privoxy..."
bot "export no_proxy=localhost,127.0.0.1,localaddress,.localdomain.com"
export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com";
bot "export http_proxy=http://127.0.0.1:8118";
export http_proxy="http://127.0.0.1:8118";
bot "export https_proxy=$http_proxy";
export https_proxy=$http_proxy;
echo -e "已配置代理";
ok
running "start server..."
# sudo /usr/local/sbin/privoxy /usr/local/etc/privoxy/config
sudo brew services start privoxy
#  通过统一使终端翻墙后, 不再需要单独在 gitconfig 里配置代理. GUI 上也有小飞机翻墙了.
# git config --global http.proxy socks5://127.0.0.1:1086
# git config --global http.https://github.com.proxy socks5://127.0.0.1:1086
ok
echo "$(netstat -na | grep 8118)"
echo "$(ps -ef | grep privoxy)"
read -r -p "已开启代理, 代理端口是否可见" response
ok

# ------------------------------ 配置 bash, 安装 git/zsh/ruby ------------------------------
bot "config bash"
# 配置 bash 颜色, exports, alias, functions,  等终端快捷行为
running "config bash in bashconfig dir..."
./bashconfig/bootstrap.sh
ok

# skip those GUI clients, git command-line all the way
running "Intall Git..."
require_brew git
# update zsh to latest
running "Intall Zsh..."
require_brew zsh
ok

# update ruby to latest
bot "use versions of packages installed with homebrew"
RUBY_CONFIGURE_OPTS="--with-openssl-dir=`brew --prefix openssl` --with-readline-dir=`brew --prefix readline` --with-libyaml-dir=`brew --prefix libyaml`"
running "Intall Ruby..."
require_brew ruby
ok

bot "set zsh as the user login shell"
CURRENTSHELL=$(dscl . -read /Users/$USER UserShell | awk '{print $2}')
ok

if [[ "$CURRENTSHELL" != "/usr/local/bin/zsh" ]]; then
  bot "setting newer homebrew zsh (/usr/local/bin/zsh) as your shell (password required)"
  # sudo bash -c 'echo "/usr/local/bin/zsh" >> /etc/shells'
  # chsh -s /usr/local/bin/zsh
  sudo dscl . -change /Users/$USER UserShell $SHELL /usr/local/bin/zsh > /dev/null 2>&1
  ok
fi

bot "VIM Setup"
read -r -p "Do you want to install vim plugins now? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  bot "Installing vim plugins"
  # cmake is required to compile vim bundle YouCompleteMe
  # require_brew cmake
  vim +PluginInstall +qall > /dev/null 2>&1
  ok
else
  ok "skipped. Install by running :PluginInstall within vim"
fi

# node version manager
require_brew nvm

# nvm
require_nvm stable

#####################################
# Now we can switch to node.js mode
# for better maintainability and
# easier configuration via
# JSON files and inquirer prompts
#####################################

bot "installing npm tools needed to run this project..."
npm install
ok

bot "installing packages from config.js..."
node index.js
ok

#  上面的脚本里设置了必须装的, brewfile 不一定适合每个机器, 有些东西在配置低的机器不适合装
# bot "Now checking Brewfile for brew install..."

running "cleanup homebrew"
brew cleanup --force > /dev/null 2>&1
rm -f -r /Library/Caches/Homebrew/* > /dev/null 2>&1
ok

bot "OS Configuration"
read -r -p "Do you want to update the system configurations? [y|N] " response
if [[ -z $response || $response =~ ^(n|N) ]]; then
  open /Applications/iTerm.app
  bot "All done"
  exit
fi

###############################################################################
bot "Configuring General System UI/UX..."
###############################################################################
# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
running "closing any system preferences to prevent issues with automated changes"
osascript -e 'tell application "System Preferences" to quit'
ok

##############################################################################
# Security                                                                   #
##############################################################################
# Based on:
# https://github.com/drduh/macOS-Security-and-Privacy-Guide
# https://benchmarks.cisecurity.org/tools2/osx/CIS_Apple_OSX_10.12_Benchmark_v1.0.0.pdf

# Enable firewall. Possible values:
#   0 = off
#   1 = on for specific sevices
#   2 = on for essential services
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1

# 防火墙
# Enable firewall stealth mode (no response to ICMP / ping requests)
# Source: https://support.apple.com/guide/mac-help/use-stealth-mode-to-keep-your-mac-more-secure-mh17133/mac
#sudo defaults write /Library/Preferences/com.apple.alf stealthenabled -int 1
sudo defaults write /Library/Preferences/com.apple.alf stealthenabled -int 1

# 禁用远程事件
# Disable remote apple events
sudo systemsetup -setremoteappleevents off

# 禁用远程登录
# Disable remote login
sudo systemsetup -setremotelogin off

#  禁用调制解调器唤醒设备
# Disable wake-on modem
sudo systemsetup -setwakeonmodem off

# 禁用 LAN 唤醒设备
# Disable wake-on LAN
sudo systemsetup -setwakeonnetworkaccess off

# 禁用客户账号登录
# Disable guest account login
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false

###############################################################################
# SSD-specific tweaks                                                         #
###############################################################################

# disablelocal is no longer used, check man tmutil for more info
# running "Disable local Time Machine snapshots"
# sudo tmutil disablelocal;ok

# running "Disable hibernation (speeds up entering sleep mode)"
# sudo pmset -a hibernatemode 0;ok

# running "Remove the sleep image file to save disk space"
# sudo rm -rf /Private/var/vm/sleepimage;ok
# running "Create a zero-byte file instead"
# sudo touch /Private/var/vm/sleepimage;ok
# running "…and make sure it can’t be rewritten"
# sudo chflags uchg /Private/var/vm/sleepimage;ok

################################################
# Optional / Experimental                      #
################################################

cpname="takeTrace"
# running "Set computer name (as done via System Preferences → Sharing)"
# sudo scutil --set ComputerName "$cpname"
# sudo scutil --set HostName "$cpname"
# sudo scutil --set LocalHostName "$cpname"
# sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$cpname"

running "Show icons for hard drives, servers, and removable media on the desktop"
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true;ok

running "Wipe all (default) app icons from the Dock(移除所有驻留 Dock 的 APP)"
# # This is only really useful when setting up a new Mac, or if you don’t use
# the Dock to launch apps.
defaults write com.apple.dock persistent-apps -array "";ok

################################################
bot "Standard System Changes"
################################################
# 开机以详细模式启动
# running "always boot in verbose mode (not MacOS GUI mode)"
# sudo nvram boot-args="-v";ok

# running "Set standby delay to 24 hours (default is 1 hour)"
# sudo pmset -a standbydelay 86400;ok

# 禁用开机音效
running "Disable the sound effects on boot"
sudo nvram SystemAudioVolume=" ";ok

# running "Menu bar: hide the Time Machine, Volume, User, and Bluetooth icons"
# for domain in ~/Library/Preferences/ByHost/com.apple.systemuiserver.*; do
#   defaults write "${domain}" dontAutoLoad -array \
#     "/System/Library/CoreServices/Menu Extras/TimeMachine.menu" \
#     "/System/Library/CoreServices/Menu Extras/Volume.menu" \
#     "/System/Library/CoreServices/Menu Extras/User.menu"
# done;
# defaults write com.apple.systemuiserver menuExtras -array \
#   "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" \
#   "/System/Library/CoreServices/Menu Extras/AirPort.menu" \
#   "/System/Library/CoreServices/Menu Extras/Battery.menu" \
#   "/System/Library/CoreServices/Menu Extras/Clock.menu"
# ok

# 设置边栏图标大小为中等
running "Set sidebar icon size to medium"
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2;ok

# 将保存选项设置为默认
running "Expand save panel by default"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true;ok

running "Expand print panel by default"
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true;ok

# 默认保存到磁盘(而非 iCloud)
running "Save to disk (not to iCloud) by default"
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false;ok

# 打印 job 完成后自动退出打印 APP
running "Automatically quit printer app once the print jobs complete"
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true;ok

running "Disable the “Are you sure you want to open this application?” dialog"
defaults write com.apple.LaunchServices LSQuarantine -bool false;ok

# https://github.com/atomantic/dotfiles/issues/30#issuecomment-514589462
#running "Remove duplicates in the “Open With” menu (also see 'lscleanup' alias)"
#/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user;ok

running "Display ASCII control characters using caret notation in standard text views"
# Try e.g. `cd /tmp; unidecode "\x{0000}" > cc.txt; open -e cc.txt`
defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true;ok

# running "Disable automatic termination of inactive apps"
# defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true;ok

running "Disable the crash reporter"
defaults write com.apple.CrashReporter DialogType -string "none";ok

# 在登录窗口点击时钟时显示IP, hostname, OS 等等
running "Reveal IP, hostname, OS, etc. when clicking clock in login window"
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName;ok

# running "Restart automatically if the computer freezes"
# sudo systemsetup -setrestartfreeze on;ok

# running "Never go into computer sleep mode"
# sudo systemsetup -setcomputersleep Off > /dev/null;ok

running "Check for software updates daily, not just once per week"
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1;ok

# running "Disable Notification Center and remove the menu bar icon"
# launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist > /dev/null 2>&1;ok

# 输入时禁用 智能dash 号
running "Disable smart dashes as they’re annoying when typing code"
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false;ok


###############################################################################
bot "Trackpad, mouse, keyboard, Bluetooth accessories, and input"
###############################################################################

# 触摸板: 登录面板和这个用户操作开启轻触点击
running "Trackpad: enable tap to click for this user and for the login screen"
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1;ok

# 增加蓝牙/耳机音质
running "Increase sound quality for Bluetooth headphones/headsets"
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40;ok

# 开启全键盘访问控制
running "Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)"
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3;ok

# 重复键入时禁止等待时间(加快按键速度)
running "Disable press-and-hold for keys in favor of key repeat"
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false;ok
# 加快重复按键速度
running "Set a blazingly fast keyboard repeat rate"
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 10;ok

running "Set language and text formats (english/US)"
defaults write NSGlobalDomain AppleLanguages -array "en"
defaults write NSGlobalDomain AppleLocale -string "en_US@currency=USD"
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults write NSGlobalDomain AppleMetricUnits -bool true;ok

running "Disable auto-correct"
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false;ok

###############################################################################
bot "Configuring the Screen"
###############################################################################

# 屏保后立即需要密码
running "Require password immediately after sleep or screen saver begins"
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0;ok

# 保存截图在桌面
running "Save screenshots to the desktop"
defaults write com.apple.screencapture location -string "${HOME}/Desktop";ok

# 保存截图为 png
running "Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)"
defaults write com.apple.screencapture type -string "png";ok

# 截图禁止阴影
running "Disable shadow in screenshots"
defaults write com.apple.screencapture disable-shadow -bool true;ok

running "Enable subpixel font rendering on non-Apple LCDs"
defaults write NSGlobalDomain AppleFontSmoothing -int 2;ok

running "Enable HiDPI display modes (requires restart)"
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true;ok

###############################################################################
bot "Finder Configs"
###############################################################################
running "Keep folders on top when sorting by name (Sierra only)"
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# running "Allow quitting via ⌘ + Q; doing so will also hide desktop icons"
# defaults write com.apple.finder QuitMenuItem -bool true;ok

running "Disable window animations and Get Info animations"
defaults write com.apple.finder DisableAllAnimations -bool true;ok

running "Set Downloads as the default location for new Finder windows"
# For other paths, use 'PfLo' and 'file:///full/path/here/'
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/";ok

running "Show hidden files by default"
defaults write com.apple.finder AppleShowAllFiles -bool true;ok

running "Show all filename extensions"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true;ok

running "Show status bar"
defaults write com.apple.finder ShowStatusBar -bool true;ok

running "Show path bar"
defaults write com.apple.finder ShowPathbar -bool true;ok

running "Allow text selection in Quick Look"
defaults write com.apple.finder QLEnableTextSelection -bool true;ok

running "Display full POSIX path as Finder window title"
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true;ok

running "When performing a search, search the current folder by default"
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf";ok

running "Disable the warning when changing a file extension"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false;ok

running "Enable spring loading for directories"
defaults write NSGlobalDomain com.apple.springing.enabled -bool true;ok

running "Remove the spring loading delay for directories"
defaults write NSGlobalDomain com.apple.springing.delay -float 0;ok

running "Avoid creating .DS_Store files on network volumes"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true;ok

running "Disable disk image verification"
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true;ok

running "Automatically open a new Finder window when a volume is mounted"
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true;ok

running "Use list view in all Finder windows by default"
# Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`
defaults write com.apple.finder FXPreferredViewStyle -string "clmv";ok

# running "Disable the warning before emptying the Trash"
# defaults write com.apple.finder WarnOnEmptyTrash -bool false;ok

running "Empty Trash securely by default"
defaults write com.apple.finder EmptyTrashSecurely -bool true;ok

running "Enable AirDrop over Ethernet and on unsupported Macs running Lion"
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true;ok

running "Expand the following File Info panes: “General”, “Open with”, and “Sharing & Permissions”"
defaults write com.apple.finder FXInfoPanesExpanded -dict \
  General -bool true \
  OpenWith -bool true \
  Privileges -bool true;ok

###############################################################################
bot "Dock & Dashboard"
###############################################################################

running "Set the icon size of Dock items to 36 pixels"
defaults write com.apple.dock tilesize -int 36;ok

running "Change minimize/maximize window effect to scale"
defaults write com.apple.dock mineffect -string "scale";ok

running "Minimize windows into their application’s icon"
defaults write com.apple.dock minimize-to-application -bool true;ok

running "Enable spring loading for all Dock items"
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true;ok

running "Show indicator lights for open applications in the Dock"
defaults write com.apple.dock show-process-indicators -bool true;ok

running "Don’t animate opening applications from the Dock"
defaults write com.apple.dock launchanim -bool false;ok

running "Speed up Mission Control animations"
defaults write com.apple.dock expose-animation-duration -float 0.1;ok

running "Disable Dashboard"
defaults write com.apple.dashboard mcx-disabled -bool true;ok

running "Don’t show Dashboard as a Space"
defaults write com.apple.dock dashboard-in-overlay -bool true;ok

running "Don’t automatically rearrange Spaces based on most recent use"
defaults write com.apple.dock mru-spaces -bool false;ok

running "Remove the auto-hiding Dock delay"
defaults write com.apple.dock autohide-delay -float 0;ok
running "Speed up the animation when hiding/showing the Dock"
defaults write com.apple.dock autohide-time-modifier -float 0.1;ok

running "Automatically hide and show the Dock"
defaults write com.apple.dock autohide -bool true;ok

running "Make Dock icons of hidden applications translucent"
defaults write com.apple.dock showhidden -bool true;ok

running "Make Dock more transparent"
defaults write com.apple.dock hide-mirror -bool true;ok

running "设置 LaunchPad 行/列/背景模糊度"
defaults write com.apple.dock springboard-columns -int 8;
defaults write com.apple.dock springboard-rows -int 7;
defaults write com.apple.dock ResetLaunchPad -bool TRUE;
defaults write com.apple.dock springboard-blur-radius -int 100;

running "Reset Launchpad, but keep the desktop wallpaper intact"
find "${HOME}/Library/Application Support/Dock" -name "*-*.db" -maxdepth 1 -delete;ok

bot "Configuring Hot Corners"
# Possible values:
#  0: no-op
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center

running "右下角 → 启动屏保"
defaults write com.apple.dock wvous-br-corner -int 5
defaults write com.apple.dock wvous-br-modifier -int 0;ok

###############################################################################
bot "Configuring Safari & WebKit"
###############################################################################

running "Set Safari’s home page to ‘about:blank’ for faster loading"
defaults write com.apple.Safari HomePage -string "about:blank";ok

running "Prevent Safari from opening ‘safe’ files automatically after downloading"
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false;ok

running "Enable Safari’s debug menu"
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true;ok

running "Make Safari’s search banners default to Contains instead of Starts With"
defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false;ok

running "Enable the Develop menu and the Web Inspector in Safari"
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true;ok

running "Add a context menu item for showing the Web Inspector in web views"
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true;ok

###############################################################################
bot "Configuring Mail"
###############################################################################


running "Disable send and reply animations in Mail.app"
defaults write com.apple.mail DisableReplyAnimations -bool true
defaults write com.apple.mail DisableSendAnimations -bool true;ok

running "Copy email addresses as 'foo@example.com' instead of 'Foo Bar <foo@example.com>' in Mail.app"
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false;ok

running "Add the keyboard shortcut ⌘ + Enter to send an email in Mail.app"
defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" -string "@\\U21a9";ok

###############################################################################
bot "Terminal & iTerm2"
###############################################################################

running "Only use UTF-8 in Terminal.app"
defaults write com.apple.terminal StringEncodings -array 4;ok

# running "Enable “focus follows mouse” for Terminal.app and all X11 apps"
# i.e. hover over a window and start `typing in it without clicking first
defaults write com.apple.terminal FocusFollowsMouse -bool true
#defaults write org.x.X11 wm_ffm -bool true;ok

###############################################################################
bot "Time Machine"
###############################################################################

running "Prevent Time Machine from prompting to use new hard drives as backup volume"
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true;ok

# running "Disable local Time Machine backups"
# hash tmutil &> /dev/null && sudo tmutil disablelocal;ok

###############################################################################
bot "Activity Monitor"
###############################################################################

running "Show the main window when launching Activity Monitor"
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true;ok

running "Visualize CPU usage in the Activity Monitor Dock icon"
defaults write com.apple.ActivityMonitor IconType -int 5;ok

# Show processes in Activity Monitor
# 100: All Processes
# 101: All Processes, Hierarchally
# 102: My Processes
# 103: System Processes
# 104: Other User Processes
# 105: Active Processes
# 106: Inactive Processes
# 106: Inactive Processes
# 107: Windowed Processes
running "Show all processes in Activity Monitor"
defaults write com.apple.ActivityMonitor ShowCategory -int 100;ok

running "Sort Activity Monitor results by CPU usage"
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0;ok

running "Set columns for each tab"
defaults write com.apple.ActivityMonitor "UserColumnsPerTab v5.0" -dict \
    '0' '( Command, CPUUsage, CPUTime, Threads, PID, UID, Ports )' \
    '1' '( Command, ResidentSize, Threads, Ports, PID, UID,  )' \
    '2' '( Command, PowerScore, 12HRPower, AppSleep, UID, powerAssertion )' \
    '3' '( Command, bytesWritten, bytesRead, Architecture, PID, UID, CPUUsage )' \
    '4' '( Command, txBytes, rxBytes, PID, UID, txPackets, rxPackets, CPUUsage )';ok

running "Sort columns in each tab"
defaults write com.apple.ActivityMonitor UserColumnSortPerTab -dict \
    '0' '{ direction = 0; sort = CPUUsage; }' \
    '1' '{ direction = 0; sort = ResidentSize; }' \
    '2' '{ direction = 0; sort = 12HRPower; }' \
    '3' '{ direction = 0; sort = bytesWritten; }' \
    '4' '{ direction = 0; sort = txBytes; }';ok

running "Update refresh frequency (in seconds)"
# 1: Very often (1 sec)
# 2: Often (2 sec)
# 5: Normally (5 sec)
defaults write com.apple.ActivityMonitor UpdatePeriod -int 2;ok

running "Show Data in the Disk graph (instead of IO)"
defaults write com.apple.ActivityMonitor DiskGraphType -int 1;ok

running "Show Data in the Network graph (instead of packets)"
defaults write com.apple.ActivityMonitor NetworkGraphType -int 1;ok

running "Change Dock Icon"
# 0: Application Icon
# 2: Network Usage
# 3: Disk Activity
# 5: CPU Usage
# 6: CPU History
defaults write com.apple.ActivityMonitor IconType -int 3;ok

###############################################################################
bot "Address Book, Dashboard, iCal, TextEdit, and Disk Utility"
###############################################################################

running "Enable the debug menu in Address Book"
defaults write com.apple.addressbook ABShowDebugMenu -bool true;ok

running "Enable Dashboard dev mode (allows keeping widgets on the desktop)"
defaults write com.apple.dashboard devmode -bool true;ok

running "Use plain text mode for new TextEdit documents"
defaults write com.apple.TextEdit RichText -int 0;ok
running "Open and save files as UTF-8 in TextEdit"
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4;ok

running "Enable the debug menu in Disk Utility"
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true;ok

###############################################################################
bot "Mac App Store"
###############################################################################

running "Enable the WebKit Developer Tools in the Mac App Store"
defaults write com.apple.appstore WebKitDeveloperExtras -bool true;ok

running "Enable Debug Menu in the Mac App Store"
defaults write com.apple.appstore ShowDebugMenu -bool true;ok

###############################################################################
bot "Messages"
###############################################################################

# running "Disable automatic emoji substitution (i.e. use plain text smileys)"
# defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false;ok

# 输入时禁用智能引号
running "Disable smart quotes as it’s annoying for messages that contain code"
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false;ok

# running "Disable continuous spell checking"
# defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false;ok

read -r -p "是否要重启? killAll ?" response
killall cfprefsd

read -r -p "打开iTerm?" response
open /Applications/iTerm.app


###############################################################################
# Kill affected applications                                                  #
###############################################################################
bot "OK. Note that some of these changes require a logout/restart to take effect. Killing affected applications (so they can reboot)...."
for app in "Activity Monitor" "Address Book" "Calendar" "Contacts" "cfprefsd" \
  "Dock" "Finder" "Mail" "Messages" "Safari" "SizeUp" "SystemUIServer" \
  "iCal" "Terminal"; do
  killall "${app}" > /dev/null 2>&1
done

brew update && brew upgrade && brew cleanup

bot "Woot! All done. "

# 下面是当初始化完成后需要自己设置对的软件和配置

# ------------------ todo: mackup 安装恢复(不一定每台电脑都需要 mackup 里的东西, 低配的设备里可能就会是负担) ------------------
#####################################
# 检查 mackup 的位置, 将文件转移
#####################################


# warning:
# brew bundle --verbose

# 微信小助手安装:  安装工具: https://github.com/lmk123/oh-my-wechat 小助手: https://github.com/MustangYM/WeChatExtension-ForMac
# curl -o- -L https://raw.githubusercontent.com/lmk123/oh-my-wechat/master/install.sh | bash -s

# mackup 恢复后, 添加对应的脚本, 如果软链后的(即原有备份的.dotfiles 有了就不需要重新写一次)
# zshrc/bashrc 里有了就直接注释好了
# 配置上面脚本安装程序后, 需要做的一些配置
# Install GNU core utilities (those that come with macOS are outdated)
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
