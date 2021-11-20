.PHONY: test

MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

test:
	MODE=0 $(MYVIM) -u test.vim
	MODE=1 $(MYVIM) -u test.vim
	MODE=2 $(MYVIM) -u test.vim
	MODE=3 $(MYVIM) -u test.vim
