#!/bin/zsh

echo 'remove ./Homebrew'
sudo rm -rf ./Homebrew

echo '/usr/local/Homebrew -> ./Homebrew'
sudo cp -r /usr/local/Homebrew ./Homebrew

echo 'here to backup brew --cache dir for convenient install formula and cask in new mac'

read "response?is backup to $pwd/Caches ? (y|n): "

if [[ $response =~ (y|yes|Y) ]]
then
  if ! [[ -d Caches ]]; then
    mkdir Caches
  fi
  if [[ -d ./Caches/Homebrew ]]; then
    sudo rm -rf ./Caches/Homebrew
  fi
  echo "remove Caches/Homebrew ok"

  echo "copy `brew --cache` -> ./Caches"
  sudo cp -r `brew --cache` ./Caches
  echo 'copy brew cache ok'
  ls -G -lh "./Caches/Homebrew"
fi
