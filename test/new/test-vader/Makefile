.PHONY: test

MYVIM ?= nvim --headless

INMAKE := 1
export INMAKE

VADER_DIR := ../../vader
TESTS := $(wildcard $(VADER_DIR)/*.vader)
TESTS := $(TESTS:.vader=)

test: $(TESTS)

$(VADER_DIR)/%: $(VADER_DIR)/%.vader
	$(MYVIM) -u $(VADER_DIR)/minvimrc +Vader! $<
