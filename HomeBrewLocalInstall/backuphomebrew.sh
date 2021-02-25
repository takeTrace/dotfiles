#!/bin/bash

#  将当前 homebrew 的缓存和仓库备份到这里.
cp -r `brew --cache`/ ./HomeBrewCache/
cp -r /usr/local/Homebrew/ ./HomeBrewRepo/
