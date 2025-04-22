.PHONY: test

MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

test:
	MODE=0 $(MYVIM) -u test.vim # default
	MODE=1 $(MYVIM) -u test.vim # additional regex highlighting
	MODE=2 $(MYVIM) -u test.vim # matchup disabled
