echo "this will clear homebrew and caches which in this transfer directory"

read "res?sure to clear?"
if [[ $res =~ (y|yes|Y) ]]; then
  sudo rm -rf ./Homebrew
  echo "clear Homebrew dir ok"
  sudo rm -rf ./Caches/*
  echo "clear Caches ok"
  ls -la
fi
