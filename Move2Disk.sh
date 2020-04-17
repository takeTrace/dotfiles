rsync --exclude "_gsdata_/" \
		--exclude ".DS_Store" \
		--exclude "mackup" \
		-avh --no-perms . $1/.dotfiles;
