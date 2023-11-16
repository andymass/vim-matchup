.PHONY: test

MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

test:
	$(MYVIM) -u test.vim
	MODE=ts-with-syntax $(MYVIM) -u test.vim
